require "actions/jira_update_issue_assignee_and_roles_for_status"
require "actions/slack_notify_on_absent_feature_env"
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
          Actions::SlackNotifyOnAbsentFeatureEnv.run(issue, changelog, user_name)
        end
      end
    end
  end
end
