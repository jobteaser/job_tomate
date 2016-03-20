module JobTomate
  module Commands

    # A base class for the command pattern. Provides a way
    # to share common behaviour between commands (e.g. auditing,
    # helpers...).
    class Base

      # Allows to use the command class with `run` as a class
      # method instead of initializing an instance first:
      #
      # Example:
      #     Commands::ShowMe.run(arg, another)
      #     #=> will run Commands::ShowMe.new.run(arg, another)
      def self.run(*args)
        LOGGER.info "#{name}.run #{args}"
        new.run(*args)
      end
    end
  end
end
