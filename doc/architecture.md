# Architecture

JobTomate is built on a set of components that interact together to perform workflows:

- **Triggers** generate **events** (e.g. `Github::PullRequestOpened`, `JIRA::IssueCommentAdded`). The currently available events are webhooks and tasks (scheduled).
- **Events** trigger **actions** (e.g. `JIRAAddCommentOnGithubPullRequest`, `SlackNotifyJIRAIssueAssignee`)
- **Actions** perform effects through **commands** (e.g. `JIRA::AddComment`, `Slack::SendMessage`). This is the part where the workflow's logic is handled.

## -> Trigger objects

That's the starting point of any workflow: the event that needs action, e.g. a new JIRA status, a new gibhub comment, a toggle entry recorded etc. It is closer to a listener, because a lot of these are represented by webhooks. 

_NB: many triggers exist already, so before creating a new one, please check the existing ones, chances are you'll find yours there._

Once a trigger is actioned, it determines which overall scenario will be executed, like if a pull request is opened, it's not the same sequence of actions as when it's closed.

## -> Event objects

These are the above-mentioned overall scenarios that regroup smaller Actions (see below). Example: an opened pull-request (`Event`) needs a specific comment published on Jira, an issue's status change, a bunch of potential slack notifications and a re-assignment of an issue (`Actions`).

Events, too, mostly exist, so it's very much recommended to browse through them before creating new ones.

## -> Action objects

Smaller, more punctual scenarios that orchestrate the lowest level interactions with external services. For instance, when we need to send a slack notification about a missing bug cause (`Action`), we first need to find out who will receive it, what the text is going to be, customize the look and feel of the future message and call the generic service that will actually send the payload to Slack servers (`Command`).

This is the group most subject to modifications.
NB: by convention, we are calling `Actions` without any conditions. It is inside of them that we determine if certain `Commands` need to be executed.

## -> Command objects

The most atomic single responsibility services that can do just one generic thing. They are the interface that communicates with all external services we use: it can be posting a Jira comment or slacking a new notification. All customisation is achieved via parameters, and unless we're introducing a completely new type of behavior (maybe sending sms or a push mobile notifications), there's no need to modify `Commands`.

## Data structure

Within JobTomate there're two types of data: the objects that persist in the DB (they are located at `lib/data` folder) and value objects that are only used during the execution of one particular scenario (`lib/values` folder).

### Persisted data

Some workflows may rely on local data (e.g. Toggl reports are cached in `TogglEntry` records to allow more complex processing, such as detecting changes). We also need users to store credentials to perform actions on some services (e.g. JIRA) or which username to mention in messages (e.g. in Slack).

### Value objects

We use `Values` objects (e.g. `Github::PullRequest`, `JIRA::Changelog`) to pass data in a structured way between the triggers, actions and commands. Even if this is not enforced, value objects are intended to be immutable to limit bugs and provide helpers on raw data (e.g. `Value::JIRA#link`).

Generally this kind of data comes from external services and contains the present state of data (a Jira issue or a Github pull request or a Toggl report) at the external service. We aren't supposed to modify it, it only should be used for internal workflow. 

If you realize that external information needs to be modified, it is a valid reason to create a new action.

For example, a change of JIRA issue status requires several Slack notifications AND at the same time it triggers an external re-assignment of the issue. 

So, each Slack notification is a separate action sourced by the `Issue` value object, the change of assignee is another action that, in its turn, triggers a new webhook with the updated assignee. This change might (or might now) trigger another slack notification, but there's absolutely no need to compact all of these notifications into one service. They are completely independent.
