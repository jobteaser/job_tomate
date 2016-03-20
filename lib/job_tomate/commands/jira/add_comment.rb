require 'job_tomate/commands/jira/support/client'

module JobTomate
  module Commands
    module Jira

      # TODO
      class AddComment
        def self.run(issue_key, username, password, comment)
          body = {
            body: comment
          }

          log_message = "Add comment (#{comment}) to #{issue_key} as #{username}"
          if ENV['APP_ENV'] != 'development'
            Client.exec_request(:post, "/issue/#{issue_key}/comment", username, password, body)
            LOGGER.info log_message
          else
            LOGGER.info "#{log_message} - SKIPPED"
            return true
          end
        end
      end
    end
  end
end
