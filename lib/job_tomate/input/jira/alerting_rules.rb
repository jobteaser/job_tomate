require 'active_support/all'
require 'job_tomate/input/jira/helpers'
require 'job_tomate/interface/jira_client'
require 'job_tomate/output/slack_webhook'

module JobTomate
  module Input
    module Jira

      # Send alerts on Slack for maintenance issues when:
      #   - a new blocker issues has been created (TODO),
      #   - a new issue has been created and the total number of WIP issues is:
      #     * >= 10, ask for 1 more developer (level 1),
      #     * >= 14, ask for 2 more developers (level 2),
      #     * >= 18, ask for a war-room (level 3).
      class AlertingRules
        extend Helpers

        JQL_MAINTENANCE_ISSUES = 'project = JobTeaser AND ' \
          'cf[10400] = Maintenance AND ' \
          'fixVersion is EMPTY '

        JIRA_STATUSES = {
          todo: ['Open'],
          wip: ['In Development', 'In Review']
        }

        ALERT_MAINTENANCE_LEVELS = {
          10 => :level_1,
          15 => :level_2,
          20 => :level_3
        }

        ALERT_MAINTENANCE_MESSAGES = {
          up_to_level_1: '*Maintenance reached level 1* => 1 developer must reinforce the maintenance team',
          up_to_level_2: '*Maintenance reached level 2* => 2 developers must reinforce the maintenance team',
          up_to_level_3: '*Maintenance reached level 3* => war room',
          down_from_level_1: '*Maintenance back to normal :)* => no reinforcement required',
          down_from_level_2: '*Maintenance back to level 1* => 1 developer must reinforce the maintenance team',
          down_from_level_3: '*Maintenance reached level 2* => 2 developers must reinforce the maintenance team'
        }

        # Apply the rules
        def self.apply(webhook_data)
          # maintenance_alerts(webhook_data)
          blocker_notification(webhook_data)
        end

        # Send Slack message if a maintenance issue has been created and the
        # count of todo and wip issues match an alert level.
        #
        # TODO: use formatted message
        # TODO: add information to message (link to issue, event - creation or status change...)
        def self.maintenance_alerts(webhook_data)
          return unless issue_category(webhook_data) == :maintenance

          change = maintenance_level_change(webhook_data)
          return if change.nil?

          message = ALERT_MAINTENANCE_MESSAGES[change]
          return if message.nil?

          Output::SlackWebhook.send(
            "<!channel>: #{message}",
            channel: '#maintenance'
          )
        end

        def self.blocker_notification(webhook_data)
          return unless issue_created?(webhook_data)
          if issue_priority(webhook_data) == 'Blocker'
            message = 'New blocker issue has just been created!'
            Output::SlackWebhook.send(
              "<!channel>: #{message}",
              channel: '#maintenance'
            )
          end
        end

        # IMPLEMENTATION

        # :up if the issue was created
        # :down if the issue
        def self.maintenance_level_change(webhook_data)
          count = count_of_maintenance(:todo) + count_of_maintenance(:wip)

          if issue_created?(webhook_data) ||
             (issue_updated?(webhook_data) &&
             issue_status_change_to_todo_or_wip?(webhook_data))

            # Level going up
            level = ALERT_MAINTENANCE_LEVELS[count]
            return level ? :"up_to_#{level}" : nil
          end

          if issue_updated?(webhook_data) &&
             !issue_status_change_to_todo_or_wip?(webhook_data)

            # Level going down
            level = ALERT_MAINTENANCE_LEVELS[count + 1]
            return level ? :"down_from_#{level}" : nil
          end
          nil
        end

        def self.issue_status_change_to_todo_or_wip?(webhook_data)
          status_change = change('status', webhook_data)
          return false if status_change.nil?

          status_change['toString'].in?(JIRA_STATUSES[:todo] + JIRA_STATUSES[:wip])
        end

        # @param status [Symbol] key from JIRA_STATUSES
        def self.count_of_maintenance(status_group)
          jira_statuses = JIRA_STATUSES[status_group]
          if jira_statuses.nil?
            fail ArgumentError, "Unknown status \"#{status}\""
          end

          results = search(jql_for_maintenance_with_statuses(jira_statuses))
          results['total'].to_i
        end

        # Builds a JQL query for maintenance issues (using
        # JQL_MAINTENANCE_ISSUES) and appending a query to
        # limit results to issues in the specified statuses.
        def self.jql_for_maintenance_with_statuses(statuses)
          jql_status_list = statuses.map { |s| "'#{s}'" }.join(', ')
          "#{JQL_MAINTENANCE_ISSUES} AND status IN (#{jql_status_list})"
        end
      end
    end
  end
end
