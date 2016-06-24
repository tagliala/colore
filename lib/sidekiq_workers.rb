#
# Sidekiq workers for the Colore system.
#
#
require 'rest_client'
require 'sidekiq'
require 'sidetiq'

module Colore
  module Sidekiq
    # This worker converts a document file to a new format and stores it.
    class ConversionWorker
      include ::Sidekiq::Worker
      sidekiq_options queue: :colore, retry: false

      # Converts a document file to a new format. The converted file will be stored in
      # the document version directory. If the callback_url is specified, the [CallbackWorker]
      # will be called to POST the conversion results back to the client application.
      # @param doc_key_str [String] the serialised [DocKey]
      # @param version [String] the file version
      # @param filename [String] the file to convert
      # @param action [String] the conversion to perform
      # @param callback_url [String] optional callback URL
      def perform doc_key_str, version, filename, action, callback_url=nil
        doc_key = DocKey.parse doc_key_str
        new_filename = Converter.new.convert doc_key, version, filename, action
        status = 200
        message = "Document converted"
      rescue Heathen::TaskNotFound => e
        logger.warn "#{e.message}, will not attempt to re-process this request"
        log_error e, doc_key_str, filename, action
        status = 400
        message = e.message
      rescue StandardError => e
        logger.warn "#{e.message}, will not attempt to re-process this request"
        log_error e, doc_key_str, filename, action
        status = 500
        message = e.message
      ensure
        CallbackWorker.perform_async doc_key_str, version, action, new_filename, callback_url, status, message if callback_url
      end

      private

      def log_error error, doc_key, filename, action
        errlog = Logger.new(C_.error_log || STDERR)

        log = ''
        log << "While converting #{doc_key} (#{filename}) to #{action}"
        log << "\nthe following error occurred: #{error.class} #{error.message}"
        log << "\nbacktrace:"
        log << "  " << error.backtrace.join("\n  ")

        log.split("\n").each {|line| errlog.error(line) }
      end
    end

    # This worker sends responses back to the client application.
    class CallbackWorker
      include ::Sidekiq::Worker
      sidekiq_options queue: :colore, retry: 5, backtrace: true

      # Constructs a conversion response and POSTs it to the specified callback_url.
      # @param doc_key_str [String] the serialised [DocKey]
      # @param version [String] the file version
      # @param action [String] the conversion to perform
      # @param new_filename [String] the converted file name
      # @param callback_url [String] callback URL
      # @param status [Integer) status code to send in callback
      # @param description [String] description text to send in callback
      def perform doc_key_str, version, action, new_filename, callback_url, status, description
        doc_key = DocKey.parse doc_key_str
        doc = Document.load C_.storage_directory, doc_key
        rsp_hash = {
          status: status.to_i,
          description: description,
          app: doc_key.app,
          doc_id: doc_key.doc_id,
          version: version,
          action: action,
          path: (doc.file_path(version,new_filename) if status < 300),
        }
        RestClient.post callback_url, rsp_hash
      end
    end

    # This worker periodically purges legacy conversion files (the expectation is that
    # apps using the legacy service will request the file shortly after posting the
    # original, so won't need it after then).
    class LegacyPurgeWorker
      include ::Sidekiq::Worker
      include ::Sidetiq::Schedulable
      sidekiq_options queue: :colore, retry: 0, backtrace: true
      recurrence backfill: true do
        daily.hour_of_day(6)
      end

      # Looks for old legacy docs and deletes them
      def perform
        purge_seconds = (C_.legacy_purge_days || 1).to_f * 86400.0
        dir = LegacyConverter.new.legacy_dir
        dir.each_entry do |file|
          next if (dir+file).directory?
          if Time.now - (dir+file).ctime > purge_seconds
            (dir+file).unlink
            logger.debug "Deleted old legacy file: #{file}"
          end
        end
      end
    end
  end
end
