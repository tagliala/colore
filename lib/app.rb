require 'pathname'
require 'haml'
require 'sinatra/base'
require_relative 'colore'

module Colore
  # TODO: validate path-like parameters for invalid characters
  #
  # This is the Sinatra API implementation for Colore.
  # See (BASE/config.ru) for rackup details
  class App < Sinatra::Base
    set :backtrace, true
    before do
      @storage_dir = Pathname.new( C_.storage_directory )
    end

    helpers do
      # Renders all responses (including errors) in a standard JSON format.
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

    #
    # Landing page. A vague intention exists to put the API docco here.
    #
    get '/' do
      haml :index
    end

    #
    # Create document (will fail if document already exists)
    #
    # POST params:
    #   - title
    #   - formats
    #   - callback_url
    #   - file
    put '/document/:app/:doc_id/:filename' do |app,doc_id,filename|
      begin
        doc_key = DocKey.new app,doc_id
        doc = Document.create @storage_dir, doc_key # will raise if doc exists
        call env.merge( 'REQUEST_METHOD'=>'POST' )
      rescue StandardError => e
        respond e, e.message
      end
    end

    #
    # Update document (will advance version and store document)
    #
    # POST params:
    #   - title
    #   - formats
    #   - callback_url
    #   - file
    post '/document/:app/:doc_id/:filename' do |app,doc_id,filename|
      begin
        doc_key = DocKey.new app,doc_id
        doc = Document.load( @storage_dir, doc_key )
        doc.title = params[:title] if params[:title]
        if params[:file]
          version = doc.new_version
          doc.add_file version, filename, Pathname.new(params[:file][:tempfile].path)
          doc.set_current version
        end
        doc.save_metadata
        (params[:formats] || []).each do |format|
          Sidekiq::ConversionWorker.perform_async(
            doc_key.to_s,
            doc.current_version,
            filename,
            format,
            params[:callback_url]
          )
        end
        respond 201, "Document stored", {
            app: app,
            doc_id: doc_id,
            path: doc.file_path( Document::CURRENT, filename ),
          }
      rescue StandardError => e
        respond e, e.message
      end
    end

    #
    # Request new format
    #
    # POST params:
    #   - callback_url
    post '/document/:app/:doc_id/:version/:filename/:format' do |app,doc_id,version,filename,format|
      begin
        doc_key = DocKey.new app, doc_id
        raise DocumentNotFound.new unless Document.exists? @storage_dir, doc_key
        doc = Document.load @storage_dir, doc_key
        raise VersionNotFound.new unless doc.has_version? version
        Sidekiq::ConversionWorker.perform_async doc_key, version, filename, format, params[:callback_url]
        respond 202, "Conversion initiated"
      rescue StandardError => e
        respond e, e.message
      end
    end

    #
    # Delete document
    #
    # DELETE params:
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
    delete '/document/:app/:doc_id/:version' do |app, doc_id, version|
      begin
        doc = Document.load @storage_dir, DocKey.new(app,doc_id)
        doc.delete_version version
        doc.save_metadata
        respond 200, 'Document version deleted'
      rescue StandardError => e
        respond e, e.message
      end
    end

    #
    # Get file
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

    #
    # Convert document
    #
    # POST params:
    #  file     - the file to convert
    #  format   - the format to convert to
    #  langauge - the language of the file (defaults to 'en')
    post '/convert' do
      begin
        body = params[:file][:tempfile].read
        content = Converter.new.convert_file( params[:format], body, params[:language] )
        content_type content.mime_type
        content
      rescue StandardError => e
        respond e, e.message
      end
    end
  end
end
