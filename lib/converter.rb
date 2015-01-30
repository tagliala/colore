module Colore
  class Converter
    def initialize
      # TODO: config
    end

    def convert app_id, doc_id
      metadata = @docstore.load_metadata app_id, doc_id
      orig_body = @docstore.load_content app_id, doc_id, :original
      orig_md = metadata[:versions][:original]
      #heathen = AutoHeathen::Converter.new
      #action = heathen.get_action orig_md[:content_type]
      language = metadata[:language] || 'en'
      #conv_filename, conv_body = heathen.convert action, language, orig_md[:filename], orig_body
      #metadata = @docstore.write_file app_id, doc_id, conv_filename, conv_body
    end
  end
end
