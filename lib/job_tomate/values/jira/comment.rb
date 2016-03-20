module JobTomate
  module Values
    module JIRA

      # A value object to encapsulate JIRA issue comment data.
      class Comment
        attr_reader :data

        # @param comment [Hash] the JIRA representation of an
        #   issue comment
        def self.build(comment_data)
          new(comment_data)
        end

        def initialize(comment_data)
          @data = comment_data
        end

        def body
          data["body"]
        end

        # @return [[Data::User]] array of users identified from
        #   mentioned usernames in the comment's body, matched
        #   against users in the database with the same
        #   jira_username.
        def mentioned_users
          @mentioned_users ||= (
            mentioned_usernames = body.scan(/\[~[^\]]+\]/).map do |s|
              s.gsub(/[\[\]~]/, "")
            end
            mentioned_usernames.uniq.map do |username|
              JobTomate::Data::User.where(jira_username: username).first
            end.compact
          )
        end

        # Takes the comment body and replaces occurrence of JIRA
        # user mentions (`[~jira.user]`) by Slack user mentions
        # (`@slack.user`).
        #
        # TODO: find a better place for this logic. It's not necessary
        #   for the moment, but we couple Slack implementation with
        #   a JIRA component, which is bad coupling.
        def body_for_slack
          @body_for_slack ||= (
            rewritten_body = body.clone
            mentioned_users.each do |user|
              next if user.slack_username.blank?
              rewritten_body.gsub! "[~#{user.jira_username}]", "@#{user.slack_username}"
            end
            rewritten_body
          )
        end
      end
    end
  end
end
