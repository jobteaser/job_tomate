require 'uri'
require 'active_support/all'
require 'httparty'

module JobTomate
  module Output

    # Usage:
    #   SlackWebhook.send('<@username>: Here\'s JobTomate!!!', channel: '#dev-team')
    #   SlackWebhook.send('<!channel>: Hello channel!')
    class SlackWebhook
      DEFAULT_CHANNEL = '#dev-team'
      DEFAULT_USERNAME = 'JobTomate'
      DEFAULT_ICON_URL = nil
      DEFAULT_ICON_EMOJI = ':japanese_ogre:'

      # Sends a message to Slack incoming webhook.
      #
      # @param text [String] message to send
      # @param channel [String] the channel to use (e.g. '#channel', '@username')
      # @param username [String] the username user for the message author
      # @param icon_url [String] URL for the icon of the message author (if present,
      #   takes over the emoji icon)
      # @param icon_emoji [String] emoji for the icon of the message author
      def self.send(text,
        channel: DEFAULT_CHANNEL,
        username: DEFAULT_USERNAME,
        icon_url: DEFAULT_ICON_URL,
        icon_emoji: DEFAULT_ICON_EMOJI)

        payload = build_payload(text, channel, username, icon_url, icon_emoji)

        if ENV['APP_ENV'] != 'development'
          send_payload(payload)
          LOGGER.info "Sent \"#{text}\" to Slack channel #{channel} as #{username}"
        else
          LOGGER.info "Would send \"#{text}\" to Slack channel #{channel} as #{username} (SKIPPED)"
        end
      end

      def self.build_payload(text, channel, username, icon_url, icon_emoji)
        base = {
          text: text,
          channel: channel,
          username: username,
        }
        return base.merge(icon_url: icon_url) if icon_url
        base.merge(icon_emoji: icon_emoji)
      end

      def self.send_payload(payload)
        headers = {
          'Content-Type' => 'application/json'
        }

        HTTParty.send(:post, ENV['SLACK_WEBHOOK_URL'],
          headers: headers,
          body: payload.to_json
        )
      end
    end
  end
end
