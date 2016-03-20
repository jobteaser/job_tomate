require "job_tomate/commands/toggl/support/client"
require "job_tomate/commands/base"

module JobTomate
  module Commands
    module Toggl

      # Fetch reports from Toggl between the specified dates.
      class FetchReports < Base

        # @param date_since [Date]
        # @param date_until [Date]
        def run(date_since, date_until)
          if date_until.year > date_since.year
            run(date_since, date_since.end_of_year) + run(date_since.end_of_year + 1.day, date_until)
          else
            options = {
              since: date_since.strftime("%Y-%m-%d"),
              until: date_until.strftime("%Y-%m-%d")
            }
            Client.fetch_reports_multiple_pages(options)
          end
        end
      end
    end
  end
end
