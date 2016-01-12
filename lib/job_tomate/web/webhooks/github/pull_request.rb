require 'job_tomate/data/webhook_payload'
require 'job_tomate/workflows/github/process_pull_request_webhook'

module JobTomate
  module Webhooks
    module Github

      # Handling Github /github/pull_request webhook.
      #
      # Setup the webhook with:
      #   - Path: /webhooks/github/pull_request
      #   - Choose "Let me select individual events"
      #   - Check "Pull Request" event only
      class PullRequest
        def self.define_webhooks
          lambda do
            post '/github/pull_request' do
              json = request.body.read
              return 'no body' if json.empty?

              webhook_data = JSON.parse json
              JobTomate::Data::WebhookPayload.create(source: 'github/pull_request', data: webhook_data)
              JobTomate::Workflows::Github::ProcessPullRequestWebhook.run(webhook_data)

              { status: 'ok' }.to_json
            end
          end
        end
      end
    end
  end
end
