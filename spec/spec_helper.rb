# frozen_string_literal: true

require "rspec"
require "webmock/rspec"
require "rack/test"
require "pry"

ENV["RACK_ENV"] = "test"

# Not dry-running since we're mocking external services
# using WebMock.
ENV["JIRA_DRY_RUN"] = "false"

# Running locally, setup simplecov
require "simplecov"
SimpleCov.start do
  add_filter do |src|
    # Ignoring files from the spec directory
    src.filename =~ %r{/spec/}
  end
end

# Setup app-specific environment variables
test_environment = {
  "JIRA_DEFAULT_USERNAMES_FOR_FUNCTIONAL_REVIEW" => "func.rev1,func.rev2",
  "JIRA_ACCEPTED_USERNAMES_FOR_FUNCTIONAL_REVIEW" => "acc.func",
  "JIRA_API_URL_PREFIX" => "https://example.atlassian.net/rest/api/2",
  "JIRA_BROWSER_ISSUE_PREFIX" => "https://example.atlassian.net/browse",
  "MONGODB_URI" => ENV["MONGODB_URI"] || "mongodb://127.0.0.1:27018/job_tomate",
  "JIRA_USERNAME" => "job_tomate_username",
  "JIRA_PASSWORD" => "job_tomate_pwd",
  "SLACK_WEBHOOK_URL" => "https://hooks.slack.com/services/abcd1234",
  "TOGGL_WORKSPACE_ID" => "twid",
  "ASYNC_WEB_TRANSACTIONS_ENABLED" => "false"
}
test_environment.each { |k, v| ENV[k] = v }

require File.expand_path("../../config/boot", __FILE__)
Dir[File.expand_path("../support/**/*.rb", __FILE__)].each { |f| require(f) }

require "job_tomate/data/user"
require "job_tomate/data/toggl_entry"
require "job_tomate/data/stored_webhook"

RSpec.configure do |config|
  config.before(:each) do
    Thread.current.thread_variable_set("transaction_uuid", "tuuid")
  end
  config.after(:each) do
    JobTomate::Data::User.delete_all
    JobTomate::Data::TogglEntry.delete_all
    JobTomate::Data::StoredWebhook.delete_all
    Thread.current.thread_variable_set("transaction_uuid", nil)
  end
end
