require_relative 'config/boot.rb'
require 'sinatra'
require 'job_tomate/input/github/processor'
require 'job_tomate/input/jira/processor'
require 'job_tomate/data/webhook_payload'

def status_ok
  { status: 'ok' }.to_json
end

get '/' do
  status_ok
end

# Github pull request webhook
post '/webhooks/pr' do
  json = request.body.read
  return 'no body' if json.empty?

  webhook_data = JSON.parse json
  JobTomate::Data::WebhookPayload.create(source: 'github_pr', data: webhook_data)
  JobTomate::Input::Github::Processor.run(webhook_data)

  status_ok
end

# JIRA issue change wehbook handler
post '/webhooks/jira' do
  json = request.body.read
  return 'no body' if json.empty?

  webhook_data = JSON.parse json
  JobTomate::Data::WebhookPayload.create(source: 'jira', data: webhook_data)
  JobTomate::Input::Jira::Processor.run(webhook_data)

  status_ok
end
