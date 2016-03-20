# Helper to retrieve fixtures for tests.
#
# Example:
#     Fixtures.webhook(:github, :push)
#
module Fixtures
  FIXTURES_DIR = File.expand_path("../fixtures", __FILE__)
  FILE_FORMAT = ".json"

  def self.webhook(dir, name)
    file = File.join(FIXTURES_DIR, "webhooks", dir.to_s, "#{name}#{FILE_FORMAT}")
    File.read(file)
  end

  def self.toggl_report(name)
    file = File.join(FIXTURES_DIR, "requests", "toggl", "#{name}#{FILE_FORMAT}")
    File.read(file)
  end
end
