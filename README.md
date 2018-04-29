# JobTomate

[![Build Status](https://travis-ci.org/jobteaser/job_tomate.svg?branch=master)](https://travis-ci.org/jobteaser/job_tomate)
[![Code Climate](https://codeclimate.com/repos/5659c9ee09af1e152f00d540/badges/d4a9abf44cad651805e5/gpa.svg)](https://codeclimate.com/repos/5659c9ee09af1e152f00d540/feed)
[![Test Coverage](https://codeclimate.com/repos/5659c9ee09af1e152f00d540/badges/d4a9abf44cad651805e5/coverage.svg)](https://codeclimate.com/repos/5659c9ee09af1e152f00d540/coverage)

## Purpose

Automate as many things as possible in our development workflow.

## To what is it connected?

- JIRA
- Github
- Slack (and bot)

## Workflows

Trigger | Event | Action | Status
------- | ----- | ------ | ------
Webhook | **Github** pull request opened | **JIRA** add comment on matching issue (branch named `jt-xyz-...`) | DONE
Webhook | **Github** pull request closed | **JIRA** add comment on matching issue (indicate if merged or not) | DONE
Webhook | **Github** status updated | The author of the update (e.g. Codeclimate analyze, CircleCI build) is notified on Slack | DONE
Webhook | **JIRA** updated issue **assignee** | **JIRA** depending on the issue status, update the developer | DONE
Webhook | **JIRA** updated issue **assignee** | **JIRA** depending on the issue status, update the reviewer | DONE
Webhook | **JIRA** updated issue **assignee** | **JIRA** depending on the issue status, update the feature owner | DONE
Webhook | **JIRA** updated issue **assignee** | **Slack** notify the assignee | DONE
Webhook | **JIRA new comment** on issue | **Slack** notify the mentioned user(s) | DONE

## How to use

### Start dependencies (MongoDB)

```
docker-compose up -d mongo-dev mongo-test
```

### Open a Ruby console locally

```
bin/console
```

NB: by default in non-production environments (see `RACK_ENV` environment variable), the `JIRA_DRY_RUN` is set to `"true"` to prevent JIRA API calls with effects (e.g. update, delete).

### Open a Mongo console locally

```
docker-compose run mongo-client
```

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

### Run a migration on Heroku

```
heroku run ruby db/migrate/... -a <APP-NAME>
```

### Dump the production database

**NB**

- This assumes you have deployed to Heroku
- You must have the `mongo` command-line client tool installed on your local machine

```
bin/dump_production_to_local
bin/dump_production_to_staging
```

### Add a new user

_In an application console:_

```
JobTomate::Data::User.create github_user: 'Github User', jira_username: 'JIRA username', developer_backend: true, developer_frontend: false, jira_reviewer: true, product_manager: false, jira_functional_reviewer: false, slack_username: 'Slack User'
```

## Setup

### Required environment variables

See `.env.example` file.

### Jira Webhook

You must setup a webhook on JIRA to trigger JIRA-related workflows. You can find this in Administration > System > Webhooks.

Here is the configuration to use:

- URL: `https://<your-domain>/webhooks/jira`
- Select "updated" issue events, on all issues (no filter)

### Github Webhook

For each repository that needs to be connected to JobTomate, setup the webhook like this:

- URL: `https://<your-domain>/webhooks/github`
- Content type: select "application/json"
- Select "Send me everything"

#### Slack Webhook

Setup a webhook integration on Slack. Any default will do since they are all overriden by JobTomate. The webhook URL must be defined in the environment variables (`SLACK_WEBHOOK_URL`).

#### Google Sheets API

The `script/sync_config_from_google_sheets.rb` script may be used to synchronize the application's configuration stored in the Mongo database using a Google Sheets document. This makes updating the configuration easier for non-developers and for sharing the permission to update the configuration without having to give production access permission.

To enable this integration, you need to perform the following.

#### Setup a Google Developers Console Project

You can follow the instructions available on [Google Sheets API Ruby Quickstart](https://developers.google.com/sheets/api/quickstart/ruby).

Write your Client ID and Client Secret somewhere secure.

#### Create the configuration Google Sheets document

The document must follow this structure:

- A page named after a model, e.g. `User` for `JobTomate::Data::User`.
- One column per model field, e.g. `github_user`.
- A single row at the top with the field's name.

Share the document with the appropriate users. You will need a "technical" user with limited permissions to be able to access this file for deployment. You should use this user to retrieve API tokens for your production instance.

#### Retrieve tokens

The first time you'll use the script, it will ask you to perform an OAuth authentication to retrieve API tokens.

**NB: SECURITY WARNING**

While you can perform the OAuth authentication using your personal _jobteaser.com_ Google account for development purposes, you **MUST NOT** use it to deploy the application.

This token could indeed be used to access all your Google Sheets documents. It should remain secured on your workstation. 


#### Update `.env`

```
GOOGLE_AUTH_ID=
GOOGLE_AUTH_SECRET=
GOOGLE_SHEETS_CONFIGURATION_ID=
```

1. Insert the retrieved client ID and client secret. 
2. Insert the document's ID (the string after `spreadsheets/d/` in the URL).
