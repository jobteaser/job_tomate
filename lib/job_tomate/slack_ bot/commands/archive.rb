require 'slack-ruby-bot'
require 'job_tomate/data/slack_channel'
require 'job_tomate/data/slack_message'

module JobTomate
  module SlackBot
    module Commands

      # A command module to archive all messages on interesting channels or
      # messages with "archive".
      # Available commands:
      #   - archive this channel: add the current channel to the list of
      #     automatically archived channels
      #   - stop archiving this channel: remove the current channel from
      #     the list of archived channels
      #   - archived channels: list all archived channels
      #
      # TODO: all this
      class Archive < SlackRubyBot::Commands::Base

        match(/archived channels/) do |client, data, _match|
          message = archived_channels_message(client)
          send_message client, data.channel, message
        end

        match(/archive current channel/) do |client, data, _match|
          channel_id = data['channel']
          message = add_archived_channel(channel_id, client)
          send_message client, data.channel, message
        end

        match(/stop archiving current channel/) do |client, data, _match|
          channel_id = data['channel']
          name = channel_name(client, channel_id)

          message = (
            if remove_archived_channel(channel_id)
              "Stopped archiving channel ##{name}!"
            else
              "Could not stop archiving channel ##{name}"
            end
          )
          message << " #{archived_channels_message(client)}"

          send_message client, data.channel, message
        end

        # Archive the message if:
        #   - hashtag #archive
        #   - in one of the archived channels
        match(/.*/) do |client, data, _match|
          if should_archive_message?(data)
            archive_message(client, data)
            unless in_archived_channel?(data)
              send_message client, data.channel, 'Got it!'
            end
          end
        end

        # IMPLEMENTATION

        def self.archive_message(client, data)
          channel_name = channel_name(client, data.channel)
          logger.info "Archived #{data.text} for channel ##{channel_name}"
          Data::SlackMessage.create slack_user_id: data.user, slack_channel_id: data.channel, text: data.text
        end

        def self.should_archive_message?(data)
          archive_keyword?(data) || in_archived_channel?(data)
        end

        def self.archive_keyword?(data)
          data.text =~ /#archive/
        end

        def self.in_archived_channel?(data)
          find_archived_channel(data.channel) != nil
        end

        def self.find_archived_channel(channel_id)
          Data::SlackChannel.where(slack_id: channel_id, archived: true).first
        end

        def self.add_archived_channel(channel_id, client)
          client_channel = find_client_channel(channel_id, client)
          return 'This is not a channel!' if client_channel.nil?

          return 'Channel is already archived!' if find_archived_channel(channel_id)

          name = channel_name(client, channel_id)
          message = (
            if Data::SlackChannel.create slack_id: channel_id, archived: true
              "Archiving channel ##{name}!"
            else
              "Could not archive channel ##{name}..."
            end
          )
          message + " #{archived_channels_message(client)}"
        end

        def self.find_client_channel(channel_id, client)
          client.channels.find { |c| c['id'] == channel_id }
        end

        def self.remove_archived_channel(channel_id)
          channel = find_archived_channel(channel_id)
          return false if channel.nil?
          channel.destroy
          true
        end

        def self.channel_name(client, channel_id)
          channel = find_client_channel(channel_id, client)
          return nil if channel.nil?
          channel['name']
        end

        def self.archived_channels_message(client)
          names = archived_channel_names(client)
          return 'No archived channels yet!' if names.empty?
          "Archived channels: #{names.join(', ')}"
        end

        def self.archived_channel_names(client)
          channels = archived_channels(client)
          channels.map do |channel|
            "##{channel['name']}"
          end
        end

        def self.archived_channels(client)
          ids = Data::SlackChannel.where(archived: true).map(&:slack_id)
          client.channels.select do |channel|
            channel['id'].in?(ids)
          end
        end
      end
    end
  end
end
