require 'spec_helper'
require 'app'
require 'config'

describe Colore::App do
  let(:appname) { 'app' }
  let(:doc_id) { '12345' }
  let(:filename) { 'arglebargle.docx' }
  let(:doc_key) { Colore::DocKey.new(app,doc_id) }
  let(:new_doc_id) { '54321' }
  let(:invalid_doc_id) { 'foobar' }
  let(:storage_dir) { tmp_storage_dir }

  def show_backtrace response
    if response.status == 500
      begin
        puts JSON.pretty_generate( JSON.parse response.body )
      rescue StandardError => e
        puts response.body
      end
    end
  end

  before do
    setup_storage
    allow(Colore::C_).to receive(:storage_directory) { tmp_storage_dir }
    allow(Colore::Sidekiq::ConversionWorker).to receive(:perform_async)
  end

  after do
    delete_storage
  end

  context 'PUT update document' do
    it 'creates a new document' do
      put "/document/#{appname}/#{new_doc_id}/#{filename}", {
          title: 'A title',
          file: Rack::Test::UploadedFile.new(__FILE__, 'application/ruby'),
          formats: [ 'ocr', 'pdf' ],
          backtrace: true
      }
      show_backtrace last_response
      expect(last_response.status).to eq 201
      expect(last_response.content_type).to eq 'application/json'
      expect(JSON.parse(last_response.body)).to match(
        {"status"=>201, "description"=>"Document stored", "doc_id"=>"54321"}
      )
      expect(Colore::Sidekiq::ConversionWorker).to have_received(:perform_async).twice
    end
    it 'fails to create an existing document' do
      put "/document/#{appname}/#{doc_id}/#{filename}", {
          title: 'A title',
          file: Rack::Test::UploadedFile.new(__FILE__, 'application/ruby'),
          formats: [ 'ocr', 'pdf' ],
          backtrace: true
      }
      show_backtrace last_response
      expect(last_response.status).to eq 409
      expect(last_response.content_type).to eq 'application/json'
      expect(JSON.parse(last_response.body)).to be_a Hash
      expect(Colore::Sidekiq::ConversionWorker).to_not have_received(:perform_async)
    end
  end

  context 'POST update document' do
    it 'runs' do
      post "/document/#{appname}/#{doc_id}/#{filename}", {
          title: 'New title',
          file: Rack::Test::UploadedFile.new(__FILE__, 'application/ruby'),
          formats: [ 'ocr', 'pdf' ],
          backtrace: true
      }
      show_backtrace last_response
      expect(last_response.status).to eq 201
      expect(last_response.content_type).to eq 'application/json'
      expect(JSON.parse(last_response.body)).to match(
        {"status"=>201, "description"=>"Document stored", "doc_id"=>"12345"}
      )
      expect(Colore::Sidekiq::ConversionWorker).to have_received(:perform_async).twice
    end

    it 'fails if document does not exist' do
      post "/document/#{appname}/#{new_doc_id}/#{filename}", {
          title: 'New title',
          file: Rack::Test::UploadedFile.new(__FILE__, 'application/ruby'),
          formats: [ 'ocr', 'pdf' ],
          backtrace: true
      }
      expect(last_response.status).to eq 400
      expect(last_response.content_type).to eq 'application/json'
      expect(JSON.parse(last_response.body)).to be_a Hash
      expect(Colore::Sidekiq::ConversionWorker).to_not have_received(:perform_async)
    end
  end

  context 'POST new format' do
    it 'starts a new conversion' do
      post "/document/#{appname}/#{doc_id}/current/#{filename}/format", {
          formats: [ 'ocr', 'pdf' ],
          backtrace: true
      }
      show_backtrace last_response
      expect(last_response.status).to eq 202
      expect(last_response.content_type).to eq 'application/json'
      expect(JSON.parse(last_response.body)).to match(
        {"status"=>202, "description"=>"Conversion initiated"}
      )
      expect(Colore::Sidekiq::ConversionWorker).to have_received(:perform_async).once
    end
    it 'fails if invalid document' do
      post "/document/#{appname}/#{invalid_doc_id}/current/#{filename}/format", {
          formats: [ 'ocr', 'pdf' ],
          backtrace: true
      }
      show_backtrace last_response
      expect(last_response.status).to eq 400
      expect(last_response.content_type).to eq 'application/json'
      expect(JSON.parse(last_response.body)).to be_a Hash
      expect(Colore::Sidekiq::ConversionWorker).to_not have_received(:perform_async)
    end
    it 'fails if invalid version' do
      post "/document/#{appname}/#{doc_id}/fred/#{filename}/format", {
          formats: [ 'ocr', 'pdf' ],
          backtrace: true
      }
      show_backtrace last_response
      expect(last_response.status).to eq 400
      expect(last_response.content_type).to eq 'application/json'
      expect(JSON.parse(last_response.body)).to be_a Hash
      expect(Colore::Sidekiq::ConversionWorker).to_not have_received(:perform_async)
    end
  end

  context 'DELETE document' do
    it 'runs' do
      delete "/document/#{appname}/#{doc_id}", {
        deleted_by: 'a.person'
      }
      show_backtrace last_response
      expect(last_response.status).to eq 200
      expect(last_response.content_type).to eq 'application/json'
      expect(JSON.parse(last_response.body)).to match(
        {"status"=>200, "description"=>"Document deleted"}
      )
    end
  end

  context 'DELETE document version' do
    it 'runs' do
      delete "/document/#{appname}/#{doc_id}/v001", {
        deleted_by: 'a.person'
      }
      show_backtrace last_response
      expect(last_response.status).to eq 200
      expect(last_response.content_type).to eq 'application/json'
      expect(JSON.parse(last_response.body)).to match(
        {"status"=>200, "description"=>"Document version deleted"}
      )
    end
    it 'fails if you try to delete current' do
      delete "/document/#{appname}/#{doc_id}/current", {
        deleted_by: 'a.person'
      }
      show_backtrace last_response
      expect(last_response.status).to eq 400
      expect(last_response.content_type).to eq 'application/json'
      expect(JSON.parse(last_response.body)).to be_a Hash
    end
    it 'fails if you try to delete the current version' do
      delete "/document/#{appname}/#{doc_id}/v002", {
        deleted_by: 'a.person'
      }
      show_backtrace last_response
      expect(last_response.status).to eq 400
      expect(last_response.content_type).to eq 'application/json'
      expect(JSON.parse(last_response.body)).to be_a Hash
    end
  end

  context 'GET document' do
    it 'runs' do
      get "/document/#{appname}/#{doc_id}/current/#{filename}?backtrace=true"
      show_backtrace last_response
      expect(last_response.status).to eq 200
      expect(last_response.content_type).to eq 'application/vnd.openxmlformats-officedocument.wordprocessingml.document; charset=binary'
      expect(last_response.body).to_not be_nil
    end
    it 'fails for an invalid document' do
      get "/document/#{appname}/#{invalid_doc_id}/current/#{filename}"
      expect(last_response.status).to eq 400
      expect(last_response.content_type).to eq 'application/json'
      expect(JSON.parse(last_response.body)).to be_a Hash
    end
    it 'fails for an invalid filename' do
      get "/document/#{appname}/#{doc_id}/current/foo.txt"
      expect(last_response.status).to eq 400
      expect(last_response.content_type).to eq 'application/json'
      expect(JSON.parse(last_response.body)).to be_a Hash
    end
  end

  context 'GET document info' do
    it 'runs' do
      get "/document/#{appname}/#{doc_id}?backtrace=true"
      show_backtrace last_response
      expect(last_response.status).to eq 200
      expect(last_response.content_type).to eq 'application/json'
      expect(JSON.parse(last_response.body)).to be_a Hash
    end
    it 'fails for an invalid document' do
      get "/document/#{appname}/#{invalid_doc_id}"
      expect(last_response.status).to eq 400
      expect(last_response.content_type).to eq 'application/json'
      expect(JSON.parse(last_response.body)).to be_a Hash
    end
  end
end
