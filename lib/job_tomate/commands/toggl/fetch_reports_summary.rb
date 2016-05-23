require "job_tomate/commands/toggl/support/client"
require "support/service_pattern"

module JobTomate
  module Commands
    module Toggl

      # Fetch reports from Toggl between the specified dates.
      class FetchReportsSummary
        extend ServicePattern

        # @param date_since [Date]
        # @param date_until [Date]
        # @param grouping [String] Toggl grouping type
        # @param subgrouping [String] Toggl subgrouping type, optional
        def run(date_since, date_until, grouping, subgrouping = nil)
          options = {
            since: date_since.strftime("%Y-%m-%d"),
            until: date_until.strftime("%Y-%m-%d"),
            grouping: grouping
          }
          options[:subgrouping] = subgrouping unless subgrouping.nil?
          Client.fetch_reports_summary(options)
        end
      end
    end
  end
end
