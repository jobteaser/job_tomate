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
    class JIRAIssueChangingStatusUpdatesAssigneeAndRoles
      extend ServicePattern

      # Maps which role (developer_backend, product_manager...)
      # should be assigned to the issue depending on the 
      # status.
      ROLE_FOR_STATUS = {
        "In Development" => "developer_backend",
        "In Review" => "reviewer",
        "In Functional Review" => "product_manager",
        "Ready for Release" => "developer_backend"
      }.freeze

      # @param issue [Values::JIRA::Issue]
      # @param changelog [Values::JIRA::Changelog]
      # @param username [String]: name of the JIRA user which performed the
      #   change
      def run(issue, changelog, username)
        if issue.issue_type == "Bug" && changelog.to_string == "In Functional Review"
          update_issue_assignee_with_username(issue, issue.reporter_name)
          return
        end

        return if role_for_new_status(changelog).nil?

        new_status_role = role_for_new_status(changelog)
        return if update_assignee_based_on_role(issue, new_status_role)
        return if update_assignee_and_roles(issue, username, new_status_role)

        update_issue_by_removing_assignee(issue)
      end

      private

      # @return [Bool] true if the operation was done, false otherwise
      def update_assignee_based_on_role(issue, role)
        return false unless issue_has_username_for_role?(issue, role)
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

      def issue_username_for_role(issue, role)
        issue.send(:"#{role}_name")
      end

      # Returns true if an username is already set on the issue
      # for the specified role.
      #
      # For example, returns true when called with `issue` and
      # `:reviewer` if `issue.reviewer` has a value.
      def issue_has_username_for_role?(issue, role)
        issue_username_for_role(issue, role).present?
      end

      # The user is appropriate for the role if:
      #   - the user record specifies the user can take the role (e.g.
      #     `user.developer_backend == true`), and,
      #   - either:
      #     - if the role is "developer_backend", the user is not "reviewer" of the issue, or,
      #     - if the role is "reviewer", the user is not "developer_backend" of the issue.
      def user_appropriate_for_role?(user, role, issue)
        return false unless user_can_take_role?(user, role)

        conflicting_role = (
          case role
          when "developer_backend" then "reviewer"
          when "reviewer" then "developer_backend"
          end
        )
        return true if conflicting_role.nil?
        issue_username_for_role(issue, conflicting_role) != user.jira_username
      end

      # NB: the condition is necessary because we have migrated some fields
      # from `jira_...` to a non-prefixed version (`developer`, `product_manager`).
      # Migration of other roles without the `jira` prefix will enable removing
      # the first clause.
      def user_can_take_role?(user, role)
        if role.in? %w[developer_backend product_manager]
          return false unless user.send(role)
        else
          return false unless user.send(:"jira_#{role}")
        end
        true
      end

      def update_assignee(issue, role)
        new_assignee = user_for_role(issue, role)

        if new_assignee.nil?
          update_issue_by_removing_assignee(issue)
        else
          update_issue_by_updating_assignee_with_user(issue, new_assignee)
        end
      end

      def update_issue(issue, payload)
        Commands::JIRA::UpdateIssue.run(
          issue.key,
          payload
        )
      end

      def update_issue_assignee_with_username(issue, username)
        update_issue(issue, fields: { assignee: { name: username } })
      end

      def update_assignee_and_role(issue, user, role)
        update_issue(issue, fields: {
                       assignee: { name: user.jira_username },
                       Values::JIRA::Issue.jira_field(role).to_sym => { name: user.jira_username }
                     })
      end

      def update_issue_by_removing_assignee(issue)
        update_issue(issue, fields: { assignee: nil })
      end

      def update_issue_by_updating_assignee_with_user(issue, user)
        username = user.jira_username
        update_issue(issue, fields: { assignee: { name: username } })
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
