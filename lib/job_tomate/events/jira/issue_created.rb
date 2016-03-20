require "actions/slack_notify_jira_new_maintenance_blocker"

module JobTomate
  module Events
    module JIRA

      # Handles JIRA issue created events.
      class IssueCreated

        # @param issue [Values::Issue]
        def self.run(issue)
          Actions::SlackNotifyJIRANewMaintenanceBlocker.run(issue)
        end
      end
    end
  end
end
