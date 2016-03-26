require "job_tomate/data/webhook_payload"
require "job_tomate/workflows/jira/process_webhook"

module JobTomate
  module Webhooks

    # Handling JIRA webhooks
    #
    # TODO: document how to setup the JIRA webhook appropriately
    class Jira

      def definition
        {
          name: "jira",
          verb: :post,
          path: "/jira"
        }
      end

      def extract_webhook_data(request)
        json = request.body.read
        json.empty? ? { error: "no body" } : JSON.parse(json)
      end

      def run_events(webhook_data)
        JobTomate::Workflows::Jira::ProcessWebhook.run(webhook_data)
      end
    end
  end
end
