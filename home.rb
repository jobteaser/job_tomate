require 'sinatra'

get '/' do
  @loginfos = LogInfo.all(:limit => 20)
  erb :index
end