require 'job_tomate/commands/toggl/support/client'

module JobTomate
  module Commands
    module Toggl

      # Fetch reports from Toggl between the specified dates.
      class FetchReports

        # @param date_since [Date]
        # @param date_until [Date]
        def self.run(date_since, date_until)
          Client.fetch_reports(date_since, date_until)
        end
      end
    end
  end
end
