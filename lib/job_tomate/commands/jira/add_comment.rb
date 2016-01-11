require 'job_tomate/commands/jira/support/client'

module JobTomate
  module Commands
    module Jira

      # TODO
      class AddComment
        def self.run(*args)
          Client.add_comment(*args)
        end
      end
    end
  end
end
