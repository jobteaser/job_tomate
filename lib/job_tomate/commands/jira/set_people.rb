require "job_tomate/commands/jira/support/client"

module JobTomate
  module Commands
    module Jira

      # Sets the people associated to the issue: assignee, developer,
      # reviewer.
      class SetPeople
        def self.run(issue_key, username, password, assignee, developer, reviewer)
          body = {
            fields: {
              assignee:           { name: assignee },
              customfield_10600:  { name: developer },
              customfield_10601:  { name: reviewer }
            }
          }

          if ENV["APP_ENV"] != "development"
            exec_request(:put, "/issue/#{issue_key}/", username, password, body)
            LOGGER.info "Assigned user (#{assignee}) to #{issue_key}"
          else
            LOGGER.info "Assigned user (#{assignee}) to #{issue_key} - SKIPPED"
          end
          true
        end
      end
    end
  end
end
