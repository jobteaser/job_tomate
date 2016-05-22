require "actions/jira_add_comment_on_github_pull_request_closed"
require "support/service_pattern"

module JobTomate
  module Events
    module Github

      # Process Github's "pull_request" events, for action "closed".
      # It handles 2 cases:
      #   - merged,
      #   - not merged.
      class PullRequestClosed
        extend ServicePattern

        # @param pull_request [Values::Github::PullRequest]
        def run(pull_request)
          return if pull_request.jira_issue_key.blank?
          Actions::JIRAAddCommentOnGithubPullRequestClosed.run(pull_request)
        end
      end
    end
  end
end
