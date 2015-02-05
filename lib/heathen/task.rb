module Heathen
  # A Heathen task is a block of ruby called (by [Converter] in the context of a 
  # [Processor] object. This allows us to call the Processor methods in a relatively
  # concise (and hopefully understandable) way.
  #
  # For example:
  #
  #  Heathen::Task.register 'ocr','image/*' do
  #    convert_image to: :tiff
  #    tesseract format: 'pdf'
  #  end
  #
  # In this case, the task will be selected if a request is made to OCR an image. A
  # Processor object will be created and the block executed in its context (see source in
  # [Converter#convert]). So, #convert_image and #tesseract are mixin methods of the
  # Processor object, but of course you can put whatever Ruby you like into the task block.
  class Task
    class << self
      def tasks
        @tasks ||= []
      end

      # Registers a code block to be run for the given action and mime type.
      def register action, mime_type_pattern, &block
        tasks << { action: action, mime_type_pattern: mime_type_pattern, proc: block }
      end

      # Finds a registered task suitable for the given action and mime type (note, the first
      # suitable one will be selected).
      def find action, mime_type
        tasks.each do |task|
          if task[:action] == action && mime_type =~ %r[#{task[:mime_type_pattern]}]
            return task
          end
        end
        raise TaskNotFound.new action, mime_type
      end

      # Performs a task (generally called in a 
      #def perform action, job
        #task = find action, job.mime_type
        #task[:proc].call job
      #end

      # Deletes all registered tasks
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

