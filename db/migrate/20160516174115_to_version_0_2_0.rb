#!/usr/bin/env ruby

# Script for migrating data from older version to version 0.2.0.
#
# Migration process:
#
#     ruby db/migrate/20160516174115_to_version_0_2_0.rb
#     bin/run_task fetch_toggl_reports

$LOAD_PATH.unshift File.expand_path(".")
require "config/boot"
require "lib/job_tomate/data/toggl_entry"

# Deleting all pending Toggl entries (either they are recent enough
# and we will reprocess them, or they are too old and we can ignore
# them).
failed_entries = JobTomate::Data::TogglEntry.where(status: { "$in": %w(pending pending_modified) })
failed_entries_count = failed_entries.count
failed_entries.each do |e|
  e.status = "failed"
  e.save!
end
JobTomate::LOGGER.info "#{failed_entries_count} Toggl entries set to status \"failed\""

# Verifying only "sent_to_jira" and "sent_to_jira_modified" entries remain.
synced_entries = JobTomate::Data::TogglEntry.where(status: { "$in": %w(sent_to_jira sent_to_jira_modified) })
synced_entries_count = synced_entries.count
synced_entries.each do |e|
  e.status = "synced"
  e.save!
end
JobTomate::LOGGER.info "#{synced_entries_count} Toggl entries set to status \"synced\""

other_entries = JobTomate::Data::TogglEntry.where(status: { "$nin": %w(synced failed) })
JobTomate::LOGGER.info "#{other_entries.count} Toggl entries not synced nor failed"
