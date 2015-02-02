require 'iso-639'
module Heathen
  class Processor
    # @param: format - output format. Must be one of:
    #    pdf - convert to PDF (any libre-office format)
    #    ms  - corresponding Microsoft format
    #    oo  - corresponding LibreOffice format
    def libreoffice( format: )
      suffixes = {
        'pdf' => {
          '.*' => 'pdf',
        },
        'ms' => {
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document' => 'docx',
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' => 'xlsx',
          'application/vnd.openxmlformats-officedocument.presentationml.presentation' => 'pptx',
          'application/vnd.oasis.opendocument.text' => 'docx',
          'application/vnd.oasis.opendocument.spreadsheet' => 'xlsx',
          'application/vnd.oasis.opendocument.presentation' => 'pptx',
          'application/zip' => 'docx',
        },
        'oo' => {
          'application/msword' => 'odt',
          'application/vnd.ms-word' => 'odt',
          'application/vnd.ms-excel' => 'ods',
          'application/vnd.ms-office' => 'odt',
          'application/vnd.ms-powerpoint' => 'odp',
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document' => 'odt',
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' => 'ods',
          'application/vnd.openxmlformats-officedocument.presentationml.presentation' => 'odp',
        }
      }

      raise InvalidParameterInStep.new('format', format) unless suffixes[format.to_s]
      to_suffix = nil
      suffixes[format.to_s].each do |k,v|
        to_suffix = v if job.mime_type =~ /#{k}/
      end
      raise InvalidMimeTypeInStep.new('(various document formats)', job.mime_type) unless to_suffix

      target_file = "#{job.content_file}.#{to_suffix}"
      executioner.execute(
        'libreoffice',
        '--convert-to', to_suffix,
        '--outdir', sandbox_dir,
        job.content_file,
        '--headless',
      )
      raise ConversionFailed.new(executioner.last_messages) if executioner.last_exit_status != 0
      raise ConversionFailed.new("Cannot find converted file (looking for #{File.basename(target_file)})" ) unless File.exist? target_file
      c = File.read(target_file)
      job.content = File.read(target_file)
      File.unlink(target_file)
    end
  end
end
