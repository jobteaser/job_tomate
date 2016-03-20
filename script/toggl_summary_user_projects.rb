#!/usr/bin/env ruby
#
# Displays (in the console) the total timespent (calculated
# from Toggl) for every team member for the specified period
# of time, for "Sprint", "Maintenance" and "Projects"
# Toggl groupings.
#
# Usage
#     ruby script/summary_user_projects.rb 2016-01-01 2016-01-28

require_relative '../config/boot'
require 'job_tomate/commands/toggl/fetch_reports_summary'

USAGE = "Usage: ruby script/toggl_summary_user_projects.rb YYYY-MM-DD YYYY-MM-DD"
if ARGV.count != 2
  puts USAGE
  exit
end

date_since = Date.parse ARGV[0]
date_until = Date.parse ARGV[1]

reports = JobTomate::Commands::Toggl::FetchReportsSummary.run(
  date_since,
  date_until,
  'projects'
)

puts 'TEAM SUMMARY'
puts '============'
prod_total = 0
PROD_PROJECTS = %w(Sprint Maintenance Projets)
reports['data'].each do |project_data|
  project_title = project_data['title']['project'] || 'N/A'
  project_hours = ((project_data['time'] || 0) / (60 * 60 * 1000).to_f).round(1)
  prod_total += project_hours if project_title.in? PROD_PROJECTS
  puts "#{project_title} => #{project_hours}h"
end
puts "  prod => #{prod_total}h"
puts "  total => #{((reports['total_grand'] / 3_600_000).to_f).round(1)}h"
puts ''

reports = JobTomate::Commands::Toggl::FetchReportsSummary.run(
  date_since,
  date_until,
  'users',
  'projects'
)

puts 'USER SUMMARY'
puts '============'
reports['data'].each do |user_data|
  puts user_data['title']['user']
  user_data['items'].each do |user_item|
    next unless user_item['title']['project'].in? %w(Sprint Maintenance Projets)
    puts "  #{(user_item['title']['project'] || 'N/A')}  => #{((user_item['time'] || 0) / (60 * 60 * 1000).to_f).round(1)}h"
  end
  puts "  total => #{((user_data['time'] || 0) / (60 * 60 * 1000).to_f).round(1)}h"
end
