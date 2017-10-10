require "commands/jira/set_field"
require "support/service_pattern"

module JobTomate
  module Actions

    # Adds a JIRA comment as JobTomate
    class JIRAFillBranchNameOnGithubPullRequestOpened
      extend ServicePattern

      def run(pull_request)
        Commands::JIRA::SetField.run(
          pull_request.jira_issue_key,
          ENV["JIRA_USERNAME"],
          ENV["JIRA_PASSWORD"],
          "Branch Name",
          "#{pull_request.head_ref}"
        )
      end
    end
  end
end
