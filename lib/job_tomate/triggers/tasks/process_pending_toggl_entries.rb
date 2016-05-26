require "commands/toggl/find_entry"
require "commands/toggl/update_entry"
require "events/toggl/new_report"
require "events/toggl/updated_report"
require "support/service_pattern"

module JobTomate
  module Triggers
    module Tasks

      # Process all pending entries (`Data::TogglEntry`).
      # Triggers the `Toggl::UpdatedReport` event for each pending
      # entry.
      #
      # NB: This event is appropriate because it handles all
      # possible cases and is compatible for both new and updated
      # report cases.
      class FetchTogglReports
        extend ServicePattern

        def run
          entries = Commands::Toggl::FindPendingEntries.run
          process_entries(entries)
        end

        def process_entries(entries)
          entries.each do |entry|
            Events::Toggl::UpdatedReport.run(entry)
          end
        end
      end
    end
  end
end
