# frozen_string_literal: true

require "events/circleci/status"

module JobTomate
  module Triggers
    module Webhooks

      # Handling Github /github webhooks.
      #
      # Setup the webhook with:
      #   - Path: /webhooks/circleci
      #   - Choose "Send me everything"
      class Circleci
        HEADER_EVENT = "HTTP_X_GITHUB_EVENT"

        def self.definition
          {
            name: "circleci",
            verb: :post,
            path: "/circleci"
          }
        end

        # @param webhook [Values::Webhook]
        def run_events(webhook)
          @webhook = webhook
          raise InvalidWebhook unless valid_webhook?
          process_status_event
        end

        private

        attr_reader :webhook

        def valid_webhook?
          true
        end

        def status_value
          Values::Github::Status.new(webhook.parsed_body)
        end

        def process_status_event
          Events::Github::StatusUpdated.run(status_value)
        end

        def pull_request_action?(action)
          webhook.parsed_body["action"] == action.to_s
        end
      end

    end
  end
end
