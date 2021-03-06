require "job_tomate/commands/jira/support/client"
require "support/service_pattern"

module JobTomate
  module Commands
    module JIRA

      # SearchIssues.run(jql: {...}) to perform a search on
      # JIRA issues with the specified JQL string.
      class SearchIssues
        extend ServicePattern

        API_USERNAME = ENV["JIRA_USERNAME"]
        API_PASSWORD = ENV["JIRA_PASSWORD"]
        MAX_RESULTS = 1000

        def run(jql: jql_query)
          JobTomate::Commands::JIRA::Client.exec_request(
            :get, "/search",
            API_USERNAME, API_PASSWORD,
            {}, # body
            jql: jql,
            startAt: 0,
            fields: "id",
            maxResults: MAX_RESULTS
          )
        end
      end
    end
  end
end
