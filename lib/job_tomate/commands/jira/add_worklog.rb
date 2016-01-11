require 'job_tomate/commands/jira/support/client'

module JobTomate
  module Commands
    module Jira

      # TODO
      class AddWorklog
        def self.run(*args)
          Client.add_worklog(args)
        end
      end
    end
  end
end
