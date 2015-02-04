require 'spec_helper'
require 'rest_client'

describe Colore::Sidekiq::ConversionWorker do
  let(:doc_key) { Colore::DocKey.new('app','12345') }
  let(:callback_url) { 'http://foo/bar' }

  context '#perform' do
    it 'runs' do
      mock_converter = double(Colore::Converter)
      allow(Colore::Converter).to receive(:new) { mock_converter }
      allow(mock_converter).to receive(:convert)
      expect(Colore::Sidekiq::CallbackWorker).to receive(:perform_async)
      described_class.new.perform doc_key.to_s, 'current', 'arglebargle.docx', 'pdf', callback_url
    end
  end
end

describe Colore::Sidekiq::CallbackWorker do
  let(:doc_key) { Colore::DocKey.new('app','12345') }
  let(:callback_url) { 'http://foo/bar' }
  before do
    setup_storage
    allow(Colore::C_).to receive(:storage_directory) { tmp_storage_dir }
  end
  after do
    delete_storage
  end
  context '#perform' do
    it 'runs' do
      expect(RestClient).to receive(:post).with(callback_url,String,Hash)
      described_class.new.perform doc_key.to_s, 'current', 'arglebargle.docx', 'pdf', callback_url
    end
  end
end
