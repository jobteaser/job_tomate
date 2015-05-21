require 'mongoid'
require 'config/mongo'

module JobTomate
  class TogglEntry
    include Mongoid::Document
    include Mongoid::Timestamps

    store_in collection: 'toggl_entries'

    # Possible statuses:
    #   - new
    #   - sent_to_jira
    #   - ..._modified
    field :status,            type: String

    field :toggl_id,          type: String
    field :toggl_updated,     type: Time
    field :added_to_jira_at,  type: Time
  end
end
