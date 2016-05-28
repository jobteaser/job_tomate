require "events/github/pull_request_opened"
require "events/github/pull_request_closed"
require "values/github/pull_request"

module JobTomate
  module Triggers
    module Webhooks

      # Handling Github /github webhooks.
      #
      # Setup the webhook with:
      #   - Path: /webhooks/github
      #   - Choose "Send me everything"
      class Github
        HEADER_EVENT = "HTTP_X_GITHUB_EVENT"

        def self.definition
          {
            name: "github",
            verb: :post,
            path: "/github"
          }
        end

        # @param webhook [Values::Webhook]
        def run_events(webhook)
          @webhook = webhook
          return unless pull_request_event?
          process_pull_request_opened if pull_request_action?(:opened)
          process_pull_request_closed if pull_request_action?(:closed)
        end

        private

        attr_reader :webhook

        def process_pull_request_opened
          Events::Github::PullRequestOpened.run(pr_value)
        end

        def process_pull_request_closed
          Events::Github::PullRequestClosed.run(pr_value)
        end

        def pull_request_event?
          webhook.headers[HEADER_EVENT] == "pull_request"
        end

        def pull_request_action?(action)
          webhook.parsed_body["action"] == action.to_s
        end

        def pr_value
          Values::Github::PullRequest.new(webhook.parsed_body["pull_request"])
        end
      end
    end
  end
end
