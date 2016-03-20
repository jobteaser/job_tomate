require "mongoid"
require "config/mongo"

module JobTomate
  module Data

    # JobTomate::Data::TogglEntry
    #
    # STATES (`status`)
    # =================
    #   - "pending": when created and not yet processed
    #   - "synced": the issue has been sent to JIRA
    #     successfully
    #   - "not_related_to_jira": there is no apparent link between
    #     this report and a JIRA issue
    #   - "too_short": the worklog is too short to be added to JIRA
    #     and is simply ignored
    #
    # TRANSITIONS
    # ===========
    #
    # - FROM pending TO:
    #   - synced
    #   - not_related_to_jira
    #   - too_short
    # - FROM synced TO pending (on Toggl entry update)
    #
    class TogglEntry
      include Mongoid::Document
      include Mongoid::Timestamps

      store_in collection: "toggl_entries"

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
