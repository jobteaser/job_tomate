require "commands/jira/update_issue"
require "support/service_pattern"

module JobTomate
  module Actions

    # Updates the issue's assignee according to its new status:
    #   - "In Development": assign to developer,
    #   - "In Review": assign to reviewer,
    #   - "In Functional Review": assign to feature owner,
    #   - "Ready for Release": assign to developer.
    #
    # Technical debts:
    #   - Using status labels instead of status identifiers. We use the changelog's
    #     `toString` value instead of `to`, so if the labels of the statuses are changed
    #     the code may get broken, while the identifiers would not change.
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
      def run(issue, changelog, username)
        return if no_role_for_new_status?(changelog)

        new_status_role = role_for_new_status(changelog)
        return if update_assignee_based_on_role(issue, new_status_role)
        return if update_assignee_and_roles(issue, username, new_status_role)
        unassign(issue)
      end

      private

      # @return [Bool] true if the operation was done, false otherwise
      def update_assignee_based_on_role(issue, role)
        return false unless issue_role_set?(issue, role)
        update_assignee(issue, role)
        true
      end

      # @return [Bool] true if the operation was done, false otherwise
      def update_assignee_and_roles(issue, username, new_status_role)
        user = user_for_name(username)
        return unless user_appropriate_for_role?(user, new_status_role, issue)
        update_assignee_and_role(issue, user, new_status_role)
      end

      def role_for_new_status(changelog)
        @role_for_new_status ||= (
          new_status = changelog.to_string
          ROLE_FOR_STATUS[new_status]
        )
      end

      def no_role_for_new_status?(changelog)
        role_for_new_status(changelog).nil?
      end

      def issue_role_username(issue, role)
        issue.send(:"#{role}_name")
      end

      def issue_role_set?(issue, role)
        issue_role_username(issue, role).present?
      end

      # The user is appropriate for the role if:
      #   - the user record specifies the user can take the role (e.g.
      #     `user.jira_developer == true`), and,
      #   - either:
      #     - if the role is "developer", the user is not "reviewer" of the issue, or,
      #     - if the role is "reviewer", the user is not "developer" of the issue.
      def user_appropriate_for_role?(user, role, issue)
        return false unless user.send(:"jira_#{role}")
        conflicting_role = (
          case role
          when "developer" then "reviewer"
          when "reviewer" then "developer"
          end
        )
        return true if conflicting_role.nil?
        issue_role_username(issue, conflicting_role) != user.jira_username
      end

      def update_assignee(issue, role)
        new_assignee = user_for_role(issue, role)

        if new_assignee.nil?
          unassign(issue)
        else
          assign_to(issue, new_assignee)
        end
      end

      def update_issue(issue, payload)
        Commands::JIRA::UpdateIssue.run(
          issue.key,
          payload
        )
      end

      def update_assignee_and_role(issue, user, role)
        update_issue(issue, fields: {
                       assignee: { name: user.jira_username },
                       Values::JIRA::Issue.jira_field(role).to_sym => { name: user.jira_username }
                     })
      end

      def unassign(issue)
        update_issue(issue, fields: { assignee: nil })
        issue.set_assignee_name(nil)
      end

      def assign_to(issue, assignee)
        username = assignee.jira_username
        update_issue(issue, fields: { assignee: { name: username } })
        issue.set_assignee_name(username)
      end

      def user_for_role(issue, role)
        username = issue.send(:"#{role}_name")
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
