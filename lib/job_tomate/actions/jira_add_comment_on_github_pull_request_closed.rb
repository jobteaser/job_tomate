require "commands/jira/add_comment"
require "support/service_pattern"

module JobTomate
  module Actions

    # Adds a JIRA comment as JobTomate
    class JIRAAddCommentOnGithubPullRequestClosed
      extend ServicePattern

      def run(pull_request)
        Commands::JIRA::AddComment.run(
          pull_request.jira_issue_key,
          ENV["JIRA_USERNAME"],
          ENV["JIRA_PASSWORD"],
          comment(pull_request)
        )
      end

      def comment(pull_request)
        if pull_request.merged?
          "Merged PR in #{pull_request.base_ref}: #{pull_request.html_url}"
        else
          "Closed PR without merging: #{pull_request.html_url}"
        end
      end
    end
  end
end
