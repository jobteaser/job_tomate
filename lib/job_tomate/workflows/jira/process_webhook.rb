require 'active_support/all'
Dir[File.expand_path('../rules/*.rb', __FILE__)].each { |f| require f }

module JobTomate
  module Workflows
    module Jira
      class ProcessWebhook

        # Handles JIRA wehbooks (see README for details on webhook configuration).
        #
        # Performs the following tasks:
        #   - Sets the developer or the reviewer when not set and can be determined
        #     by the workflow.
        #   - Sets the assignee to the appropriate team member according to the
        #     workflow and status change.
        #
        # The operation is performed on JIRA using the user that performed
        # the issue change. If the user is not available on JobTomate, the
        # first user in the database is used.
        def self.run(webhook_data)
          rules_modules.each { |rules_module| apply(rules_module, webhook_data) }
        end

        # Applying the specified rules.
        # Exceptions are caught to prevent breaking the application
        # of other rules coming after.
        def self.apply(rules, webhook_data)
          rules.apply(webhook_data)
        rescue => e
          LOGGER.error e
        end

        def self.rules_modules
          rules_module_constants = JobTomate::Workflows::Jira::Rules.constants
          rules_module_constants.map do |rules_module|
            JobTomate::Workflows::Jira::Rules.const_get(rules_module)
          end
        end
      end
    end
  end
end
