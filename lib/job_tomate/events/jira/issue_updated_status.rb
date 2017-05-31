require "actions/jira_issue_changing_status_updates_assignee_and_roles"
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
          Actions::SlackNotifyMissingPullRequest.run(issue) if missing_pull_request?(issue, changelog)
        end

        def missing_pull_request?
          return false unless changelog.requires_pull_request?
          issue.missing_pull_request?
        end
      end
    end
  end
end
