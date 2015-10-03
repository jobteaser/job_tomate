require 'rspec'
require 'pry'

ENV['APP_ENV'] = 'test'
# Setup app-specific environment variables
test_environment = {
  'JIRA_DEFAULT_USERNAMES_FOR_FUNCTIONAL_REVIEW' => 'func.rev1,func.rev2',
  'JIRA_ACCEPTED_USERNAMES_FOR_FUNCTIONAL_REVIEW' => 'acc.func',
  'JIRA_ISSUE_URL_BASE' => 'url',
  'MONGODB_URI' => 'mongodb://127.0.0.1:27017/job_tomate_test'
}
test_environment.each { |k, v| ENV[k] = v }

require File.expand_path('../../config/boot', __FILE__)

require 'job_tomate/user'
require 'job_tomate/toggl_entry'
RSpec.configure do |config|
  config.after(:each) do
    JobTomate::User.delete_all
    JobTomate::TogglEntry.delete_all
  end
end
