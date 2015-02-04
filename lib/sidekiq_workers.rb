require 'sidekiq'

module Colore
  module Sidekiq
    class ConversionWorker
      include ::Sidekiq::Worker
      sidekiq_options queue: :colore, retry: 5, backtrace: true

      def perform doc_key_str, version, filename, format, callback_url
        doc_key = DocKey.parse doc_key_str
        Converter.new.convert doc_key, version, filename, format
        CallbackWorker.perform_async doc_key_str, version, format, callback_url
      end
    end

    class CallbackWorker
      include ::Sidekiq::Worker
      sidekiq_options queue: :colore, retry: 5, backtrace: true

      def perform doc_key_str, version, format, callback_url
        doc_key = DocKey.parse doc_key_str
        doc = Document.load C_.storage_directory, doc_key
        rsp_hash = {
          status: 200,
          description: "Document converted",
          app: doc_key.app,
          doc_id: doc_key.doc_id,
          version: version,
          format: format,
          path: doc.file_path(version,format),
        }
        RestClient.post callback_url, JSON.pretty_generat(rsp_hash), content_type: :json
      end
    end
  end
end
