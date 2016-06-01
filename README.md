

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

reports = JobTomate::Commands::Toggl::FetchReports.run(Date.yesterday, Date.today).map{|e| e['user']}.uniq

# The JIRA password can be reset manually for a given user by a JIRA admin
JobTomate::Data::User.create toggl_user: 'Toggl User', github_user: 'Github User', jira_username: 'JIRA username', jira_password: 'JIRA password'
```

**Reprocess older Toggl reports for a given user**

**TO BE UPDATED**

```
require 'job_tomate/commands/toggl/fetch_reports'
require 'job_tomate/commands/toggl/process_reports'
reports = JobTomate::Commands::Toggl::FetchReports.run(3.days.ago, Date.today).select {|r| r['user'] == 'some-user' }
reports.map { |r| JobTomate::Commands::Toggl::ProcessReports.process_toggl_report(r) }
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

### How to improve an existing workflow

Say we want to add the branch name in the JIRA comment added when creating a new pull request ([issue #21](https://github.com/jobteaser/job_tomate/issues/21)).

#### 1. Create the feature branch

Since we're on issue #21, create a branch prefixed with `issue#21-`, for example `issue#21-pull-request-jira-branch-name`. Be sure to branch from a fresh `master`.

#### 2. Find and update the corresponding test(s)

- Tests are grouped around the _source_ trigger. Since our trigger is a Github pull request, we'll look into `spec/acceptance/github`. We find a matching spec: `pull_request_opened_spec`.
- By reading the test file, we find the test we need to update: `opened pull request related to JIRA issue adds a comment on the JIRA with the PR link`.
- We update the test to add the new expectation. We'll have a look at the used fixture. We can identify it through this call: `receive_stored_webhook(:github_pull_request_opened_jira_related)`.
- So the corresponding fixture file is: `spec/support/fixtures/stored_webhooks/github_pull_request_opened_jira_related.yml`.
- From the fixture, we can find that the branch for the pull request is `jt-1234-create-crawler`. So we change the expected comment by adding ` - branch: jt-1234-create-crawler`.

#### 3. Find and update the corresponding implementation

Now that the test has been updated, the build is red and we need to fix the implementation. Let's find where:

- The workflow is related to a Github trigger, which is webhook. The starting point is `Triggers::Webhooks::Github`. Our workflow already exists, so we should not have to change it.
- This event is triggered for a new pull request, so we can find it easily: `Events::Github::PullRequestOpened`.
- By looking at the `PullRequestOpened` event, we can see the action corresponding to this workflow is `Actions::JIRAAddCommentOnGithubPullRequestOpened`. Our change will be there.
- This action is simply a call to `Commands::JIRA::AddComment` with appropriate parameters. Just updating the parameters will do the trick. We just add ` - branch: #{pull_request.branch}`.
- Did this work? Not yet, because the `#branch` method was not defined on `Values::PullRequest`. Since the `data` attribute of the `Values::PullRequest` is simply the content of the `pull_request` attribute of the Github webhook's payload, it's easy to add the method.
- You're done!
- NB: In fact, we used `Values::PullRequest#head_ref` which already exists and returns the expected value, instead of creating a new alias method.

Check the corresponding [pull request](https://github.com/jobteaser/job_tomate/pull/34) for the code!

#### 4. Push and create pull request

Push your branch and go to Github to create the matching pull request. Link the fixed issue in the pull request's description, and wait for your tests to be green.


### How to create a new workflow

We want to add a workflow notifying a pull request's submitter that the status of a pull request has been updated by an external service ([issue 26](https://github.com/jobteaser/job_tomate/issues/26)). The Github webhook trigger with the `"status"` Github event will help us with this workflow.

#### 1. Find a stored webhook and build a fixture for the test

- We start by retrieving the production database locally with `bin/dump_production_to_local`.
- This enables us to investigate the stored webhooks and try to find one matching our case.
- In the application's console (`bin/console`), we find the stored webhook and store it as a fixture:

```
# Retrieve a matching webhook
webhook = JobTomate::Data::StoredWebhook.order(:created_at.asc).select do |w|
  w.headers["HTTP_X_GITHUB_EVENT"] == "status"
end.last

# Make a fixture from it
webhook.write_to_fixture(:github_status_update)
```

**NB: you must anonymize the content of the fixture before committing it!**

#### 2. Create a new acceptance test

Now that we have the appropriate fixture, we'll write the corresponding test. Since the workflow is triggered by the `status` Github event, we'll add a `spec/acceptance/github/status_spec.rb` file.

To execute the fixture webhook in the spec, we can use `receive_stored_webhook(:github_status)`. In our test, we'll be expecting a request to Slack. To help mocking it, we can use one of the `WebmockHelpers` module methods. The `stub_slack_send_message_as_job_tomate(text, channel)` seems really pertinent. The rest? Well, it's simple Ruby-testing as usual!

#### 3. Write the implementation

When your test has been written, your build should be red. Time to write the implementation!

__TO BE COMPLETED__


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

#### Stored webhooks

When receiving a webhook, a `Data::StoredWebhook` record is created. You can store it to a fixture (using `#write_to_fixture`) and use it in tests using `receive_stored_webhook`. See `webhooks_helpers.rb` for more details.
