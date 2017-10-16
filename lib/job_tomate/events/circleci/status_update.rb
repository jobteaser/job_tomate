# frozen_string_literal: true
require "actions/slack_notify_on_circleci_status_update"
require "support/service_pattern"

module JobTomate
  module Events
    module Circleci

      # Process CircleCI's "status_update" events (e.g. Build succeeded)
      class StatusUpdate
        extend ServicePattern

        # @param status [string] either 'success' or 'failed'
        def run(status)
          Actions::SlackNotifyOnCircleciStatusUpdate.run(status)
        end
      end
    end
  end
end
