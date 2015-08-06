require 'rspec'
require 'pry'
require File.expand_path('../../config/boot', __FILE__)

require 'job_tomate/toggl_entry'
RSpec.configure do |config|
  config.after(:each) do
    JobTomate::TogglEntry.delete_all
  end
end
