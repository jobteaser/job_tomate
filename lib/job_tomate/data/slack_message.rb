require 'mongoid'

module JobTomate
  module Data

    # Represents a Slack channel that can be
    # interacted with by JobTomate.
    class SlackMessage
      include Mongoid::Document
      include Mongoid::Timestamps

      store_in collection: 'slack_messages'

      field :slack_user_id, type: String
      field :slack_channel_id, type: String
      field :text, type: String
    end
  end
end
