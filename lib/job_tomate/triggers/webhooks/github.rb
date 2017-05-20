require "events/github/pull_request_opened"
require "events/github/pull_request_closed"
require "events/github/status_updated"
require "values/github/pull_request"
require "values/github/status"

module JobTomate
  module Triggers
    module Webhooks

      # Handling Github /github webhooks.
      #
      # Setup the webhook with:
      #   - Path: /webhooks/github
      #   - Choose "Send me everything"
      class Github
        HEADER_EVENT = "HTTP_X_GITHUB_EVENT".freeze
        HEADER_EVENT_VALID_VALUES = %w(issue_comment status pull_request pull_request_review_comment)

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
          raise Web::InvalidWebhook unless valid_webhook?
          process_pull_request_event if pull_request_event?
          process_status_event if status_event?
        end

        private

        attr_reader :webhook

        def valid_webhook?
          webhook.headers[HEADER_EVENT].in? HEADER_EVENT_VALID_VALUES
        end

        def status_event?
          webhook.headers[HEADER_EVENT] == "status"
        end

        def process_status_event
          Events::Github::StatusUpdated.run(status_value)
        end

        def status_value
          Values::Github::Status.new(webhook.parsed_body)
        end

        def pull_request_event?
          webhook.headers[HEADER_EVENT] == "pull_request"
        end

        def process_pull_request_event
          process_pull_request_opened if pull_request_action?(:opened)
          process_pull_request_closed if pull_request_action?(:closed)
        end

        def process_pull_request_opened
          Events::Github::PullRequestOpened.run(pr_value)
        end

        def process_pull_request_closed
          Events::Github::PullRequestClosed.run(pr_value)
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
