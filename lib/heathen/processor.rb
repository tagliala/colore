require 'logger'

module Heathen
  # The Processor is the heart of the Heathen conversion process. Mixed in to it are all
  # of the processing steps available to Heathen (see the processing_methods directory).
  #
  # See [Task] for how it is used.
  #
  # Mixin methods (defined in processing_methods/) are expected to make their changes to
  # the Processor#job object, setting content or other values as necessary.
  class Processor
    attr_reader :job
    attr_reader :executioner
    attr_reader :sandbox_dir

    # Creates a new processor.
    # @param job [Job] the job to be performed.
    # @param logger [Logger] an optional logger.
    # @param base_tmpdir [String] the base directory for all temporary (sandbox_dir) files
    def initialize( job:, logger: Logger.new(STDOUT), base_tmpdir:'/tmp' )
      @job = job
      @logger = logger
      @executioner = Heathen::Executioner.new(@logger)
      @sandbox_dir = Dir.mktmpdir( "heathen", base_tmpdir.to_s )
      job.sandbox_dir = @sandbox_dir
    end

    # Compares the job current content's mime type with the given pattern, raising InvalidMimeTypeInStep if it does not match.
    # @param pattern [String] a regex pattern, e.g. "image/.*"
    # This is a helper method for mixin methods.
    def expect_mime_type pattern
      raise InvalidMimeTypeInStep.new(pattern,job.mime_type) unless job.mime_type =~ %r[#{pattern}]
    end

    # Performs a sub-task, defined by action. See [Task] for details.
    def perform_task action
      task_proc = Task.find(action, job.mime_type)[:proc]
      self.instance_eval &task_proc
    end

    # Called to clean up temporary files at end of processing
    def clean_up
      FileUtils.remove_entry @sandbox_dir
    end

    # Creates a new temporary file in the sandbox
    def temp_file_name prefix='', suffix=''
      Dir::Tmpname.create( [prefix,suffix], @sandbox_dir ){}
    end

    def config_file name
      # I don't like this. Change for C_ ? - I'd like to keep colore bits out so I can gemify heathen
      Pathname.new(__FILE__).realpath.parent.parent.parent + 'config' + name
    end

    def log
      @logger
    end
  end
end
