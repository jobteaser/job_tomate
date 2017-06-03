# frozen_string_literal: true

require "job_tomate/commands/jira/support/client"
require "support/service_pattern"

module JobTomate
  module Commands
    module JIRA

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
