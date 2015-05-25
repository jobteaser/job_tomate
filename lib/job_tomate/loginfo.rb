require 'mongoid'
require 'config/mongo'

module JobTomate
  class LogInfo
    include Mongoid::Document
    include Mongoid::Timestamps

    store_in collection: 'loginfos'

    field :action,          type: String
    field :timestamp,       type: String
    field :status,          type: String
  end
end
