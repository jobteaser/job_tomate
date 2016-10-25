require "commands/toggl/find_pending_entries"
require "errors/jira"
require "events/toggl/updated_report"
require "support/service_pattern"

module JobTomate
  module Triggers
    module Tasks

      # Process all pending entries (`Data::TogglEntry`).
      # Triggers the `Toggl::UpdatedReport` event for each pending
      # entry.
      #
      # Usage:
      #
      #     # From shell
      #     bin/run_task process_pending_entries
      #
      #     # In console
      #     JobTomate::Triggers::Tasks::ProcessPendingTogglEntries.run
      #
      # NB: This event is appropriate because it handles all
      # possible cases and is compatible for both new and updated
      # report cases.
      class ProcessPendingTogglEntries
        extend ServicePattern

        def run
          entries = Commands::Toggl::FindPendingEntries.run
          process_entries(entries)
        end

        def process_entries(entries)
          entries.each do |entry|
            begin
              Events::Toggl::UpdatedReport.run(entry)
            rescue JobTomate::Errors::JIRA::BaseError => e
              LOGGER.error "JIRA error: #{e}"
            end
          end
        end
      end
    end
  end
end
