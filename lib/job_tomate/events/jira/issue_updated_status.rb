require "actions/jira_update_issue_assignee_for_status"
require "data/user"
require "errors/jira"
require "support/service_pattern"

module JobTomate
  module Events
    module JIRA

      # Trigger actions for a JIRA issue "status" change.
      class IssueUpdatedStatus
        extend ServicePattern

        def run(issue, changelog)
          @issue = issue
          @changelog = changelog
          Actions::JIRAUpdateIssueAssigneeForStatus.run(@issue)
        end

        private

        def new_status
          @changelog.to_string
        end
      end
    end
  end
end
