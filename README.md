

[![Build Status](https://travis-ci.org/jobteaser/job_tomate.svg?branch=master)](https://travis-ci.org/jobteaser/job_tomate)
[![Code Climate](https://codeclimate.com/repos/5659c9ee09af1e152f00d540/badges/d4a9abf44cad651805e5/gpa.svg)](https://codeclimate.com/repos/5659c9ee09af1e152f00d540/feed)
[![Coverage Status](https://coveralls.io/repos/github/jobteaser/job_tomate/badge.svg?branch=master)](https://coveralls.io/github/jobteaser/job_tomate?branch=master)

## Purpose

Automate as many things as possible in our development workflow.

## To what is it connected?

- JIRA
- Github
- Toggl
- Slack ( and bot)

## Workflows

Trigger | Event | Action | Status
------- | ----- | ------ | ------
Scheduled task | **Toggl** new time entry | **JIRA** add worklog on matching issue | DONE
Webhook | **Github** pull request opened | **JIRA** add comment on matching issue (branch named `jt-xyz-...`) | DONE
Webhook | **Github** pull request closed | **JIRA** add comment on matching issue (indicate if merged or not) | DONE
Webhook | **JIRA** updated issue **assignee** | **JIRA** depending on the issue status, update the developer | DONE
Webhook | **JIRA** updated issue **assignee** | **JIRA** depending on the issue status, update the reviewer | DONE
Webhook | **JIRA** updated issue **assignee** | **JIRA** depending on the issue status, update the feature owner | DONE
Webhook | **JIRA** updated issue **assignee** | **Slack** notify the assignee | DONE
Webhook | **JIRA new comment** on issue | **Slack** notify the mentioned user(s) | DONE
Webhook | **JIRA** updated issue **status** | **JIRA** assign the appropriate person | DONE


## How to use

### Open a console locally

```
bin/console
```

NB: by default in non-production environments (see `RACK_ENV` environment variable), the `JIRA_DRY_RUN` is set to `"true"` to prevent JIRA API calls with effects (e.g. update, delete).

### Deploy to Heroku

```sh
# Staging
bin/set_env_staging
bin/deploy_staging

# Production
bin/set_env_production
bin/deploy_production
```

The deployed code will run a web application that will handle webhooks (see `triggers/webhooks.rb`).

Scheduled tasks must be setup for _tasks_ triggers (`triggers/tasks`). Using Heroku's Scheduler plugin, setup the following recurring task:

- `bin/run_task fetch_toggl_reports`: every 1 hour is fine

Some maintenance scripts must be scheduled too (Heroku's Scheduler plugin is fine too):

- `script/cleanup_stored_webhooks_and_requests`: every day

### Run a console on Heroku

```
heroku run bin/console -a <APP-NAME>
```

### Dump the production database

_NB: this assumes you have deployed to Heroku_

```
bin/dump_production_to_local
bin/dump_production_to_staging
```

### Add a new user

If the user started using Toggl, some `TogglEntry` records should be pending for this user. We can use them to find the user's Toggl username. We also need to process them after the user has been created.

_In an application console:_

```
# Get the Toggl username
JobTomate::Data::TogglEntry.where(status: "pending").all.map(&:toggl_user).uniq
=> ["New User"]

# The JIRA password can be reset manually for a given user by a JIRA admin
JobTomate::Data::User.create toggl_user: 'Toggl User', github_user: 'Github User', jira_username: 'JIRA username', jira_password: 'JIRA password', jira_developer: true, jira_reviewer: true, jira_feature_owner: false, jira_functional_reviewer: false, slack_username: 'Slack User'
```

**Reprocess older Toggl reports for a given user**

All unprocessed Toggl reports are stored as `Data::TogglEntry` records with the status `"pending"`. Use the following task to process them:

```
bin/run_task process_pending_entries
```

## Setup

### Required environment variables

See `.env.example` file.

### JIRA Webhook

You must setup a webhook on JIRA to trigger JIRA-related workflows. You can find this in Administration > System > Webhooks.

Here is the configuration to use:

- URL: `https://<your-domain>/webhooks/jira`
- Select "updated" issue events, on all issues (no filter)

### Github Webhook

For each repository that needs to be connected to JobTomate, setup the webhook like this:

- URL: `https://<your-domain>/webhooks/github`
- Content type: select "application/json"
- Select "Send me everything"

### Slack Webhook

Setup a webhook integration on Slack. Any default will do since they are all overriden by JobTomate. The webhook URL must be defined in the environment variables (`SLACK_WEBHOOK_URL`).

## Contributing

Check the issues.

### Overall architecture

#### Workflows

JobTomate is built on a set of components that interact together to perform workflows:

- **Triggers** (webhooks, tasks) generate **events** (e.g. `Github::PullRequestOpened`, `JIRA::IssueCommentAdded`)
- **Events** trigger **actions** (e.g. `JIRAAddCommentOnGithubPullRequest`, `SlackNotifyJIRAIssueAssignee`)
- **Actions** perform effects through **commands** (e.g. `JIRA::AddComment`, `Slack::SendMessage`)

#### Data

Some workflows may rely on local data (e.g. Toggl reports are cached in `TogglEntry` records to allow more complex processing, such as detecting changes). We also need users to store credentials to perform actions on some services (e.g. JIRA) or which username to mention in messages (e.g. in Slack). This is the purpose of `Data` objects.

#### Values

We use `Values` objects (e.g. `Github::PullRequest`, `JIRA::Changelog`) to pass data in a structured way between the triggers, actions and commands. Even if this is not enforced, value objects are intended to be immutable to limit bugs and provide helpers on raw data (e.g. `Value::JIRA#link`).


### Architecture decisions

#### Using acceptance tests only

Except some specific cases for which unit tests may be helpful (`Commands::JIRA::Client` and `Commands::Slack::SendMessage`), only acceptance tests are used.

Why has this approach been chosen?
  - It gives more freedom to change the implementation of underlying components, without having a lot of intermediate tests to be updated in the meanwhile.
  - The purpose of JobTomate is essentially to perform calls to external services in response to events triggered by other external services, so performing the tests at the level the nearer to these services felt right.
  - JobTomate will not be provided without actual workflows which will be acceptance-tested. Testing these workflows also ensures the underlying components are tested. Unit-testing the components would only provide a second and extraneous layer of tests.

#### Custom VCR-like testing

##### Stored requests

The `JIRA::Client` will store a `Data::StoredRequest` for each request. This will ease debugging but also helps in setting up new acceptance tests. You may perform the request you want to test in your development environment and persist it to a fixture for reuse in specs. See `webmock_helpers.rb` for more details.

##### Stored webhooks

When receiving a webhook, a `Data::StoredWebhook` record is created. You can store it to a fixture (using `#write_to_fixture`) and use it in tests using `receive_stored_webhook`. See `webhooks_helpers.rb` for more details.
