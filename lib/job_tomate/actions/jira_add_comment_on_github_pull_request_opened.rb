require "commands/jira/add_comment"

module JobTomate
  module Actions

    # Adds a JIRA comment as JobTomate
    class JIRAAddCommentOnGithubPullRequestOpened

      def self.run(pull_request)
        Commands::JIRA::AddComment.run(
          pull_request.jira_issue_key,
          ENV["JIRA_USERNAME"],
          ENV["JIRA_PASSWORD"],
          "Opened PR: #{pull_request.html_url}"
        )
      end
    end
  end
end
