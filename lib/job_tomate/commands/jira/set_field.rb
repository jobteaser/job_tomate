require "commands/jira/support/client"
require "support/service_pattern"

module JobTomate
  module Commands
    module JIRA

      # Add a comment to a JIRA issue
      class SetField
        extend ServicePattern

        # @param issue_key [String]
        # @param username [String]
        # @param password [String]
        # @param comment [String] text for the comment
        def run(issue_key, username, password, field, value)
          body = {
            fields: {
              :"#{field}" => value
            }
          }

          if ENV["JIRA_DRY_RUN"] != "true"
            Client.exec_request(:put, "/issue/#{issue_key}", username, password, body)
          else
            true
          end
        end
      end
    end
  end
end
