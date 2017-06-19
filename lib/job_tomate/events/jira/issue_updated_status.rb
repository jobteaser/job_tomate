require "actions/jira_issue_changing_status_updates_assignee_and_roles"
require "actions/slack_notify_jira_bug_issue_updated_without_cause"
require "actions/slack_notify_missing_pull_request"
require "actions/slack_notify_missing_pull_request"
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
          Actions::SlackNotifyMissingPullRequest.run(issue, changelog, user_name)
        end
      end
    end
  end
end
