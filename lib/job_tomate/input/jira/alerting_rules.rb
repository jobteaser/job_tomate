require 'active_support/all'
require 'job_tomate/input/jira/helpers'
require 'job_tomate/output/jira_client'
require 'job_tomate/output/slack_webhook'

module JobTomate
  module Input
    module Jira

      # Performs alerting actions depending on the
      # state of the issues (may not be related to the
      # particular issue the webhook is issued for).
      class AlertingRules
        extend Helpers

        JIRA_MAX_RESULTS = 1000
        JQL_MAINTENANCE_ISSUES = 'project = JobTeaser AND cf[10400] = Maintenance AND (fixVersion is EMPTY AND status not in (released, closed) OR updatedDate >= -1w)'

        ALERT_MAINTENANCE_TODO_AND_WIP_MAX = 5

        # Applies the rules
        def self.apply(webhook_data)
          if issue_created?(webhook_data) ||
            issue_changed?('status', webhook_data)
            alert_maintenance_todo_and_wip_issues
          end
        end

        def self.alert_maintenance_todo_and_wip_issues
          count_todo = count_of_maintenance(:todo)
          count_wip = count_of_maintenance(:wip)
          if count_todo + count_wip > ALERT_MAINTENANCE_TODO_AND_WIP_MAX
            Output::SlackWebhook.send(
              "<!channel>: *Too much maintenance*: #{count_todo} TODO & #{count_wip} WIP",
              channel: '#maintenance'
            )
          end
        end

        # @param status [Symbol] :todo or :wip
        def self.count_of_maintenance(status)
          jira_statuses = (
            case status
            when :todo then ['Open']
            when :wip then ['In Development', 'In Review']
            else fail ArgumentError, "Unknown status \"#{status}\""
            end
          )
          results = Output::JiraClient.exec_request(
            :get,
            '/search',
            ENV['JIRA_USERNAME'],
            ENV['JIRA_PASSWORD'],
            {}, # body
            {
              jql: jql_for_maintenance_with_statuses(jira_statuses),
              startAt: 0,
              fields: 'id',
              maxResults: JIRA_MAX_RESULTS
            }
          )
          # require 'pry'; binding.pry
          results['total']
        end

        def self.jql_for_maintenance_with_statuses(statuses)
          jql_status_list = statuses.map { |s| "\"#{s}\"" }.join(', ')
          "#{JQL_MAINTENANCE_ISSUES} AND status IN (#{jql_status_list})"
        end
      end
    end
  end
end
