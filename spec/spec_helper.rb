require 'rspec'
require 'pry'

ENV['APP_ENV'] = 'test'

if ENV['CI']
  # Running on CI, setup Coveralls
  require 'coveralls'
  Coveralls.wear!
else
  # Running locally, setup simplecov
  require 'simplecov'
  require 'simplecov-json'
  SimpleCov.formatter = SimpleCov::Formatter::JSONFormatter
  SimpleCov.start do
    add_filter do |src|
      # Ignoring files from the spec directory
      src.filename =~ %r{/spec/}
    end
  end
end

# Setup app-specific environment variables
test_environment = {
  'JIRA_DEFAULT_USERNAMES_FOR_FUNCTIONAL_REVIEW' => 'func.rev1,func.rev2',
  'JIRA_ACCEPTED_USERNAMES_FOR_FUNCTIONAL_REVIEW' => 'acc.func',
  'JIRA_ISSUE_URL_BASE' => 'url',
  'MONGODB_URI' => 'mongodb://127.0.0.1:27017/job_tomate_test'
}
test_environment.each { |k, v| ENV[k] = v }

require File.expand_path('../../config/boot', __FILE__)

require 'job_tomate/data/user'
require 'job_tomate/data/toggl_entry'
require 'job_tomate/data/webhook_payload'

RSpec.configure do |config|
  config.after(:each) do
    JobTomate::Data::User.delete_all
    JobTomate::Data::TogglEntry.delete_all
    JobTomate::Data::WebhookPayload.delete_all
  end
end
