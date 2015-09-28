require 'active_support/all'
require 'job_tomate/input/jira/helpers'
require 'job_tomate/interface/jira_client'
require 'job_tomate/output/slack_webhook'

module JobTomate
  module Input
    module Jira

      # Performs alerting actions depending on the
      # state of the issues (may not be related to the
      # particular issue the webhook is issued for).
      class AlertingRules
        extend Helpers

        JQL_MAINTENANCE_ISSUES = 'project = JobTeaser AND ' \
          'cf[10400] = Maintenance AND ' \
          '(fixVersion is EMPTY AND ' \
          'status not in (released, closed) OR ' \
          'updatedDate >= -1w)'

        JIRA_STATUSES = {
          todo: ['Open'],
          wip: ['In Development', 'In Review']
        }

        ALERT_MAINTENANCE_TODO_AND_WIP_MAX = 5

        # Applies the rules
        def self.apply(webhook_data)
          maintenance_alerts(webhook_data)
        end

        def self.maintenance_alerts(webhook_data)
          maintenance_todo_wip_alert(webhook_data)
        end

        # TODO: use formatted message
        # TODO: add information to message (link to issue, event - creation or status change...)
        def self.maintenance_todo_wip_alert(webhook_data)
          return unless issue_created?(webhook_data) || issue_changed?('status', webhook_data)
          return unless issue_category(webhook_data) == :maintenance

          count_todo = count_of_maintenance(:todo)
          count_wip = count_of_maintenance(:wip)
          if count_todo + count_wip > ALERT_MAINTENANCE_TODO_AND_WIP_MAX
            Output::SlackWebhook.send(
              "<!channel>: *Too much maintenance*: #{count_todo} TODO & #{count_wip} WIP",
              channel: '#maintenance'
            )
          end
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
