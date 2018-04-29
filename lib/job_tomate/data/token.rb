# frozen_string_literal: true

require "mongoid"

module JobTomate
  module Data

    # Store tokens for external integrations.
    class Token
      include Mongoid::Document
      include Mongoid::Timestamps

      store_in collection: "tokens"

      field :token_id, type: String
      field :value, type: String
    end
  end
end
