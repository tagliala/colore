module Heathen
  class Processor
    def wkhtmltopdf params=''
      expect_mime_type 'text/html'

      target_file = temp_file_name
      executioner.execute(
        *['wkhtmltopdf',
        params.split(/ +/),
        job.content_file('.html'),
        target_file,
        ].flatten
      )
      raise ConversionFailed.new(executioner.last_messages) if executioner.last_exit_status != 0
      job.content = File.read(target_file)
      File.unlink(target_file)
    end
  end
end
