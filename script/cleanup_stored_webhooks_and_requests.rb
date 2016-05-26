#!/usr/bin/env ruby

# Cleanup webhook payloads older than 1 week
require_relative "../config/boot"
require "job_tomate/data/stored_webhook"

JobTomate::Data::StoredWebhook.where(created_at: { :$gt => 1.week.ago }).destroy_all
JobTomate::Data::StoredRequest.where(created_at: { :$gt => 1.day.ago }).destroy_all
