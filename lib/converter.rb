require 'filemagic/ext'
require 'mime/types'
require 'heathen'

module Colore
  # The Colore Converter is a glue class to allow Colore to access the Heathen conversion
  # system.
  class Converter
    def initialize storage_dir: C_.storage_directory, logger: Logger.new(nil)
      @storage_dir = storage_dir
      @logger = logger
    end

    # Converts the given file and stores it under the same document version.
    # @param doc_key [DocKey] the document identifier
    # @param version [String] the file version
    # @param filename [String] the name of the file to convert
    # @param action [String] the conversion to perform
    # @return the converted file name
    def convert doc_key, version, filename, action
      doc = Document.load @storage_dir, doc_key
      ignore, orig_content = doc.get_file( version, filename)
      language = 'en' # TODO - add to spec and upload
      new_content = convert_file action, orig_content, language
      # TODO - handling for variant formats with the same extension
      #        probably by adding format info before suffix
      #        e.g. foo.40x40.jpg
      new_filename = Heathen::Filename.suggest filename, new_content.mime_type
      doc.add_file version, new_filename, new_content
      doc.save_metadata
      return new_filename
    end

    # Converts the supplied content. Nothing gets saved.
    # @param action [String] the conversion to perform
    # @param orig_content [String] the body of the file to convert
    # @param language [String] the file's language
    # @return [String] the converted file body
    def convert_file action, orig_content, language='en'
      Heathen::Converter.new(logger:@logger).convert(action, orig_content, language)
    rescue Heathen::TaskNotFound => e
      raise InvalidAction.new( e.message )
    rescue Heathen::Error => e
      raise ConversionError.new( e )
    end
  end
end
