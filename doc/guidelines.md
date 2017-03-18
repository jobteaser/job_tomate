# Code guidelines

## Overview of the architecture

JobTomate is built on a set of components that interact together to perform workflows:

- **Triggers** generate **events** (e.g. `Github::PullRequestOpened`, `JIRA::IssueCommentAdded`). The currently available events are webhooks and tasks (scheduled).
- **Events** trigger **actions** (e.g. `JIRAAddCommentOnGithubPullRequest`, `SlackNotifyJIRAIssueAssignee`)
- **Actions** perform effects through **commands** (e.g. `JIRA::AddComment`, `Slack::SendMessage`). This is the part where the workflow's logic is handled.

## Patterns

### Data

Some workflows may rely on local data (e.g. Toggl reports are cached in `TogglEntry` records to allow more complex processing, such as detecting changes). We also need users to store credentials to perform actions on some services (e.g. JIRA) or which username to mention in messages (e.g. in Slack). This is the purpose of `Data` objects.

### Values

We use `Values` objects (e.g. `Github::PullRequest`, `JIRA::Changelog`) to pass data in a structured way between the triggers, actions and commands. Even if this is not enforced, value objects are intended to be immutable to limit bugs and provide helpers on raw data (e.g. `Value::JIRA#link`).

## Tests

### Architecture decisions

For tests, the following decisions have been taken:

- Only unit test commands (e.g. `Commands::JIRA::Client`, `Commands::Slack::SendMessage`, see `spec/unit/commands`).
- Workflows must be tested from end-to-end using acceptance tests.

Why has this approach been chosen?
  - It gives more freedom to change the implementation of underlying components, without having a lot of intermediate tests to be updated in the meanwhile.
  - The purpose of JobTomate is essentially to perform calls to external services in response to events triggered by other external services, so performing the tests at the level the nearer to these services felt right.
  - JobTomate will not be provided without actual workflows which will be acceptance-tested. Testing these workflows also ensures the underlying components are tested. Unit-testing the components would only provide a second and extraneous layer of tests.

### Custom VCR-like testing

#### Stored requests

The `JIRA::Client` will store a `Data::StoredRequest` for each request. This will ease debugging but also helps in setting up new acceptance tests. You may perform the request you want to test in your development environment and persist it to a fixture for reuse in specs. See `webmock_helpers.rb` for more details.

#### Stored webhooks

When receiving a webhook, a `Data::StoredWebhook` record is created. You can store it to a fixture (using `#write_to_fixture`) and use it in tests using `receive_stored_webhook`. See `webhooks_helpers.rb` for more details.
