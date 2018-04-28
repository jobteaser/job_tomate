# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path(".")
require "config/boot"

# Script for data migration for version 0.3.0
#
# Migration process:
#
#     ruby db/migrate/20180428_v0.3.0_remove_toggl.rb

# We recreate the removed TogglEntry class so we can delete
# the documents through the migration.
module JobTomate
  module Data

    # Removed persisted data class
    class TogglEntry
      include Mongoid::Document
      store_in collection: "toggl_entries"
    end
  end
end

JobTomate::Data::TogglEntry.delete_all
