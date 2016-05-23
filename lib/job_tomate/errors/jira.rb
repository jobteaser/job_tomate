module JobTomate
  module Errors

    # JIRA errors
    module JIRA
      UnknownUser = Class.new(StandardError)
      UnknownCustomField = Class.new(StandardError)
      WorklogTooShort = Class.new(StandardError)
    end
  end
end
