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
          '(fixVersion is EMPTY AND ' \
          'status not in (released, closed)'

        JIRA_STATUSES = {
          todo: ['Open'],
          wip: ['In Development', 'In Review']
        }

        ALERT_MAINTENANCE_TODO_AND_WIP_LEVEL_1 = 10
        ALERT_MAINTENANCE_TODO_AND_WIP_LEVEL_2 = 14
        ALERT_MAINTENANCE_TODO_AND_WIP_LEVEL_3 = 18

        # Apply the rules
        def self.apply(webhook_data)
          maintenance_alerts(webhook_data)
        end

        # Send Slack message if a maintenance issue has been created and the
        # count of todo and wip issues match an alert level.
        #
        # TODO: use formatted message
        # TODO: add information to message (link to issue, event - creation or status change...)
        def self.maintenance_alerts(webhook_data)
          return unless issue_category(webhook_data) == :maintenance
          return unless issue_created?(webhook_data)

          count_todo_and_wip = count_of_maintenance(:todo) + count_of_maintenance(:wip)
          return if count_todo_and_wip < ALERT_MAINTENANCE_TODO_AND_WIP_LEVEL_1

          message = (
            if count_todo_and_wip == ALERT_MAINTENANCE_TODO_AND_WIP_LEVEL_3
              '*Maintenance reached level 3* => war room'
            elsif count_todo_and_wip == ALERT_MAINTENANCE_TODO_AND_WIP_LEVEL_2
              '*Maintenance reached level 2* => 2 developers must reinforce the maintenance team'
            elsif count_todo_and_wip == ALERT_MAINTENANCE_TODO_AND_WIP_LEVEL_1
              '*Maintenance reached level 1* => 1 developer must reinforce the maintenance team'
            end
          )
          Output::SlackWebhook.send(
            "<!channel>: #{message}",
            channel: '#maintenance'
          )
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
          jql_status_list = statuses.map { |s| "\"#{s}\"" }.join(', ')
          "#{JQL_MAINTENANCE_ISSUES} AND status IN (#{jql_status_list})"
        end
      end
    end
  end
end
