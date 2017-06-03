# frozen_string_literal: true

require "job_tomate/commands/jira/support/client"
require "support/service_pattern"

module JobTomate
  module Commands
    module JIRA

      # Command to fetch issue fields from JIRA. This is useful
      # to find the identifier to use in code for a given custom
      # field.
      #
      # How to use?
      #
      #    ENV["JIRA_USERNAME"] = <some jira username>
      #    ENV["JIRA_PASSWORD"] = <the user's password>
      #    JSON.parse(JobTomate::Commands::JIRA::GetFields.run().body)
      #
      class GetFields
        extend ServicePattern

        API_USERNAME = ENV["JIRA_USERNAME"]
        API_PASSWORD = ENV["JIRA_PASSWORD"]

        def self.run
          JobTomate::Commands::JIRA::Client.exec_request_base(
            :get, "/field",
            API_USERNAME, API_PASSWORD,
            {} # body
          )
        end
      end
    end
  end
end
