require 'mongoid'
require 'job_tomate/data/slack_message'

module JobTomate
  module Data

    # Represents a Slack channel that can be
    # interacted with by JobTomate.
    class SlackChannel
      include Mongoid::Document
      include Mongoid::Timestamps

      store_in collection: 'slack_channels'

      field :slack_id, type: String
      field :archived, type: Boolean
    end
  end
end
