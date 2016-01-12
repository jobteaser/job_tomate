require 'job_tomate/data/webhook_payload'
require 'job_tomate/workflows/jira/process_webhook'

module JobTomate
  module Webhooks

    # Handling JIRA webhooks
    #
    # TODO: document how to setup the JIRA webhook appropriately
    class Jira
      def self.define_webhooks
        lambda do
          post '/jira' do
            json = request.body.read
            return 'no body' if json.empty?

            webhook_data = JSON.parse json
            JobTomate::Data::WebhookPayload.create(source: 'jira', data: webhook_data)
            JobTomate::Workflows::Jira::ProcessWebhook.run(webhook_data)

            { status: 'ok' }.to_json
          end
        end
      end
    end
  end
end
