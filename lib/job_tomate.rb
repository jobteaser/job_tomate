# Top-level module
#
# ARCHITECTURE
# ============
#
# The entire JobTomate application provides several approaches
# to handle workflows and features:
#
#   1. Webhooks processing
#   2. Scheduled workflows
#   3. SlackBot commands
#
# The architecture of the application is structured around the
# 2 following components:
#
#   - `JobTomate::Commands`:
#     - commands are intended to perform a single action with
#       a single service, for example:
#         - send a message on Slack,
#         - add a commend to a JIRA issue...
#     - commands are used and combined within workflows.
#
#   - `JobTomate::Workflows`: a more complex kind of operations,
#     combining several commands with logic to implement the
#     workflows documented in the top-level README.
#
# 1. Webhooks processing
# ----------------------
# TODO
#
# 2. Scheduled workflows
# ----------------------
# TODO
#
# 3. SlackBot commands
# --------------------
# TODO
module JobTomate
  VERSION = '0.2.0'
end
