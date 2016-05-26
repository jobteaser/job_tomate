require "job_tomate/data/toggl_entry"
require "support/service_pattern"

module JobTomate
  module Commands
    module Toggl

      # Find entries with status "pending"
      class FindPendingEntries
        extend ServicePattern

        def run
          Data::TogglEntry.where(status: "pending").all
        end
      end
    end
  end
end
