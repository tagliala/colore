require 'digest'

module Colore
  module Utils
    def self.symbolize_keys obj
      case obj
        when Hash
          h = {}
          obj.each do |k,v|
            h[k.to_sym] = symbolize_keys v
          end
          h
        when Array
          obj.map{ |o| symbolize_keys o }
        else
          obj
      end
    end
    def symbolize_keys obj
      Colore::Utils.symbolize_keys obj
    end

    def self.metadata_filename directory
      directory + 'metadata.json'
    end

    def self.read_metadata directory
      filename = metadata_filename directory
      return {} unless File.exist? filename
      md = JSON.parse( File.read(filename) )
      symbolize_keys md
    end
  end
end
