#!/usr/bin/env ruby

# Cleanup:
#   - requests older than 1 day,
#   - webhooks older than 1 week.

require_relative "../config/boot"
require "job_tomate/data/stored_request"
require "job_tomate/data/stored_webhook"

JobTomate::Data::StoredRequest.where(created_at: { :$lt => 1.day.ago }).destroy_all
JobTomate::Data::StoredWebhook.where(created_at: { :$lt => 1.week.ago }).destroy_all
