module Fixtures

  # Fixture generator for Github webhooks.
  class GithubWebhooks
    DATA_DIR = File.expand_path("../data/github_webhooks", __FILE__)
    FILE_FORMAT = ".json"

    def self.get(name)
      file = File.join(DATA_DIR, "#{name}#{FILE_FORMAT}")
      File.read(file)
    end
  end
end
