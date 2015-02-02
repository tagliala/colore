module Heathen
  class Converter
    def convert action, content, language='en'
      job = Job.new action, content, language
      task = Task.find action, content.mime_type
      processor = Heathen::Processor.new job: job
      begin
        processor.instance_eval &(task[:proc])
      ensure
        processor.clean_up
      end
      job.content
    end
  end
end
