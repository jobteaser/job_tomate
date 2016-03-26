require "job_tomate/data/webhook_payload"
require "job_tomate/events/github/pull_request/closed"
require "job_tomate/events/github/pull_request/merged"
require "job_tomate/events/github/pull_request/opened"

module JobTomate
  module Webhooks

    # Handling Github /github webhooks.
    #
    # Setup the webhook with:
    #   - Path: /webhooks/github
    #   - Choose "Send me everything"
    class Github

      attr_reader :webhook_data

      def definition
        {
          name: "github",
          verb: :post,
          path: "/github"
        }
      end

      def extract_webhook_data(request)
        json = request.body.read
        json.empty? ? { error: "no body" } : JSON.parse(json)
      end

      def run_events(webhook_data)
        @webhook_data = webhook_data

        return if handled_case_opened?
        return if handled_case_merged?
        return if handled_case_closed?
      end

      private

      def handled_case_opened?
        if pr_action == "opened"
          Events::Github::PullRequest::Opened.run(pr_description)
          return true
        end
        false
      end

      def handled_case_merged?
        if pr_description[:merged].present?
          Events::Github::PullRequest::Merged.run(pr_description)
          return true
        end
        false
      end

      def handled_case_closed?
        if pr_action == "closed"
          Events::Github::PullRequest::Closed.run(pr_description)
          return true
        end
        false
      end

      def pr_action
        webhook_data["action"]
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
