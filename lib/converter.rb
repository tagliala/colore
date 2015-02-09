require 'filemagic/ext'
require 'mime/types'
require 'heathen'

module Colore
  # The Colore Converter is a glue class to allow Colore to access the Heathen conversion
  # system.
  class Converter
    def initialize storage_dir = C_.storage_directory
      @storage_dir = storage_dir
    end

    # Converts the given file and stores it under the same document version.
    # @param doc_key [DocKey] the document identifier
    # @param version [String] the file version
    # @param filename [String] the name of the file to convert
    # @param new_format [String] the format to convert to
    # @return the converted file name
    def convert doc_key, version, filename, new_format
      doc = Document.load @storage_dir, doc_key
      ignore, orig_content = doc.get_file( version, filename)
      language = 'en' # TODO - add to spec and upload
      new_content = convert_file new_format, orig_content, language
      # TODO - handling for variant formats with the same extension
      #        probably by adding format info before suffix
      #        e.g. foo.40x40.jpg
      new_filename = Heathen::Filename.suggest filename, new_content.mime_type
      doc.add_file version, new_filename, new_content
      doc.save_metadata
      return new_filename
    end

    # Converts the supplied content. Nothing gets saved.
    # @param format [String] the format to convert to
    # @param orig_content [String] the body of the file to convert
    # @param language [String] the file's language
    # @return [String] the converted file body
    def convert_file format, orig_content, language='en'
      Heathen::Converter.new.convert(format, orig_content, language)
    rescue Heathen::TaskNotFound => e
      raise InvalidFormat.new( e.message )
    rescue Heathen::Error => e
      raise ConversionError.new( e )
    end
  end
end
