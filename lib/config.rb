require 'yaml'
require 'erb'

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
    # File URL base for legacy convert API method
    attr_accessor :legacy_url_base
    # Number of days to keep legacy files before purging
    attr_accessor :legacy_purge_days
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
        yaml = YAML.load(ERB.new(File.read(config_file_path)).result)
        c = new
        c.storage_directory = yaml['storage_directory']
        c.legacy_url_base   = yaml['legacy_url_base']
        c.legacy_purge_days = yaml['legacy_purge_days'].to_i
        c.redis_url         = yaml['redis_url']
        c.redis_namespace   = yaml['redis_namespace']
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

    # Reset config - used for testing
    def self.reset
      @config = nil
    end
  end
end
