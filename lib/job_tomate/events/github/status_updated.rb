# frozen_string_literal: true
require "actions/slack_notify_on_github_status_update"
require "support/service_pattern"

module JobTomate
  module Events
    module Github

      # Process Github's "status_updated" events (e.g. Codeclimate or
      # CircleCI notifications).
      class StatusUpdated
        extend ServicePattern

        # @param status [Values::Github::Status]
        def run(status)
          Actions::SlackNotifyOnGithubStatusUpdate.run(status)
        end
      end
    end
  end
end
