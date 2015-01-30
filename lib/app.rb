require 'pathname'
require 'haml'
require 'sinatra/base'
require_relative 'document'
require_relative 'doc_key'
require_relative 'config'
require_relative 'sidekiq_workers'
require_relative 'errors'
require_relative 'utils'

module Colore
  # TODO: validate path-like parameters for invalid characters
  class App < Sinatra::Base
    set :backtrace, true
    before do
      @storage_dir = Pathname.new( C_.storage_directory )
    end

    helpers do
      def respond status, message, extra={}
        case status
          when Error
            status = status.http_code
          when StandardError
            extra[:backtrace] = status.backtrace if params[:backtrace]
            status = 500
        end
        content_type 'application/json'
        return status, {
          status: status,
          description: message,
        }.merge(extra).to_json
      end
    end

    get '/' do
      haml :index
    end

    #
    # Update document
    #
    # POST params:
    #   - created_by
    #   - fail_if_exists
    #   - title
    #   - formats
    #   - callback_url
    #   - file
    post '/document/:app/:doc_id' do |app,doc_id|
      begin
        doc_key = DocKey.new app,doc_id
        if Document.exists?(@storage_dir,doc_key)
          raise DocumentExists.new if params[:fail_if_exists] == 'true'
        else
          Document.create( @storage_dir, doc_key, params[:title] )
        end
        doc = Document.new( @storage_dir, doc_key )
        doc.title = params[:title] if params[:title]
        if params[:file]
          version_key = doc.new_version
          doc.add_file(
            version_key,
            Format::ORIGINAL,
            params[:file][:filename],
            Pathname.new(params[:file][:tempfile].path),
            params[:created_by]
          )
          doc.set_current version_key
        end
        if params[:formats]
          Sidekiq::ConversionWorker.perform_async(
            doc_key,
            doc.current_version,
            params[:formats],
            params[:callback_url]
          )
        end
        respond 201, "Document stored", {
            doc_id: doc_id,
          }
      rescue StandardError => e
        respond e, e.message
      end
    end

    #
    # Request new format
    #
    # POST params:
    #   - requested_by
    #   - formats
    #   - callback_url
    post '/document/:app/:doc_id/:version/format' do |app,doc_id,version|
      begin
        doc_key = DocKey.new app, doc_id
        raise DocumentNotFound.new unless Document.exists? @storage_dir, doc_key
        doc = Document.load @storage_dir, doc_key
        raise VersionNotFound.new unless doc.version_exists? version
        Sidekiq::ConversionWorker.perform_async doc_key, params[:formats], params[:callback_url]
        respond 202, "Conversion initiated"
      rescue StandardError => e
        respond e, e.message
      end
    end

    #
    # Delete document
    #
    # DELETE params:
    #    - deleted_by
    delete '/document/:app/:doc_id' do |app, doc_id|
      begin
        Document.delete @storage_dir, DocKey.new(app,doc_id)
        respond 200, 'Document deleted'
      rescue StandardError => e
        respond e, e.message
      end
    end

    #
    # Delete document version
    #
    # DELETE params:
    #    - deleted_by
    delete '/document/:app/:doc_id/:version' do |app, doc_id, version|
      begin
        doc = Document.load @storage_dir, DocKey.new(app,doc_id)
        doc.delete_version version
        respond 200, 'Document version deleted'
      rescue StandardError => e
        respond e, e.message
      end
    end

    #
    # Get document
    #
    get '/document/:app/:doc_id/:version/:filename' do |app, doc_id, version, filename|
      begin
        doc = Document.load @storage_dir, DocKey.new(app,doc_id)
        ctype, file = doc.get_file( version, filename )
        content_type ctype
        file
      rescue StandardError => e
        respond e, e.message
      end
    end

    #
    # Get document info
    #
    get '/document/:app/:doc_id' do |app, doc_id|
      begin
        doc = Document.load @storage_dir, DocKey.new(app,doc_id)
        respond 200, 'Information retrieved', doc.to_hash
      rescue StandardError => e
        respond e, e.message
      end
    end
  end
end
