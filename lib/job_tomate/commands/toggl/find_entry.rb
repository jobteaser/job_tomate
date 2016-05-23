require "job_tomate/data/toggl_entry"
require "support/service_pattern"

module JobTomate
  module Commands
    module Toggl

      # Find the entry matching the passed Toggl report.
      class FindEntry
        extend ServicePattern

        def run(report)
          toggl_id = report["id"]
          Data::TogglEntry.where(toggl_id: toggl_id).first
        end
      end
    end
  end
end
