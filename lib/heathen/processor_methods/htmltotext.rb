require 'nokogiri'

module Heathen
  class Processor
    def htmltotext
      expect_mime_type 'text/html'

      begin
        doc = Nokogiri::HTML(File.open(job.content_file))

        # Strip JS / CSS from the file so it doesn't appear in the output
        doc.css('script, link').each { |node| node.remove }

        text = doc.css('body').text
      rescue Nokogiri::SyntaxError => e
        raise ConversionFailed.new(e)
      end

      job.content = text
    end
  end
end
