# frozen_string_literal: true

require "events/toggl/helpers"
require "support/service_pattern"

module JobTomate
  module Events
    module Toggl

      # Event for new TogglEntry created (occurs when
      # a new Toggl report has been fetched and saved
      # to a TogglEntry).
      class NewReport
        extend ServicePattern
        include Helpers

        # @param entry [Data::TogglEntry]
        def run(entry)
          @entry = entry
          return update_entry_not_related_to_jira unless related_to_jira?
          add_worklog_and_update_entry
        end
      end
    end
  end
end
