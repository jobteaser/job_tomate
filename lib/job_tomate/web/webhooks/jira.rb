require "job_tomate/data/webhook_payload"
require "job_tomate/workflows/jira/process_webhook"

module JobTomate
  module Webhooks

    # Handling JIRA webhooks
    #
    # TODO: document how to setup the JIRA webhook appropriately
    class Jira < Base

      def definition
        {
          name: "jira",
          verb: :post,
          path: "/jira"
        }
      end

      def run_events
        JobTomate::Workflows::Jira::ProcessWebhook.run(webhook_data)
      end
    end
  end
end
