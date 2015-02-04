require 'filemagic/ext'
require 'mime/types'
require 'heathen'

module Colore
  class Converter
    def initialize storage_dir = C_.storage_directory
      @storage_dir = storage_dir
    end

    def convert doc_key, version, filename, new_format
      doc = Document.load @storage_dir, doc_key
      ignore, orig_content = doc.get_file( version, filename)
      language = 'en' # TODO - add to spec and upload
      new_content = convert_file new_format, orig_content, language
      # TODO - handling for variant formats with the same extension
      #        probably by adding format info before suffix
      #        e.g. foo.40x40.jpg
      new_filename = "#{filename[0..-(File.extname(filename).length+1)]}.#{new_format}"
      doc.add_file version, new_filename, new_content
      return new_filename
    end

    def convert_file format, orig_content, language='en'
      Heathen::Converter.new.convert(format, orig_content, language)
    end
  end
end
