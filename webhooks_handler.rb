require_relative 'config/boot.rb'
require 'sinatra'
require 'job_tomate/github_processor'
require 'job_tomate/input/jira/processor'

get '/' do
  { status: 'ok' }.to_json
end

# Github pull request webhook
post '/webhooks/pr' do
  json = request.body.read
  return 'no body' if json.empty?

  webhook_data = JSON.parse json
  JobTomate::GithubProcessor.run(webhook_data)
end

# JIRA issue change wehbook handler
post '/webhooks/jira' do
  json = request.body.read
  return 'no body' if json.empty?

  webhook_data = JSON.parse json
  JobTomate::Input::Jira::Processor.run(webhook_data)
end
