require 'spec_helper'
require 'rest_client'

describe Colore::Sidekiq::ConversionWorker do
  let(:doc_key) { Colore::DocKey.new('app','12345') }
  let(:callback_url) { 'http://foo/bar' }

  before do
    @mock_converter = double(Colore::Converter)
    allow(Colore::Converter).to receive(:new) { @mock_converter }
    allow(@mock_converter).to receive(:convert)
  end

  context '#perform' do
    it 'runs' do
      expect(Colore::Sidekiq::CallbackWorker).to receive(:perform_async)
      described_class.new.perform doc_key.to_s, 'current', 'arglebargle.docx', 'pdf', callback_url
    end

    it 'gives up on Heathen::TaskNotFound' do
      allow(@mock_converter).to receive(:convert) { raise Heathen::TaskNotFound.new('foo','bar') }
      expect(Colore::Sidekiq::CallbackWorker).to receive(:perform_async) {}
      described_class.new.perform doc_key.to_s, 'current', 'arglebargle.docx', 'pdf', callback_url
    end

    it 'gives up on other errors' do
      allow(@mock_converter).to receive(:convert) { raise 'arglebargle' }
      expect(Colore::Sidekiq::CallbackWorker).to receive(:perform_async) {}
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
      expect(RestClient).to receive(:post).with(callback_url,Hash)
      described_class.new.perform doc_key.to_s, 'current', 'arglebargle.docx', 'pdf', callback_url, 250, 'foobar'
    end
  end
end

describe Colore::Sidekiq::LegacyPurgeWorker do
  before do
    setup_storage
    allow(Colore::C_).to receive(:storage_directory) { tmp_storage_dir }
    allow(Colore::C_).to receive(:legacy_purge_days) { 2 }
  end
  after do
    delete_storage
  end
  context '#perform' do
    it 'runs' do
      dir = Colore::LegacyConverter.new.legacy_dir
      file1 = dir + 'file1.tiff'
      file2 = dir + 'file2.tiff'
      file1.open('w') { |f| f.write 'foobar' }
      file2.open('w') { |f| f.write 'foobar' }
      described_class.new.perform
      expect(file1.file?).to eq true
      expect(file2.file?).to eq true
      Timecop.freeze(Date.today + 1)
      described_class.new.perform
      expect(file1.file?).to eq true
      expect(file2.file?).to eq true
      Timecop.freeze(Date.today + 3)
      described_class.new.perform
      expect(file1.file?).to eq false
      expect(file2.file?).to eq false
    end
  end
end
