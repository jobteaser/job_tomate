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

  data = JSON.parse json
  JobTomate::GithubProcessor.run(data)
end

# JIRA issue change wehbook handler
post '/webhooks/jira' do
  json = request.body.read
  return 'no body' if json.empty?

  data = JSON.parse json
  issue_key = data['issue']['key']

  changelog = data['changelog']
  if changelog.blank? || (items = changelog['items']).empty?
    logger.warn "No changelog or changelog items for issue #{issue_key}"
    return
  end

  status_change = items.find{ |item| item['field'] == 'status' }
  if status_change.nil?
    logger.warn "No status change for issue #{issue_key}"
    return
  end

  JobTomate::Input::Jira::Processor.run(data) if status_change
end
