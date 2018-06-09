# frozen_string_literal: true

require "commands/jira/update_issue"
require "support/service_pattern"

module JobTomate
  module Actions

    # Adds a JIRA comment as JobTomate
    class JIRAFillBranchNameOnGithubPullRequestOpened
      extend ServicePattern

      def run(pull_request)
        update_issue_branch_name(pull_request.jira_issue_key, pull_request.head_ref)
      end

      private

      def update_issue_branch_name(issue_key, new_branch_name)
        Commands::JIRA::UpdateIssue.run(
          issue_key,
          fields: {
            Values::JIRA::Issue.jira_field("branch_name") => new_branch_name
          }
        )
      end
    end
  end
end
