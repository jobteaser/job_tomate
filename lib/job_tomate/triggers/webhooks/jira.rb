require "data/webhook_payload"
require "errors/jira"
require "triggers/webhooks"
require "values/jira/changelog"
require "values/jira/comment"
require "values/jira/issue"

# Requiring all Events::JIRA class for handling issue
# updated events.
events_jira_dir = File.expand_path("../../../events/jira", __FILE__)
Dir[File.join(events_jira_dir, "/issue_*.rb")].each do |f|
  require f
end

module JobTomate
  module Triggers
    module Webhooks

      # Handling JIRA webhooks
      #
      # Setup the webhook with:
      #   - path: /webhooks/jira
      #   - issue related events, for all issues
      #   - enabled issue events "created", "updated", "deleted"
      #
      # Handling update events
      # ----------------------
      # To handle update events, you need to have the appropriate
      # event classe defined. For example, if you need to generate
      # an event for a change on the "status" field, you need to
      # define the Events::JIRA::IssueUpdatedStatus class.
      #
      # If you're not dealing with a default JIRA attribute, you
      # can specify the mapping in `Values::JIRA::Changelog`.
      #
      # All classes under /events/jira gets required at
      # the beginning of this file, so if an event class
      # matching the updated field is found, the corresponding
      # event is run. So to add a new event, you just have
      # to add the appropriate class, and the mapping if
      # necessary;
      class Jira < Base

        def self.definition
          {
            name: "jira",
            verb: :post,
            path: "/jira"
          }
        end

        def run_events
          run_events_for_issue_created if issue_created?
          run_events_for_issue_deleted if issue_deleted?
          run_events_for_issue_new_comment if issue_new_comment?
          run_events_for_issue_changelog if issue_changelog?
        end

        private

        def issue_created?
          webhook_event == "issue_created"
        end

        def issue_deleted?
          webhook_event == "issue_deleted"
        end

        def issue_new_comment?
          return false unless webhook_event == "issue_updated"
          webhook_data["comment"].present?
        end

        def issue_changelog?
          return false unless webhook_event == "issue_updated"
          webhook_data["changelog"].present?
        end

        def run_events_for_issue_created
          Events::JIRA::IssueCreated.run(issue_value)
        end

        def run_events_for_issue_deleted
          Events::JIRA::IssueDeleted.run(issue_value)
        end

        def run_events_for_issue_new_comment
          Events::JIRA::IssueCommentAdded.run(issue_value, comment_value)
        end

        # Run events for an issue update with a "changelog".
        # Multiple events may be run if the changelog contains
        # multiple items.
        def run_events_for_issue_changelog
          webhook_data["changelog"]["items"].each do |item|
            run_event_for_issue_changelog_item(item)
          end
        end

        def run_event_for_issue_changelog_item(item)
          changelog_value = Values::JIRA::Changelog.build(item)
          begin
            field = changelog_field(changelog_value)
            module_constant = "JobTomate::Events::JIRA::IssueUpdated#{field.camelize}".constantize
          rescue NameError
            # If the constant doesn't exist, it only means we have
            # no event to trigger.
            return
          end
          module_constant.run(issue_value, changelog_value)
        end

        def changelog_field(changelog_value)
          return changelog_value.field
        rescue Errors::JIRA::UnknownCustomField
          # We can ignore the error if we don't know the custom
          # field in this context, it means it's not handled.
          nil
        end

        # Accessors for on webhook data

        def issue_value
          @issue_value ||= Values::JIRA::Issue.build(webhook_data["issue"])
        end

        def comment_value
          @comment_value ||= Values::JIRA::Comment.build(webhook_data["comment"])
        end

        # @return [String] issue_created, issue_updated,
        #   or issue_deleted
        def webhook_event
          @webhook_event ||= webhook_data["webhookEvent"].gsub("jira:", "")
        end
      end
    end
  end
end
