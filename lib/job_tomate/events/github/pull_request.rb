require "events/base"
require "actions/jira/add_comment_as_job_tomate"

module JobTomate
  module Events
    module Github

      # Process Github's "pull_request" events.
      # It handles 2 cases:
      #   - merged,
      #   - not merged.
      #
      # Expected @description: Hash
      #   - base_ref
      #   - head_ref
      #   - html_url
      #   - merged
      class PullRequest < Base

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
          return comment_opened if opened?
          return comment_closed if closed?
          fail "Unhandled pull_request event action \"#{description[:action]}\""
        end

        def comment_opened
          "Opened PR: #{description[:html_url]}"
        end

        def comment_closed
          if merged?
            "Merged PR in #{description[:base_ref]}: #{description[:html_url]}"
          else
            "Closed PR without merging: #{description[:html_url]}"
          end
        end

        def opened?
          description[:action] == "opened"
        end

        def closed?
          description[:action] == "closed"
        end

        def merged?
          description[:merged] == true
        end
      end
    end
  end
end
