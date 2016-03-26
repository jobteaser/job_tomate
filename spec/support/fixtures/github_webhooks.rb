module Fixtures

  # Fixture generator for Github webhooks.
  class GithubWebhooks
    DATA_DIR = File.expand_path("../data", __FILE__)
    FILES = {
      opened_pull_request: "webhook_github_opened_pull_request"
    }
    FILE_FORMAT = ".json"

    # Payload for webhook on opened pull request event.
    def self.opened_pull_request
      file = File.join(DATA_DIR, "#{FILES[:opened_pull_request]}#{FILE_FORMAT}")
      File.read(file)
    end
  end
end
