require 'filemagic/ext'
require 'mime/types'
require 'heathen'

module Colore
  class Converter
    def initialize storage_dir = C_.storage_directory
      @storage_dir = storage_dir
    end

    def convert app_id, doc_id, version, format
      doc = Document.load DocKey.new(app_id, doc_id)
      orig_path = doc.versions[version.to_sym].formats[Format::ORIGINAL].path
      orig_content = File.read(orig_path)
      language = 'en' # TODO - add to spec and upload
      new_content = convert_file format, orig_content, language
      new_filename = "converted.#{get_suffix new_content.mime_type}"
      doc.add_file version, format, new_filename, new_content
    end

    def convert_file format, orig_content, language='en'
      Heathen::Converter.new.convert(format, orig_content, language)
    end

    def get_suffix mime_type
      Mime::Types.of(mime_type).first.preferred_extension
      # TODO - some form of error trapping for unknown mime types is probably a good idea
      #        as I don't know how well filemagic and mime/types get on
    end
  end
end
