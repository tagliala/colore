require 'sidekiq'

module Colore
  module Sidekiq
    class ConversionWorker
      include ::Sidekiq::Worker
      def perform_async doc_key_str, formats, callback_url
        doc_key = DocKey.parse doc_key_str
        format = formats.shift
        Converter.new.convert doc_key, format do
          if formats.size == 0
            CallbackWorker.perform_async doc_key_str, callback_url
          else
            self.class.perform_async doc_key_str, formats, callback_url
          end
        end
      end
    end

    class CallbackWorker
      include ::Sidekiq::Worker
      def perform_async doc_key_str, callback_url
        doc_key = DocKey.parse doc_key_str
        doc = Document.new doc_key
        response = {
          status: 200,
          description: "Document converted",
        }.merge(doc.to_hash).to_json
        RestClient.post callback_url, response, content_type: :json
      end
    end
  end
end
