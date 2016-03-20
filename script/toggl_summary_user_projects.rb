#!/usr/bin/env ruby
#
# Displays (in the console) the total timespent (calculated
# from Toggl) for every team member for the specified period
# of time, for "Sprint", "Maintenance" and "Projects"
# Toggl groupings.
#
# Usage
#     ruby script/summary_user_projects.rb 2016-01-01 2016-01-28

require_relative "../config/boot"
require "job_tomate/commands/toggl/fetch_reports_summary"

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
  "projects",
  "users"
)
TEAMS = {
  "Rockets" => ["Aurelie Ginioux", "B Crouzier", "Benoit Dinocourt", "David Ruyer", "Ludovic Vielle"],
  "Sharks" => ["Poilon", "Francois Sevaistre", "Charly Poly", "Bakari Sumaila"],
}
TEAMS["All"] = TEAMS.values.flatten + ["Romain"]

PROD_PROJECTS = %w(Sprint Maintenance Projets)
TEAMS.each do |team, members|
  puts "TEAM #{team.upcase} SUMMARY"
  puts "============================"
  team_prod_total = 0
  team_total = 0
  reports["data"].each do |project_data|
    project_title = project_data["title"]["project"] || "N/A"
    team_project_total = 0
    project_data["items"].each do |project_item|
      next unless project_item["title"]["user"].in?(members)
      project_hours = ((project_item["time"] || 0) / (60 * 60 * 1000).to_f).round(1)
      team_project_total += project_hours
      team_prod_total += project_hours if project_title.in? PROD_PROJECTS
      team_total += project_hours
    end
    puts "#{project_title} => #{team_project_total.round(1)}h"
  end
  puts "  prod => #{team_prod_total.round(1)}h"
  puts "  total => #{team_total.round(1)}h"
  puts ""
end

reports = JobTomate::Commands::Toggl::FetchReportsSummary.run(
  date_since,
  date_until,
  "users",
  "projects"
)

puts "USER SUMMARY"
puts "============"
reports["data"].each do |user_data|
  puts user_data["title"]["user"]
  user_data["items"].each do |user_item|
    next unless user_item["title"]["project"].in? %w(Sprint Maintenance Projets)
    puts "  #{(user_item['title']['project'] || 'N/A')}  => #{((user_item['time'] || 0) / (60 * 60 * 1000).to_f).round(1)}h"
  end
  puts "  total => #{((user_data['time'] || 0) / (60 * 60 * 1000).to_f).round(1)}h"
end
