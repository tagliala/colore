module Heathen
  class Task
    class << self
      def tasks
        @tasks ||= []
      end

      def register action, mime_type_pattern, &block
        tasks << { action: action, mime_type_pattern: mime_type_pattern, proc: block }
      end

      def find action, mime_type
        tasks.each do |task|
          if task[:action] == action && mime_type =~ %r[#{task[:mime_type_pattern]}]
            return task
          end
        end
        raise TaskNotFound.new action, mime_type
      end

      def perform action, job
        task = find action, job.mime_type
        task[:proc].call job
      end

      def clear
        @tasks = []
      end
    end
  end
end

Heathen::Task.register 'ocr', 'image/.*' do
  convert_image to: :tiff, params: '-depth 8 -density 300 -background white +matte'
  tesseract format: 'pdf'
end

Heathen::Task.register 'pdf', '.*' do
  case job.mime_type
    when %r[image/*]
      perform_task 'ocr'
    when %r[text/html]
      wkhtmltopdf
    else
      libreoffice format: 'pdf'
  end
end

Heathen::Task.register 'microsoft', '.*' do
  libreoffice 'ms'
end

Heathen::Task.register 'openoffice', '.*' do
  libreoffice 'oo'
end

