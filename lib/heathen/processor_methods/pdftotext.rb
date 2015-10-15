module Heathen
  class Processor
    def pdftotext
      expect_mime_type 'application/pdf'

      target_file = temp_file_name
      executioner.execute(
        'pdftotext',
        job.content_file,
        target_file
      )
      raise ConversionFailed.new(executioner.last_messages) if executioner.last_exit_status != 0
      job.content = File.read(target_file)
      File.unlink(target_file)
    end
  end
end
