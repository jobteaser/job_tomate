require "job_tomate/commands/base"
require "job_tomate/data/toggl_entry"

module JobTomate
  module Commands
    module Toggl

      # Find the entry matching the passed Toggl report.
      class FindEntry < Commands::Base
        def run(report)
          toggl_id = report["id"]
          Data::TogglEntry.where(toggl_id: toggl_id).first
        end
      end
    end
  end
end
