require 'mongoid'
require 'config/mongo'

module JobTomate
  module Data

    # STATES (`status`)
    # =================
    #   - "pending": when created and not yet processed
    #   - "synced_with_jira": the issue has been sent to JIRA
    #     successfully
    #   - "not_related_to_jira": there is no apparent link between
    #     this report and a JIRA issue
    #
    # TRANSITIONS
    # ===========
    # FROM "pending":
    #   TO "synced_with_jira": when processed and synced with a JIRA
    #     worklog, OR
    #   TO "not_related_to_jira": when processed and not related to a
    #     JIRA issue
    #
    # When the entry is updated (if it changed on Toggl
    # side), it goes back to "pending".
    class TogglEntry
      include Mongoid::Document
      include Mongoid::Timestamps

      store_in collection: 'toggl_entries'

      field :status,            type: String
      field :toggl_id,          type: String
      field :toggl_started,     type: Time
      field :toggl_updated,     type: Time
      field :toggl_duration,    type: Integer # converted to seconds
      field :toggl_description, type: String
      field :toggl_user,        type: String
      field :jira_issue_key,    type: String
      field :jira_worklog_id,   type: String

      field :history,           type: Array

      index({ toggl_started: 1 }, unique: false)
    end
  end
end
