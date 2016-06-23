module Heathen
  class Processor
    def pdftotext
      expect_mime_type 'application/pdf'

      executioner.execute(
        'tika',
        '--text',
        job.content_file,
        binary: true
      )
      raise ConversionFailed.new(executioner.last_messages) if executioner.last_exit_status != 0

      job.content = executioner.stdout
    end
  end
end
