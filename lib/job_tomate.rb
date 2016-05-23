# Top-level module
#
# ARCHITECTURE
# ============
#
# 1. Triggers (webhooks, scheduled jobs, bot commands) trigger Events.
# 2. Events run Actions.
# 3. Actions encapsulate the business logic to perform specific
#    Commands.
# 4. The Commands define the interactions with data or external
#    services.
#
module JobTomate
  VERSION = "0.3.0"
end
