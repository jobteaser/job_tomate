module JobTomate

  # Workflows are defined by classes within the JobTomate::Workflows
  # module.
  #
  module Workflows

    # Workflow superclass.
    #
    # Subclasses must define the .run method. Arguments must
    # be Strings since a workflow may be started from the
    # command line using `bin/run_workflow...`.
    class BaseWorkflow

      def self.run(*args)
        fail "BaseWorkflow subclasses must implement .run"
      end
    end
  end
end
