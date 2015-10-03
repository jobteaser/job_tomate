require 'active_support/all'
require 'job_tomate/input/jira/helpers'
require 'job_tomate/interface/jira_client'
require 'job_tomate/output/slack_webhook'

module JobTomate
  module Input
    module Jira

      # Performs rules related to comments added to an issue:
      #   - notify mentioned user on Slack
      class CommentsRules
        extend Helpers

        def self.apply(webhook_data)
          notify_mentioned_user_in_new_comment(webhook_data)
        end

        # If the webhook event is a new comment ("webhookEvent" = "jira:issue_updated"
        # and "comment" value in the payload):
        #   - identify mentioned users,
        #   - notify them on Slack.
        def self.notify_mentioned_user_in_new_comment(webhook_data)
          return unless issue_updated?(webhook_data)
          comment = webhook_data['comment']
          return if comment.nil?

          comment_text = comment['body']
          mentioned_jira_usernames = comment_text.scan(/\[~[^\]]+\]/).map { |s| s.gsub(/[\[\]~]/, '') }.uniq

          mentioned_users = mentioned_jira_usernames.map do |jira_username|
            user_for_jira_username(jira_username)
          end.compact

          key = issue_key(webhook_data)
          mentioned_users.each do |mentioned_user|
            slack_username = mentioned_user.slack_username
            next if slack_username.blank?
            Output::SlackWebhook.send(
              "You were mentioned in a comment on #{slack_link_for_jira_issue(key)}: #{comment_text}",
              channel: "@#{mentioned_user.slack_username}"
            )
          end
        end
      end
    end
  end
end
