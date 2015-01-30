require 'yaml'

module Colore
  class C_
    attr_accessor :storage_directory

    def self.config_file_path
      Pathname.new(__FILE__).realpath.parent.parent + 'config' + 'app.yml'
    end

    def self.config
      @config ||= begin
        yaml = YAML.load File.read(config_file_path)
        c = new
        c.storage_directory = yaml['storage_directory']
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
