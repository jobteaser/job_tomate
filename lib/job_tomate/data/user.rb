require "mongoid"

module JobTomate
  module Data

    # Store users in database with credentials and
    # identifiers to the appropriate services.
    # 
    # NB: The records are synchronized with a Google Sheets
    # document. See `script/sync_config_from_google_sheets.rb`
    # for more information.
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
      field :product_manager,           type: Boolean
      field :jira_functional_reviewer,  type: Boolean # TODO: should be `functional_reviewer`
      field :slack_username,            type: String
    end
  end
end
