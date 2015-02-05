require 'spec_helper'
require 'filemagic/ext'

describe Heathen::Filename do
  let(:content) { 'The quick brown fox jumps over the lazy dog' }
  let(:mime_type) { content.mime_type }
  context '.suggest' do
    it 'suggests foo.pdf' do
      expect(described_class.suggest 'foo.pdf', mime_type).to eq 'foo.txt'
    end

    it 'suggests bar/foo.pdf' do
      expect(described_class.suggest 'bar/foo.pdf', mime_type).to eq 'bar/foo.txt'
    end

    it 'suggests foo' do
      expect(described_class.suggest 'foo', mime_type).to eq 'foo.txt'
    end

    it 'suggests bar/foo' do
      expect(described_class.suggest 'bar/foo', mime_type).to eq 'bar/foo.txt'
    end
  end

  context '.suggest_in_new_dir' do
    it 'suggests (short dir) -> (longer dir)' do
      expect(
        described_class.suggest_in_new_dir '/home/joe/src/foo.pdf', mime_type, '/home', '/opt/users'
      ).to eq '/opt/users/joe/src/foo.txt'
    end

    it 'suggests (longer dir) -> (short dir)' do
      expect(
        described_class.suggest_in_new_dir '/opt/users/joe/src/foo.pdf', mime_type, '/opt/users', '/home'
      ).to eq '/home/joe/src/foo.txt'
    end

  end
end
