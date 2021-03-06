require 'spec_helper'

describe 'Standard Heathen tasks:' do
  before do
    setup_storage
    allow(Colore::C_).to receive(:storage_directory) { tmp_storage_dir }
  end

  after do
    delete_storage
  end

  let(:converter) { Heathen::Converter.new(logger: spec_logger) }

  context 'ocr' do
    it 'runs' do
      content = fixture('heathen/quickfox.jpg').read
      new_content = converter.convert 'ocr', content
      expect(new_content.mime_type).to eq 'application/pdf; charset=binary'
    end
  end

  context 'ocr_text' do
    it 'converts jpeg' do
      content = fixture('heathen/quickfox.jpg').read
      new_content = converter.convert 'ocr_text', content
      expect(new_content.mime_type).to eq 'text/plain; charset=us-ascii'
    end

    it 'converts bmp' do
      content = fixture('heathen/quickfox.bmp').read
      new_content = converter.convert 'ocr_text', content
      expect(new_content.mime_type).to eq 'text/plain; charset=us-ascii'
    end
  end

  context 'pdf' do
    it 'converts images' do
      content = fixture('heathen/quickfox.jpg').read
      new_content = converter.convert 'pdf', content
      expect(new_content.mime_type).to eq 'application/pdf; charset=binary'
    end

    it 'converts HTML documents' do
      content = fixture('heathen/quickfox.html').read
      new_content = converter.convert 'pdf', content
      expect(new_content.mime_type).to eq 'application/pdf; charset=binary'
    end

    it 'converts Office documents' do
      content = fixture('heathen/msword.docx').read
      new_content = converter.convert 'pdf', content
      expect(new_content.mime_type).to eq 'application/pdf; charset=binary'
    end
  end

  context 'txt' do
    it 'converts odt' do
      content = fixture('heathen/ooword.odt').read
      new_content = converter.convert 'txt', content
      expect(new_content.mime_type).to eq 'text/plain; charset=us-ascii'
    end

    it 'converts docx' do
      content = fixture('heathen/msword.docx').read
      new_content = converter.convert 'txt', content
      expect(new_content.mime_type).to eq 'text/plain; charset=us-ascii'
    end

    it 'converts images' do
      content = fixture('heathen/quickfox.jpg').read
      new_content = converter.convert 'txt', content
      expect(new_content.mime_type).to eq 'text/plain; charset=us-ascii'
    end

    it 'converts pdf' do
      content = fixture('heathen/quickfox.pdf').read
      new_content = converter.convert 'txt', content
      expect(new_content.mime_type).to eq 'text/plain; charset=us-ascii'
    end

    it 'converts HTML documents' do
      content = fixture('heathen/quickfox.html').read
      new_content = converter.convert 'txt', content
      expect(new_content.mime_type).to eq 'text/plain; charset=us-ascii'
    end
  end

  context 'msoffice' do
    it 'runs' do
      content = fixture('heathen/ooword.odt').read
      new_content = converter.convert 'msoffice', content
      expect(ms_word_mime_types).to include(new_content.mime_type)
    end
  end

  context 'ooffice' do
    it 'runs' do
      content = fixture('heathen/msword.docx').read
      new_content = converter.convert 'ooffice', content
      expect(oo_mime_types).to include(new_content.mime_type)
    end
  end

  context 'doc' do
    it 'runs' do
      content = fixture('heathen/ooword.odt').read
      new_content = converter.convert 'doc', content
      expect(ms_word_mime_types).to include(new_content.mime_type)
    end
  end
end
