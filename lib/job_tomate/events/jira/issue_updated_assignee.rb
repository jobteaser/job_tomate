require "actions/jira_update_issue_roles_with_assignee"
require "actions/slack_notify_jira_issue_assignee"
require "data/user"
require "errors/jira"

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
        attr_reader :changelog
        attr_reader :issue

        # @param issue [Values::JIRA::Issue]
        # @param issue [Values::JIRA::Changelog]
        def self.run(issue, changelog)
          new(issue, changelog).run
        end

        def initialize(issue, changelog)
          @issue = issue
          @changelog = changelog
        end

        def run
          Actions::JIRAUpdateIssueRolesWithAssignee.run(issue)
          Actions::SlackNotifyJIRAIssueAssignee.run(issue)
        end
      end
    end
  end
end
