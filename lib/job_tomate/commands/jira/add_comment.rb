require "commands/base"
require "commands/jira/support/client"

module JobTomate
  module Commands
    module JIRA

      # Add a comment to a JIRA issue
      class AddComment < Base

        # @param issue_key [String]
        # @param username [String]
        # @param password [String]
        # @param comment [String] text for the comment
        def run(issue_key, username, password, comment)
          body = {
            body: comment
          }

          if ENV["JIRA_DRY_RUN"] != "true"
            Client.exec_request(:post, "/issue/#{issue_key}/comment", username, password, body)
          else
            true
          end
        end
      end
    end
  end
end
