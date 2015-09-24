require 'active_support/all'
require 'job_tomate/input/jira/status_rules'
require 'job_tomate/input/jira/alerting_rules'

module JobTomate
  module Input
    module Jira
      class Processor

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
          StatusRules.apply(webhook_data)
          AlertingRules.apply(webhook_data)
        end
      end
    end
  end
end
