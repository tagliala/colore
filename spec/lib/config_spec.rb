require 'spec_helper'
require 'config'

describe Colore::C_ do
  before do
    described_class.reset
    allow(described_class).to receive(:config_file_path) { fixture('app.yml') }
  end

  after do
    described_class.reset
  end

  context '.config' do
    it 'runs' do
      expect(described_class.config).to be_a(described_class)
      expect(described_class.config.storage_directory).to eq 'foo'
    end
  end

  context '.method_missing' do
    it 'finds #storage_directory' do
      expect(described_class.storage_directory).to eq 'foo'
    end
    it 'fails on invalid value' do
      expect {
        described_class.foo
      }.to raise_error
    end
  end
end
