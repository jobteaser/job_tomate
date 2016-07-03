require "commands/jira/update_issue"
require "support/service_pattern"

module JobTomate
  module Actions

    # Updates the issue's assignee according to its new status:
    #   - "In Development": assign to developer,
    #   - "In Review": assign to reviewer,
    #   - "In Functional Review": assign to feature owner,
    #   - "Ready for Release": assign to developer.
    class JIRAUpdateIssueAssigneeAndRolesForStatus
      extend ServicePattern

      ROLE_FOR_STATUS = {
        "In Development" => "developer",
        "In Review" => "reviewer",
        "In Functional Review" => "feature_owner",
        "Ready for Release" => "developer"
      }.freeze

      # @param issue [Values::JIRA::Issue]
      # @param changelog [Values::JIRA::Changelog]
      # @param username [String]: name of the JIRA user which performed the
      #   change
      def run(issue, _changelog, username)
        @issue = issue

        new_status_role = ROLE_FOR_STATUS[@issue.status]
        return if new_status_role.nil?

        user = user_for_name(username)

        if issue_role_set?(new_status_role)
          update_assignee(new_status_role)
          return
        end

        if user_matches_role?(user, new_status_role)
          update_assignee_and_role(user, new_status_role)
          return
        end

        unassign
      end

      private

      def issue_role_set?(role)
        @issue.send(:"#{role}_name").present?
      end

      def user_matches_role?(user, role)
        user.send(:"jira_#{role}")
      end

      def update_assignee(role)
        new_assignee = user_for_role(role)

        if new_assignee.nil?
          unassign
        else
          assign_to new_assignee
        end
      end

      def update_issue(payload)
        Commands::JIRA::UpdateIssue.run(
          @issue.key,
          payload
        )
      end

      def update_assignee_and_role(user, role)
        update_issue(
          fields: {
            assignee: {
              name: user.jira_username
            },
            Values::JIRA::Issue.jira_field(role).to_sym => {
              name: user.jira_username
            }
          }
        )
      end

      def unassign
        update_issue(
          fields: {
            assignee: nil
          }
        )
      end

      def assign_to(assignee)
        update_issue(
          fields: {
            assignee: {
              name: assignee.jira_username
            }
          }
        )
      end

      def user_for_role(role)
        username = @issue.send(:"#{role}_name")
        return if username.blank?
        user_for_name(username)
      end

      def user_for_name(username)
        user = Data::User.where(jira_username: username).first
        raise Errors::JIRA::UnknownUser, "no user with jira_username == \"#{username}\"" if user.nil?
        user
      end
    end
  end
end
