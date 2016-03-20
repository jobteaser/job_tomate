require "events/github/pull_request_opened"
require "events/github/pull_request_closed"
require "triggers/webhooks"
require "values/github/pull_request"

module JobTomate
  module Triggers
    module Webhooks

      # Handling Github /github webhooks.
      #
      # Setup the webhook with:
      #   - Path: /webhooks/github
      #   - Choose "Send me everything"
      class Github < Base
        HEADER_EVENT = "X-GitHub-Event"

        def self.definition
          {
            name: "github",
            verb: :post,
            path: "/github"
          }
        end

        def run_events
          return unless pull_request_event?
          handle_pull_request_opened
          handle_pull_request_closed
        end

        private

        def handle_pull_request_opened
          return unless pull_request_action?(:opened)
          Events::Github::PullRequestOpened.run(pr_value)
        end

        def handle_pull_request_closed
          return unless pull_request_action?(:closed)
          Events::Github::PullRequestClosed.run(pr_value)
        end

        def pull_request_event?
          request.env[HEADER_EVENT] == "pull_request"
        end

        def pull_request_action?(action)
          webhook_data["action"] == action.to_s
        end

        def pr_value
          Values::Github::PullRequest.new(webhook_data["pull_request"])
        end
      end
    end
  end
end
