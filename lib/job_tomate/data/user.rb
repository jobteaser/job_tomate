require 'mongoid'

module JobTomate
  module Data
    class User
      include Mongoid::Document
      include Mongoid::Timestamps

      store_in collection: 'users'

      field :toggl_user,          type: String
      field :github_user,         type: String
      field :jira_username,       type: String
      field :jira_password,       type: String
      field :slack_username,      type: String
    end
  end
end
