require 'spec_helper'

describe Colore::DocKey do
  let(:doc_key) { described_class.new('myapp','mydoc') }

  context '.initialize' do
    it 'throws error if app is invalid' do
      expect { described_class.new 'my app', 'mydoc' }.to raise_error(Colore::InvalidParameter)
    end
    it 'throws error if doc_id is invalid' do
      expect { described_class.new 'myapp', 'my doc' }.to raise_error(Colore::InvalidParameter)
    end
  end

  context '#path' do
    it 'runs' do
      expect(doc_key.path).to be_a Pathname
    end
  end

  context '#to_s' do
    it 'runs' do
      expect(doc_key.to_s).to eq 'myapp/mydoc'
    end
  end

  context '#subdirectory' do
    it 'runs' do
      expect(doc_key.subdirectory).to eq 'd8'
    end
  end
end
