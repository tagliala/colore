require 'yaml'

module Colore
  #
  # This is a simple mechanism to hold document configuration. A future version will replace
  # this with SimpleConfig.
  #
  # It is accessed by calling C_.{config setting}, where the config settings are
  # defined as attr_accessors in the class. For example:
  #
  #   storage_dir = C_.storage_directory
  #
  class C_
    # Base storage directory for all documents
    attr_accessor :storage_directory
    # Redis connection URL (used by sidekiq)
    attr_accessor :redis_url
    # Redis namespace (used by sidekiq)
    attr_accessor :redis_namespace

    def self.config_file_path
      # BASE/config/app.yml
      Pathname.new(__FILE__).realpath.parent.parent + 'config' + 'app.yml'
    end

    def self.config
      @config ||= begin
        yaml = YAML.load File.read(config_file_path)
        c = new
        c.storage_directory = yaml['storage_directory']
        c.redis_url = yaml['redis_url']
        c.redis_namespace = yaml['redis_namespace']
        c
      end
    end

    def self.method_missing *args
      if config.respond_to? args[0].to_sym
        config.send( *args )
      else
        super
      end
    end
  end
end
