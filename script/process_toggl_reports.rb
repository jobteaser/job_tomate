require_relative '../config/boot'

require 'job_tomate/toggl_processor'
JobTomate::TogglProcessor.run
