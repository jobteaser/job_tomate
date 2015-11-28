source 'https://rubygems.org'

ruby '2.2.3'

gem 'mongoid'
gem 'httparty'
gem 'sinatra'
gem 'puma'

# For the console
gem 'pry'
gem 'awesome_print'

group :development do
  gem 'guard'
  gem 'guard-rspec', require: false
  gem 'guard-shotgun'
  gem 'terminal-notifier-guard'
end

group :development, :test do
  gem 'rake'
  gem 'dotenv'
end

group :test do
  gem 'rack-test'
  gem 'rspec'
  gem 'webmock'
end
