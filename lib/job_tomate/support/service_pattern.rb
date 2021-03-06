module JobTomate

  # A module to extend classes applying the Service pattern. Provides a way
  # to share common behaviour between services (e.g. auditing,
  # helpers...).
  #
  # Usage:
  #
  #     class MyService
  #       extend ServicePattern
  #     end
  #
  module ServicePattern

    # Allows to use the command class with `run` as a class
    # method instead of initializing an instance first.
    #
    # Included features:
    #   - auditability: a log is written for each run
    #
    # Example:
    #     MyService.run(arg, another)
    #     #=> will run MyService.new.run(arg, another)
    #
    # NB: the transaction UUID is set at the thread level.
    def run(*args)
      within_log { new.run(*args) }
    end

    private

    def within_log
      start = Time.now
      log_start
      result = yield
      log_end((Time.now - start) / 1_000)
      result
    end

    def transaction_uuid
      Thread.current.thread_variable_get("transaction_uuid")
    end

    def log_start
      LOGGER.info "#{log_prefix}START"
    end

    def log_end(duration)
      LOGGER.info "#{log_prefix}END (#{duration}s)"
    end

    def log_prefix
      return "#{name}.run transaction='#{transaction_uuid}' - " unless transaction_uuid.blank?
      "#{name}.run - "
    end
  end
end
