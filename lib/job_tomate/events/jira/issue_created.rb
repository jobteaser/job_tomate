require "actions/slack_notify_jira_new_maintenance_blocker"
require "support/service_pattern"

module JobTomate
  module Events
    module JIRA

      # Handles JIRA issue created events.
      class IssueCreated
        extend ServicePattern

        # @param issue [Values::Issue]
        def run(issue)
          Actions::SlackNotifyJIRANewMaintenanceBlocker.run(issue)
        end
      end
    end
  end
end
