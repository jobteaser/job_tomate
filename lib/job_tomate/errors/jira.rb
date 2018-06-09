# frozen_string_literal: true

module JobTomate
  module Errors

    # JIRA errors
    module JIRA
      BaseError = Class.new(StandardError)
      NotFound = Class.new(BaseError)
      Unauthorized = Class.new(BaseError)
      UnknownError = Class.new(BaseError)
      UnknownUser = Class.new(BaseError)
      UnknownCustomField = Class.new(BaseError)
      MissingSharedUser = Class.new(BaseError)
    end
  end
end
