require "job_tomate/commands/jira/support/client"

module JobTomate
  module Commands
    module Jira

      # Returns worklog of the specified issue
      # See https://docs.atlassian.com/jira/REST/latest/#api/2/issue-getIssueWorklog
      #
      # Uses JIRA user defined by JIRA_USERNAME and JIRA_PASSWORD
      # environment variables.
      class GetIssueWorklog
        API_USERNAME = ENV["JIRA_USERNAME"]
        API_PASSWORD = ENV["JIRA_PASSWORD"]

        def self.run(key)
          Client.exec_request(
            :get, "/issue/#{key}/worklog",
            API_USERNAME, API_PASSWORD,
            {} # body
          )
        end
      end
    end
  end
end
