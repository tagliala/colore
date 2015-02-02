require 'logger'

module Heathen
  class Processor
    attr_reader :job
    attr_reader :executioner
    attr_reader :sandbox_dir

    def initialize( job:, logger: Logger.new(STDOUT), base_tmpdir:'/tmp' )
      @job = job
      @logger = logger
      @executioner = Heathen::Executioner.new(@logger)
      @sandbox_dir = Dir.mktmpdir( "heathen", base_tmpdir.to_s )
      job.sandbox_dir = @sandbox_dir
    end

    def expect_mime_type pattern
      raise InvalidMimeTypeInStep.new(pattern,job.mime_type) unless job.mime_type =~ %r[#{pattern}]
    end

    def perform_task action
      task_proc = Task.find(action, job.mime_type)[:proc]
      self.instance_eval &task_proc
    end

    def clean_up
      FileUtils.remove_entry @sandbox_dir
    end

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
