#
# Errors used by Heathen
#
module Heathen
  # Abstract heathen error class
  class Error < StandardError; end

  # Raised by task [Processor] method when a pre-condition (such as mime-type) is not valid.
  class ExpectationNotMet < Error
    def initialize name, value, pattern
      super "Expectation failure on #{name}, expected '#{value.to_s}' to match /#{pattern.to_s}/"
    end
  end

  # Raised by [Converter] if it is unable to find a task to satisfy the requested action.
  class TaskNotFound < Error
    def initialize action, mime_type
      super "No task found for action: '#{action}', mime_type: '#{mime_type}'"
    end
  end

  # Abstract step-wise error - the [#message] will also say in which method the error
  # occurred (So could be supplied to the client application without confusing anybody)
  class StepError < Error
    def initialize method=nil
      calling_method = caller[2]
      method = calling_method.gsub(/.*[`](.*)'$/,'\\1')
      super "#{message} in step '#{method}'"
    end
  end

  # Raised if the task step can't handle the input mime type
  class InvalidMimeTypeInStep < StepError
    def initialize expected, got
      super "Invalid mime_type (expected /#{expected}/, got '#{got}')"
    end
  end

  # Raised if the task step was unable to perform the conversion
  class ConversionFailed < StepError
    def initialize message=nil
      super( message || "Conversion failed" )
    end
  end

  # Raised if an input parameter to the task step was unrecognised or invalid
  class InvalidParameterInStep < StepError
    def initialize param_name, param_value
      super( "Invalid parameter: #{param_name}: #{param_value}" )
    end
  end

  # Raised if an job language is invalid for the step
  class InvalidLanguageInStep < StepError
    def initialize language
      super( "Invalid language: #{language}" )
    end
  end
end
