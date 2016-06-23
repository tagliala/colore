require 'mime/types'

module Heathen
  module Filename
    # Suggests a new file name base on the old one and the mime_type provided
    # @return [String] a new file name, with an appropriate extension
    def self.suggest filename, mime_type
      ext = File.extname(filename)
      temp_file = filename[0..-(ext.length+1)]
      ext = MIME::Types[mime_type].first.preferred_extension rescue 'txt' # FIXME use a saner extension
      "#{temp_file}.#{ext}"
    end

    # Suggests a new file name base on the old one and the mime_type provided
    # The new file name will be positioned correctly in the new dir, so for
    # example:
    #
    #   suggest_in_new_dir( '/home/joe/src/fred.pdf',
    #                       'text/plain',
    #                       '/home/joe',
    #                       '/home/fred/Projects' )
    #
    #   should return: '/home/fred/Projects/src/fred.txt'
    #
    # @return [String] a new file name, with an appropriate extension
    def self.suggest_in_new_dir filename, mime_type, base_dir, new_dir
      file = self.suggest filename, mime_type
      "#{new_dir}#{file[base_dir.length..-1]}"
    end
  end
end
