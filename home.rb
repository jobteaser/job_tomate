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
  binding.pry
  data = request.body.read
  if !data.empty?
    j = JSON.parse data
    JobTomate::JiraProcessor.run(j)
  else
    return "no body"
  end
end