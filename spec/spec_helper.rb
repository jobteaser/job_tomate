require 'rspec'
require 'pry'
require File.expand_path('../../config/boot', __FILE__)
RSpec.configure do |config|
  config.after(:each) do
    JobTomate::TogglEntry.delete_all
  end
end