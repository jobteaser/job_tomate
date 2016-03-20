require "job_tomate/data/webhook_payload"
require "job_tomate/events/github/pull_request"

module JobTomate
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
        return if handled_pull_request_event?
      end

      private

      def pull_request_event?
        request.env[HEADER_EVENT] == "pull_request"
      end

      def handled_pull_request_event?
        return false unless pull_request_event?
        Events::Github::PullRequest.run(event_description)
        true
      end

      def event_description
        { action: webhook_data["action"] }.merge pr_description
      end

      def pr_description
        {
          base_ref: webhook_data["pull_request"]["base"]["ref"],
          head_ref: webhook_data["pull_request"]["head"]["ref"],
          html_url: webhook_data["pull_request"]["html_url"],
          merged: webhook_data["pull_request"]["merged"]
        }
      end
    end
  end
end
