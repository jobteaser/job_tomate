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
    def run(*args)
      LOGGER.info "#{name}.run #{args}"
      new.run(*args)
    end
  end
end
