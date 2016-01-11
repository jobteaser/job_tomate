require 'job_tomate/commands/jira/support/client'

module JobTomate
  module Commands
    module Jira

      # TODO
      class SetPeople
        def self.run(*args)
          Client.set_people(args)
        end
      end
    end
  end
end
