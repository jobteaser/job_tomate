#!/usr/bin/env ruby

# This script displays the list of users for whom Toggl entries
# are pending.

require_relative "../config/boot"
require "job_tomate/data/toggl_entry"
require "job_tomate/events/toggl/updated_report"

JobTomate::LOGGER.level = ::Logger::ERROR

toggl_users = JobTomate::Data::TogglEntry.where(status: "pending").all.map(&:toggl_user).uniq
puts "The database contains pending Toggl entries for the following Toggl users:"
toggl_users.each do |user|
  entry = JobTomate::Data::TogglEntry.where(status: "pending", toggl_user: user).first
  begin
    JobTomate::Events::Toggl::UpdatedReport.run(entry)
    puts "#{user}: ok"
  rescue => e
    puts "#{user}: #{e}"
  end
end
