require "mongoid"

module JobTomate
  module Data

    # Store users in database with credentials and
    # identifiers to the appropriate services.
    class User
      include Mongoid::Document
      include Mongoid::Timestamps

      store_in collection: "users"

      field :toggl_user,                type: String
      field :github_user,               type: String
      field :jira_username,             type: String
      field :jira_password,             type: String
      field :jira_developer,            type: Boolean
      field :jira_reviewer,             type: Boolean
      field :jira_feature_owner,        type: Boolean
      field :jira_functional_reviewer,  type: Boolean
      field :slack_username,            type: String
    end
  end
end
