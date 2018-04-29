# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path(".")
require "config/boot"
require "data/user"

# Script for data migration for version 0.3.0
#
# Migration process:
#
#     ruby db/migrate/20180428_2_v0.3.0_rename_user_feature_owner_to_product_manager.rb

module JobTomate
  module Data

    # We reopen the `User` class to add the removed `jira_feature_owner`
    # field to perform the migration.
    class User
      field :jira_feature_owner, type: Boolean
    end
  end
end

JobTomate::Data::User.each do |u|
  u.product_manager = u.jira_feature_owner
  u.save!
end
