require "events/toggl/helpers"

module JobTomate
  module Events
    module Toggl

      # Event for new TogglEntry created (occurs when
      # a new Toggl report has been fetched and saved
      # to a TogglEntry).
      class NewReport
        include Helpers

        attr_reader :entry

        # @param entry [Data::TogglEntry]
        def self.run(entry)
          new(entry).run
        end

        def initialize(entry)
          @entry = entry
        end

        def run
          return update_entry_not_related_to_jira unless related_to_jira?
          create_worklog_and_update_entry
        end
      end
    end
  end
end
