require "job_tomate/commands/base"
require "job_tomate/commands/jira/support/client"

module JobTomate
  module Commands
    module Jira

      # Updates a JIRA issue using the specified body
      # param.
      class UpdateIssue < Base

        def run(issue_key, username, password, body)
          update(issue_key, username, password, body)
        end

        private

        def update(issue_key, username, password, body)
          Client.exec_request(:put, "/issue/#{issue_key}/", username, password, body)
          true
        end
      end
    end
  end
end
