require "mongoid"

env = ENV["RACK_ENV"]
fail "RACK_ENV environment variable must be set" if env.nil?

Mongo::Logger.logger.level = ::Logger::INFO
ENV["MONGOID_ENV"] = env
Mongoid.load! File.expand_path("../mongoid.yml", __FILE__)
