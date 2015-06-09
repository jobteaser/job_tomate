require_relative 'config/boot.rb'
require 'sinatra'
require 'pry'

get '/' do
  "Hello world"
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
    status_changed = j['changelog']['items'].find{|item| item['field'] == 'status'}
    JobTomate::JiraProcessor.run(j) if status_changed
  else
    return "no body"
  end
end