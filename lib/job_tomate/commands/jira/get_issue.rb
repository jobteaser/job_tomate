require "job_tomate/commands/jira/support/client"

module JobTomate
  module Commands
    module Jira

      # SearchIssues.run(jql: {...}) to perform a search on
      # JIRA issues with the specified JQL string.
      #
      # Uses JIRA user defined by JIRA_USERNAME and JIRA_PASSWORD
      # environment variables.
      class GetIssue
        API_USERNAME = ENV["JIRA_USERNAME"]
        API_PASSWORD = ENV["JIRA_PASSWORD"]

        def self.run(key)
          JobTomate::Commands::Jira::Client.exec_request(
            :get, "/issue/#{key}",
            API_USERNAME, API_PASSWORD,
            {} # body
          )
        end
      end
    end
  end
end
