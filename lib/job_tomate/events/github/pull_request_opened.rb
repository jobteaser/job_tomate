require "actions/jira_add_comment_on_github_pull_request_opened"
require "support/service_pattern"

module JobTomate
  module Events
    module Github

      # Process Github's "pull_request" events, for action "opened".
      class PullRequestOpened
        extend ServicePattern

        # @param pull_request [Values::Github::PullRequest]
        def run(pull_request)
          return if pull_request.jira_issue_key.blank?
          Actions::JIRAAddCommentOnGithubPullRequestOpened.run(pull_request)
        end
      end
    end
  end
end
