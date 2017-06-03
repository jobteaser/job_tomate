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
      field :jira_developer,            type: Boolean # DEPRECATED: to be migrated and removed
      field :developer_backend,         type: Boolean
      field :developer_frontend,        type: Boolean
      field :jira_reviewer,             type: Boolean # TODO: should be `reviewer`
      field :jira_feature_owner,        type: Boolean # TODO: should be `feature_owner`
      field :jira_functional_reviewer,  type: Boolean # TODO: should be `functional_reviewer`
      field :slack_username,            type: String
    end
  end
end
