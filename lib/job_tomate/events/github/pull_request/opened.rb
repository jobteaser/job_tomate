require "events/base"
require "actions/jira/add_comment_as_job_tomate"

module JobTomate
  module Events
    module Github
      module PullRequest

        # Process Github's opened pull request events.
        #
        # Expected @description: Hash
        #   - base_ref
        #   - head_ref
        #   - html_url
        #   - merged
        class Opened < Base

          def run
            return if issue_key.blank?
            create_comment
          end

          private

          def issue_key
            @issue_key ||= description[:head_ref][/jt-[\d]+/i]
          end

          def create_comment
            Actions::JIRA::AddCommentAsJobTomate.run issue_key, comment
          end

          def comment
            "Opened PR: #{description[:html_url]}"
          end
        end
      end
    end
  end
end
