require 'tempfile'

module Heathen
  class Job
    attr_accessor :action
    attr_accessor :language
    attr_accessor :original_mime_type
    attr_accessor :original_content
    attr_reader :content # the current content
    attr_reader :mime_type
    attr_reader :temp_files

    attr_accessor :steps_performed
    attr_accessor :sandbox_dir

    def initialize action, content, language='en', sandbox_dir=nil
      @action = action
      @language = language
      @original_content = content
      @original_mime_type = content.mime_type
      self.content = @original_content
      @sandbox_dir = sandbox_dir
    end

    def content= content
      @content = content
      @mime_type = content.mime_type
      @temp_file.unlink if @temp_file
      @temp_file = nil
    end

    def content_file suffix=''
      @tempfile ||= begin
        t = Tempfile.new ["heathen",suffix], @sandbox_dir
        t.write @content
        t.close
        t
      end
      @tempfile.path
    end
  end
end
