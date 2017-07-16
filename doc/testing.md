# Testing

For tests, the following decisions have been taken:

- Only unit test commands (e.g. `Commands::JIRA::Client`, `Commands::Slack::SendMessage`, see `spec/unit/commands`).
- Workflows must be tested from end-to-end using acceptance tests. Workflows are mostly implemented in `Action`s so acceptance tests names and top-level `describe` should match the corresponding `Action`.

**Why has this approach been chosen?**

  - It gives more freedom to change the implementation of underlying components, without having a lot of intermediate tests to be updated in the meanwhile.
  - The purpose of JobTomate is essentially to perform calls to external services in response to events triggered by other external services, so performing the tests at the level the nearer to these services felt right.
  - JobTomate will not be provided without actual workflows which will be acceptance-tested. Testing these workflows also ensures the underlying components are tested. Unit-testing the components would only provide a second and extraneous layer of tests.

## Custom VCR-like testing

### Stored requests

The `JIRA::Client` will store a `Data::StoredRequest` for each request. This will ease debugging but also helps in setting up new acceptance tests. You may perform the request you want to test in your development environment and persist it to a fixture for reuse in specs. See `webmock_helpers.rb` for more details.

### Stored webhooks

When receiving a webhook, a `Data::StoredWebhook` record is created. You can store it to a fixture (using `#write_to_fixture`) and use it in tests using `receive_stored_webhook`. See `webhooks_helpers.rb` for more details.
