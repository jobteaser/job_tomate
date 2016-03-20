require "job_tomate/commands/base"
require "job_tomate/commands/jira/support/client"

module JobTomate
  module Commands
    module JIRA

      # Updates a JIRA issue using the specified body
      # param.
      class UpdateIssue < Base

        # @param issue_key [String]
        # @param body [Hash]
        # @param username [String] optional, defaults to ENV["JIRA_USERNAME"]
        # @param password [String] optional, defaults to ENV["JIRA_PASSWORD"]
        #
        def run(issue_key, body, username = ENV["JIRA_USERNAME"], password = ENV["JIRA_PASSWORD"])
          Client.exec_request(:put, "/issue/#{issue_key}", username, password, body)
        end
      end
    end
  end
end
