require "actions/jira_add_comment_on_github_pull_request_closed"

module JobTomate
  module Events
    module Github

      # Process Github's "pull_request" events, for action "closed".
      # It handles 2 cases:
      #   - merged,
      #   - not merged.
      class PullRequestClosed

        # @param pull_request [Values::Github::PullRequest]
        def self.run(pull_request)
          return if pull_request.jira_issue_key.blank?
          Actions::JIRAAddCommentOnGithubPullRequestClosed.run(pull_request)
        end
      end
    end
  end
end
