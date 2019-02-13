# frozen_string_literal: true

source "https://rubygems.org"

ruby "2.5.3"

gem "httparty"
gem "mongoid"
gem "puma"
gem "sinatra"
gem "sinatra-contrib"

# For the console
gem "awesome_print"
gem "pry"
gem "ruby-progressbar"

# Integrations

# Google API
gem "google-api-client"

# Slack bot
gem "faye-websocket"
gem "slack-ruby-bot"

group :development do
  gem "guard"
  gem "guard-rspec", require: false
  gem "guard-shotgun"
  gem "rubocop"
  gem "terminal-notifier-guard"
end

group :development, :test do
  gem "dotenv"
  gem "rake"
end

group :test do
  gem "codeclimate-test-reporter", "~> 1.0.0"
  gem "rack-test"
  gem "rspec"
  gem "simplecov", require: false
  gem "timecop"
  gem "webmock"
end
