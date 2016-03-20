# Top-level module
#
# ARCHITECTURE
# ============
#
# 1. Triggers (webhooks, scheduled jobs, bot commands) trigger `Event`s.
# 2. `Event`s run Action`s
# 3. An `Action` is built using `Commands` which define the possible
#   outgoing interactions with external services.
# The entire JobTomate application provides several approaches
# to handle workflows and features:
#
module JobTomate
  VERSION = "0.2.0"
end
