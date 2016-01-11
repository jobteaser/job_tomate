#!/usr/bin/env ruby
require_relative '../config/boot'

require 'job_tomate/workflows/toggl/process_reports'
JobTomate::Workflows::Toggl::ProcessReports.run
