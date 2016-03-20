require "commands/jira/update_issue"

module JobTomate
  module Actions

    # Updates the issue's roles (developer, reviewer,
    # feature owner) according to:
    #   - the assignee that was set,
    #   - the possible roles for the assignee,
    #   - the current status of the issue,
    #   - the current roles.
    class JIRAUpdateIssueRolesWithAssignee
      attr_reader :issue

      # @param issue [Values::JIRA::Issue]
      def self.run(issue)
        new(issue).run
      end

      def initialize(issue)
        @issue = issue
      end

      def run
        return if issue.assignee_user.nil?
        set_developer
        set_reviewer
        set_feature_owner
      end

      private

      def set_developer
        return if issue.developer_name.present?
        return unless issue.assignee_user.jira_developer?
        return unless issue.status.in?(["Open", "In Development"])
        update_for_custom_field("developer", name: issue.assignee_user.jira_username)
      end

      def set_reviewer
        return if issue.reviewer_name.present?
        return unless issue.assignee_user.jira_reviewer?
        return unless issue.status.in?(["In Review"])
        update_for_custom_field("reviewer", name: issue.assignee_user.jira_username)
      end

      def set_feature_owner
        return if issue.feature_owner_name.present?
        return unless issue.assignee_user.jira_feature_owner?
        update_for_custom_field("feature_owner", name: issue.assignee_user.jira_username)
      end

      def update_for_custom_field(custom_field, value)
        Commands::JIRA::UpdateIssue.run(
          issue.key,
          fields: {
            Values::JIRA::Issue.jira_field(custom_field) => value
          }
        )
      end
    end
  end
end
