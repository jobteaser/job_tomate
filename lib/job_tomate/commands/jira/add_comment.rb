require "commands/jira/support/client"
require "support/service_pattern"

module JobTomate
  module Commands
    module JIRA

      # Add a comment to a JIRA issue
      class AddComment
        extend ServicePattern

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
