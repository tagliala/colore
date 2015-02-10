require 'pathname'
require 'filemagic/ext'
require 'mime/types'
require 'heathen'

module Colore
  # The Colore Legacy Converter provides the conversion functionality from
  # the original Heathen application. Conversions are performed foreground
  # (unlike the original, where conversion takes place in the follow-up
  # URL call). The converted files are saved to a special disk area. A
  # sidekiq task will clear files older than a certain age.
  class LegacyConverter
    LEGACY = 'legacy'

    attr_reader :legacy_dir

    def initialize storage_dir = C_.storage_directory
      @storage_dir = Pathname.new(storage_dir)
      @legacy_dir = @storage_dir + LEGACY
      @legacy_dir.mkpath
    end

    # Converts the given file and stores it in the legacy directory
    # @param action [String] the conversion to perform
    # @param orig_content [String] the body of the file to convert
    # @param language [String] the file's language
    # @return [String] the path to the converted file
    def convert_file action, orig_content, language='en'
      content = Heathen::Converter.new.convert(action, orig_content, language)
      filename = Digest::SHA2.hexdigest content
      store_file filename, content
      (@legacy_dir.basename + filename).to_s
    end

    # Stores the specified file in the legacy directory
    def store_file filename, content
      File.open(@legacy_dir + filename, 'wb') { |f| f.write content }
    end

    # Loads and returns a legacy converted file
    def get_file filename
      raise "File does not exists" unless (@legacy_dir + filename).file?
      File.read(@legacy_dir + filename)
    end
  end
end
