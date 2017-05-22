require "actions/jira_update_issue_assignee_and_roles_for_status"
require "actions/slack_notify_jira_bug_issue_updated_without_cause"
require "data/user"
require "errors/jira"
require "support/service_pattern"

module JobTomate
  module Events
    module JIRA

      # Trigger actions for a JIRA issue "status" change.
      class IssueUpdatedStatus
        extend ServicePattern

        # @param issue [Values::JIRA::Issue]
        # @param issue [Values::JIRA::Changelog]
        # @param user_name [String]
        def run(issue, changelog, user_name)
          Actions::JIRAUpdateIssueAssigneeAndRolesForStatus.run(issue, changelog, user_name)
          Actions::SlackNotifyJIRABugIssueUpdatedWithoutCause.run(issue) if missing_bug_cause?(issue)
        end

        private

        def missing_bug_cause?(issue)
          issue.bug? && !issue.bug_cause?
        end
      end
    end
  end
end
