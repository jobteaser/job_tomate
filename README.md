# JobTomate

[![Build Status](https://travis-ci.org/jobteaser/job_tomate.svg?branch=master)](https://travis-ci.org/jobteaser/job_tomate)
[![Code Climate](https://codeclimate.com/repos/5659c9ee09af1e152f00d540/badges/d4a9abf44cad651805e5/gpa.svg)](https://codeclimate.com/repos/5659c9ee09af1e152f00d540/feed)
[![Test Coverage](https://codeclimate.com/repos/5659c9ee09af1e152f00d540/badges/d4a9abf44cad651805e5/coverage.svg)](https://codeclimate.com/repos/5659c9ee09af1e152f00d540/coverage)

## Overview

**JobTomate is a Ruby application used by JobTeaser's Tech Team to automate some parts of its workflows.**

It's currently connected to the following external applications:

- Github (webhook _trigger_)
- Jira (webhook _trigger_ and API _commands_)
- Slack (webhook _trigger_ and API _commands_)
- Google Sheets API (synchronization script)

### Disclaimer

We chose to keep this repository public for a few reasons:

- The concept of such an application to automate some parts of the process and the boilerplate this project provides may be useful to other teams.
- Some parts of the code may be reused in other projects.
- This may interest developers, hopefully possible hires, that want to look into our team's internal processes and tooling. (If that matches you, have a look to our [open positions](https://www.jobteaser.com/en/companies/jobteaser/job-offers).)

**Consequently, this project has not been designed to be reusable by external persons. Deploying is not 1-click away and some parts of the documentation may be oriented towards members of the JobTeaser Tech Team.**

## How to use

Once deployed, if it's correctly configured, there is nothing to "use" really. JobTomate will simply perform the workflows it is supposed to!

### How to update configuration (e.g. users)

JobTomate use its Mongo database to store some of its configuration (for example tokens, users...). To update this configuration you can:

1. Connect to a Ruby console and add the appropriate model records manually
2. Use the `script/sync_config_from_google_sheets.rb` script which provides synchronization with a Google Sheets document (see [Deployment and configuration > Google Sheets API](#configuration-google-sheets-api)). 

_**To JobTeaser Tech Team:** the Google Sheets synchronization has been setup, find more information about this on [this Confluence page](https://jobteaser.atlassian.net/wiki/spaces/DT/pages/90308824/JobTomate)._

### How to check the logs

Accessing the logs will depend on your deployment.

_**To JobTeaser Tech Team:** more information about this on [this Confluence page](https://jobteaser.atlassian.net/wiki/spaces/DT/pages/90308824/JobTomate)._

## How to contribute

**NB: only contribution from JobTeaser Tech Team will be accepted on this repository. You may fork it if you want to do your own modifications. However, please feel free to notify us of interesting updates that we may merge into our fork.**

_**To JobTeaser Tech Team:** more information on [this Confluence page](https://jobteaser.atlassian.net/wiki/spaces/DT/pages/90308824/JobTomate)._

### How to understand the architecture

- Read the documentation:
  - [architecture](https://github.com/jobteaser/job_tomate/tree/master/doc/architecture.md)
  - [howtos](https://github.com/jobteaser/job_tomate/tree/master/doc/howtos.md)
  - [testing](https://github.com/jobteaser/job_tomate/tree/master/doc/testing.md),
  - [development tips](https://github.com/jobteaser/job_tomate/tree/master/doc/development_tips.md).
- Ask help to the [past contributors](https://github.com/jobteaser/job_tomate/graphs/contributors)

### How to setup my local environment for development

After cloning the repository...

#### Install Ruby, Bundler and the gems

We assume you know how to do this. Or you know how to Google it. Or how to ask someone near.

### Run dependencies (MongoDB)

_NB: you need Docker installed and running for this_

```
docker-compose up -d mongo-dev mongo-test
```

#### Set environment variables

Copy `.env.example` to `.env` and make the necessary changes.

```
JIRA_API_URL_PREFIX=https://<REPLACE-ME>.atlassian.net/rest/api/2
JIRA_BROWSER_ISSUE_PREFIX=https://<REPLACE-ME>.atlassian.net/browse
```

Replace `<REPLACE-ME` with the prefix of your Atlassian domain.

```
JIRA_USERNAME=<REPLACE-ME>
JIRA_PASSWORD=<REPLACE-ME>
```

You need to have an user authorized to perform API calls on Jira. You can use your own personal credentials, as long as you keep them secret and stored on your workstation. **DO NOT USE THEM TO CONFIGURE A PRODUCTION APPLICATION.**

```
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/REPLACE-ME
SLACK_API_TOKEN=<REPLACE-ME>
```

Check your Slack instance details to feed this information.

```
GOOGLE_AUTH_ID=<REPLACE-ME>
GOOGLE_AUTH_SECRET=<REPLACE-ME>
GOOGLE_SHEETS_CONFIGURATION_ID=<REPLACE-ME>
```

These are only needed if you want to run the application's configuration synchronization with Google Sheets script (`script/sync_config_from_google_sheets.rb`). If you don't need this, leave it unchanged. Otherwise, check the [Google Sheets API](#Google Sheets API) section below.

**To JobTeaser Tech Team members:** you can find more information to help you with the setup [in this Confluence page](https://jobteaser.atlassian.net/wiki/spaces/DT/pages/90308824/JobTomate).

#### Open a Ruby console locally

```
bin/console
```

NB: by default in non-production environments (see `RACK_ENV` environment variable), the `JIRA_DRY_RUN` is set to `"true"` to prevent JIRA API calls with effects (e.g. update, delete).

#### Open a Mongo console locally

```
docker-compose run mongo-client
```

### Useful with an Heroku deployment

Some scripts are available in the project if you deployed to Heroku, easing some tasks like deploying or copying the staging or production databases to your local environment.

#### Dump the production database

**NB**: you must have the `mongo` command-line client tool installed on your local machine

```
bin/dump_production_to_local
bin/dump_production_to_staging
```

#### Update environment variables

```sh
bin/set_env_staging
bin/set_env_production
```

#### Deploy a new release

```sh
bin/deploy_staging
bin/deploy_production
```

#### Run a console on Heroku

```
heroku run bin/console -a <APP-NAME>
```

#### Run a migration on Heroku

```
heroku run ruby db/migrate/... -a <APP-NAME>
```

### Deployment

The deployed code will run a web application that will handle webhooks (see `triggers/webhooks.rb`).

Scheduled tasks must be setup for _tasks_ triggers (`triggers/tasks`). If you deploy on Heroku, you can use Heroku's Scheduler plugin.

*No task to be setup. If needed, you should add the following command: `bin/run_task fetch_toggl_reports`*

Some maintenance scripts must be scheduled too:

- `script/cleanup_stored_webhooks_and_requests`: every day

### Configuration

#### Jira Webhook

You must setup a webhook on JIRA to trigger JIRA-related workflows. You can find this in Administration > System > Webhooks.

Here is the configuration to use:

- URL: `https://<your-domain>/webhooks/jira`
- Select "updated" issue events, on all issues (no filter)

#### Github Webhook

For each repository that needs to be connected to JobTomate, setup the webhook like this:

- URL: `https://<your-domain>/webhooks/github`
- Content type: select "application/json"
- Select "Send me everything"

#### Slack Webhook

Setup a webhook integration on Slack. Any default will do since they are all overriden by JobTomate. The webhook URL must be defined in the environment variables (`SLACK_WEBHOOK_URL`).

#### <a name="configuration-google-sheets-api"></a>Google Sheets API

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
