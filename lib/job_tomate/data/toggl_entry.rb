require 'mongoid'
require 'config/mongo'

module JobTomate
  module Data

    # `status` values:
    #   - pending: initial status
    #   - sent_to_jira: the issue has been sent to JIRA
    #     successfully
    # Each status may be suffixed by `_modified` if the
    # time entry is received from Toggl and an update
    # has occured.
    class TogglEntry
      include Mongoid::Document
      include Mongoid::Timestamps

      store_in collection: 'toggl_entries'

      field :status,            type: String
      field :toggl_id,          type: String
      field :toggl_updated,     type: Time
    end
  end
end
