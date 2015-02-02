module Heathen
  class Error < StandardError; end
  class ExpectationNotMet < Error
    def initialize name, value, pattern
      super "Expectation failure on #{name}, expected '#{value.to_s}' to match /#{pattern.to_s}/"
    end
  end
  class TaskNotFound < Error
    def initialize action, mime_type
      super "No task found for action: '#{action}', mime_type: '#{mime_type}'"
    end
  end

  class StepError < Error
    def initialize method=nil
      calling_method = caller[1]
      method = calling_method.gsub(/.*[`](.*)'$/,'\\1')
      super "#{message} in step '#{method}'"
    end
  end

  class InvalidMimeTypeInStep < StepError
    def initialize expected, got
      super "Invalid mime_type (expected /#{expected}/, got '#{got}')"
    end
  end

  class ConversionFailed < StepError
    def initialize message=nil
      super( message || "Conversion failed" )
    end
  end

  class InvalidParameterInStep < StepError
    def initialize param_name, param_value
      super( "Invalid parameter: #{param_name}: #{param_value}" )
    end
  end
end
