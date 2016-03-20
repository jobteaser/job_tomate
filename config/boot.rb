# Load dependencies
require "rubygems"
require "bundler"

env = (ENV["APP_ENV"] ||= "development")
Bundler.setup(:default, env.to_sym)

ENV["DRY_RUN"] = "true" if env != "production"
if env == "development"
  require "dotenv"
  Dotenv.load
end

root_dir = File.expand_path "../..", __FILE__

$LOAD_PATH.unshift root_dir
$LOAD_PATH.unshift File.join(root_dir, "lib")
$LOAD_PATH.unshift File.join(root_dir, "lib", "job_tomate")
require "config/mongo"

require "job_tomate"
JobTomate::LOGGER = env == "test" ? Logger.new("/dev/null") : Logger.new(STDOUT)
