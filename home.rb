require_relative 'config/boot.rb'

get '/' do
  @loginfos = JobTomate::LogInfo.all(:limit => 20)
  erb :index
end