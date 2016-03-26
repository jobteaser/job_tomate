require "events/base"
require "job_tomate/commands/jira/add_comment"

module JobTomate
  module Events
    module Github
      module PullRequest

        # Process Github's merged pull request events.
        class Merged < Base
        end
      end
    end
  end
end
