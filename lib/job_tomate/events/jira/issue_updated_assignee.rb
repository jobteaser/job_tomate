require "actions/jira_update_issue_roles_with_assignee"
require "actions/slack_notify_jira_issue_assignee"
require "data/user"
require "errors/jira"
require "support/service_pattern"

module JobTomate
  module Events
    module JIRA

      # Handles JIRA issue update with "assignee" field change.
      #
      # Actions that may be performed according to the conditions
      # (see specs for the business rules):
      #   - update the issue roles (developer, reviewer, feature
      #     owner) with the assignee when applicable,
      #   - notify the assignee on Slack.
      #
      class IssueUpdatedAssignee
        extend ServicePattern

        # @param issue [Values::JIRA::Issue]
        # @param issue [Values::JIRA::Changelog]
        def run(issue, _changelog)
          Actions::JIRAUpdateIssueRolesWithAssignee.run(issue)
          Actions::SlackNotifyJIRAIssueAssignee.run(issue)
        end
      end
    end
  end
end
