require 'iso-639'
module Heathen
  class Processor
    # @param: format - output format. Possibilities are nil, hocr and pdf
    #                  (nil creates a text version)
    def tesseract format: nil
      expect_mime_type 'image/tiff'

      # Grrrrrrrrrrrrrrrrrrrr Iso2/3 grrrrrrrrrrrrr
      lang = ISO_639.find job.language
      raise InvalidLanguageStep.new(job.language) if lang.nil?

      target_file = temp_file_name
      executioner.execute(
        'tesseract',
        job.content_file,
        target_file,
        '-l', lang.alpha3.downcase,
        format,
      )
      raise ConversionFailed.new(executioner.last_messages) if executioner.last_exit_status != 0
      suffix = format ? format : 'txt'
      target_file = "#{target_file}.#{suffix}"
      job.content = File.read(target_file)
      File.unlink(target_file)
    end
  end
end
