require_relative 'config/boot.rb'
require 'sinatra'
require 'pry'

get '/' do
  "Hello world"
end

post '/webhooks/pushs' do
  return 'ok'
end

post '/webhooks/pr' do
  data = request.body.read
  if !data.empty?
    j = JSON.parse data
    JobTomate::GithubProcessor.run(j)
  else
    return "no body"
  end
end

post '/webhooks/status' do
  data = request.body.read
  if !data.empty?
    j = JSON.parse data
    new_status = j['changelog']['items'].first['toString']
    reviewer = j['issue']['fields']['customfield_10601']['key']
    assignee = j['issue']['fields']['assignee']['key']
    developer = j['issue']['fields']['customfield_10600']['key']
    logger.info "ticket changed to #{new_status}, assignee is #{assignee}, reviewer is #{reviewer}, developer is #{developer}"
  else
    return "no body"
  end
end