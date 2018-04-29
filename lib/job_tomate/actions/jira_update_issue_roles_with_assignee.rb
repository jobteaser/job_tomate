require "commands/jira/update_issue"
require "support/service_pattern"

module JobTomate
  module Actions

    # Updates the issue's roles (developer, reviewer,
    # feature owner) according to:
    #   - the assignee that was set,
    #   - the possible roles for the assignee,
    #   - the current status of the issue,
    #   - the current roles.
    class JIRAUpdateIssueRolesWithAssignee
      extend ServicePattern

      # @param issue [Values::JIRA::Issue]
      def run(issue)
        @issue = issue
        return if @issue.assignee_user.nil?
        set_developer_backend
        set_reviewer
        set_product_manager
      end

      private

      def set_developer_backend
        return if @issue.developer_backend_name.present?
        return unless @issue.assignee_user.developer_backend?
        return unless @issue.status.in?(["Open", "In Development"])
        update_for_custom_field("developer_backend", name: @issue.assignee_user.jira_username)
      end

      def set_reviewer
        return if @issue.reviewer_name.present?
        return unless @issue.assignee_user.jira_reviewer?
        return unless @issue.status.in?(["In Review"])
        update_for_custom_field("reviewer", name: @issue.assignee_user.jira_username)
      end

      def set_product_manager
        return if @issue.product_manager_name.present?
        return unless @issue.assignee_user.product_manager?
        update_for_custom_field("product_manager", name: @issue.assignee_user.jira_username)
      end

      def update_for_custom_field(custom_field, value)
        Commands::JIRA::UpdateIssue.run(
          @issue.key,
          fields: {
            Values::JIRA::Issue.jira_field(custom_field) => value
          }
        )
      end
    end
  end
end
