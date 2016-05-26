module JobTomate
  module Errors

    # JIRA errors
    module JIRA
      NotFound = Class.new(StandardError)
      Unauthorized = Class.new(StandardError)
      UnknownError = Class.new(StandardError)
      UnknownUser = Class.new(StandardError)
      UnknownCustomField = Class.new(StandardError)
      WorklogTooShort = Class.new(StandardError)
    end
  end
end
