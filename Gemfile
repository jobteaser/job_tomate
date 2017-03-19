source "https://rubygems.org"

ruby "2.3.3"

gem "mongoid"
gem "httparty"
gem "sinatra"
gem "sinatra-contrib"
gem "puma"

# For the console
gem "pry"
gem "awesome_print"
gem "ruby-progressbar"

# Slack bot
gem "slack-ruby-bot"

group :development do
  gem "guard"
  gem "guard-rspec", require: false
  gem "guard-shotgun"
  gem "terminal-notifier-guard"
end

group :development, :test do
  gem "rake"
  gem "dotenv"
end

group :test do
  gem "rack-test"
  gem "rspec"
  gem "webmock"
  gem "simplecov", require: false
  gem "timecop"
  gem "codeclimate-test-reporter", "~> 1.0.0"
end
