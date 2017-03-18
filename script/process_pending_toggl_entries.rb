#!/usr/bin/env ruby

# This script processes all pending Toggl entries. It will not fail if 
# failing entries are met, only log some information about the failure.

require_relative "../config/boot"
require "job_tomate/data/toggl_entry"
require "job_tomate/events/toggl/updated_report"

JobTomate::LOGGER.level = ::Logger::ERROR

pending_count = JobTomate::Data::TogglEntry.where(status: "pending").count
puts "#{pending_count} Toggl entries pending"

toggl_users = JobTomate::Data::TogglEntry.where(status: "pending").all.map(&:toggl_user).uniq
puts "The database contains pending Toggl entries for the following Toggl users:"
toggl_users.each do |user|
  JobTomate::Data::TogglEntry.where(status: "pending", toggl_user: user).each do |entry|
    begin
      JobTomate::Events::Toggl::UpdatedReport.run(entry)
      puts "#{user}: ok"
    rescue => e
      puts "#{user}: #{e}"
    end
  end
end
