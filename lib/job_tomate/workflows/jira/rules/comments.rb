require 'active_support/all'
require 'job_tomate/workflows/jira/helpers'
require 'job_tomate/commands/slack/send_message'

module JobTomate
  module Workflows
    module Jira
      module Rules

        # Performs rules related to comments added to an issue:
        #   - notify mentioned user on Slack
        class Comments
          extend JobTomate::Workflows::Jira::Helpers

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

            users = mentioned_users(comment['body'])
            slack_comment = rewrite_users_in_jira_comment_for_slack(comment['body'], users)

            key = issue_key(webhook_data)
            users.each do |mentioned_user|
              slack_username = mentioned_user.slack_username
              next if slack_username.blank?
              Commands::Slack::SendMessage.run(
                "You were mentioned in a comment on #{slack_link_for_jira_issue(key)}: *#{slack_comment}*",
                channel: "@#{mentioned_user.slack_username}"
              )
            end
          end

          # Returns the `JobTomate::Data::User`s mentioned in the specified
          # JIRA comment body.
          def self.mentioned_users(comment_body)
            mentioned_jira_usernames = comment_body.scan(/\[~[^\]]+\]/).map { |s| s.gsub(/[\[\]~]/, '') }.uniq
            mentioned_jira_usernames.map do |jira_username|
              user_for_jira_username(jira_username)
            end.compact
          end

          # Takes a JIRA comment body and replaces occurrence of JIRA
          # user mentions (`[~jira.user]`) by Slack user mentions
          # (`@slack.user`).
          #
          # @param comment_body [String] JIRA comment body
          # @param users [Array of JobTomate::Data::User]
          def self.rewrite_users_in_jira_comment_for_slack(comment_body, users)
            rewritten_comment = comment_body.clone
            users.each do |user|
              rewritten_comment.gsub! "[~#{user.jira_username}]", "@#{user.slack_username}"
            end
            rewritten_comment
          end
        end
      end
    end
  end
end
