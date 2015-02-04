require 'spec_helper'

describe Colore::Converter do
  let(:storage_dir) { tmp_storage_dir }
  let(:doc_key) { Colore::DocKey.new('app','12345') }
  let(:version) { 'v001' }
  let(:filename) { 'arglebargle.docx' }
  let(:new_format) { 'pdf' }
  let(:new_filename) { 'arglebargle.pdf' }
  let(:converter) { described_class.new }
  let(:document) { Colore::Document.load storage_dir, doc_key }

  before do
    setup_storage
    allow(Colore::C_).to receive(:storage_directory) { tmp_storage_dir }
  end

  after do
    delete_storage
  end

  context '#convert' do
    it 'runs' do
      foo = double(Heathen::Converter)
      allow(Heathen::Converter).to receive(:new) { foo }
      allow(foo).to receive(:convert) { "The quick brown fox" }
      expect(converter.convert doc_key, version, filename, new_format).to eq new_filename
      content_type, content = document.get_file version, new_filename
      expect(content_type).to eq 'text/plain; charset=us-ascii'
      expect(content).to eq 'The quick brown fox'
    end
  end
end
