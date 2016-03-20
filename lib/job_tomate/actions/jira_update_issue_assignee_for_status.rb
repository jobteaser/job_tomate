require "commands/jira/update_issue"

module JobTomate
  module Actions

    # Updates the issue's assignee according to its new status:
    #   - "In Development": assign to developer,
    #   - "In Review": assign to reviewer,
    #   - "In Functional Review": assign to feature owner,
    #   - "Ready for Release": assign to developer.
    class JIRAUpdateIssueAssigneeForStatus
      attr_reader :issue

      ROLE_FOR_STATUS = {
        "In Development" => "developer",
        "In Review" => "reviewer",
        "In Functional Review" => "feature_owner",
        "Ready for Release" => "developer"
      }

      # @param issue [Values::JIRA::Issue]
      def self.run(issue)
        new(issue).run
      end

      def initialize(issue)
        @issue = issue
      end

      def run
        new_assignee_role = ROLE_FOR_STATUS[issue.status]
        return if new_assignee_role.nil?
        update_assignee(new_assignee_role)
      end

      private

      def update_assignee(role)
        new_assignee = user_for_role(role)
        return if new_assignee.nil?

        Commands::JIRA::UpdateIssue.run(
          issue.key,
          fields: {
            assignee: {
              name: new_assignee.jira_username
            }
          }
        )
      end

      def user_for_role(role)
        username = issue.send(:"#{role}_name")
        return if username.blank?

        user = Data::User.where(jira_username: username).first
        fail Errors::JIRA::UnknownUser, "no user with jira_username == \"#{username}\"" if user.nil?
        user
      end
    end
  end
end
