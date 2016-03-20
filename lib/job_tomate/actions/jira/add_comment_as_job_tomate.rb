require "commands/jira/add_comment"

module JobTomate
  module Actions
    module JIRA

      # Adds a JIRA comment as JobTomate
      class AddCommentAsJobTomate

        def self.run(issue_key, comment)
          Commands::Jira::AddComment.run(
            issue_key,
            ENV["JIRA_USERNAME"],
            ENV["JIRA_PASSWORD"],
            comment
          )
        end
      end
    end
  end
end
