#!/usr/bin/env ruby
# Cleanup webhook payloads older than 1 week
require_relative "../config/boot"
require "job_tomate/data/webhook_payload"

JobTomate::Data::WebhookPayload.where(created_at: { :$gt => 1.week.ago }).destroy_all
