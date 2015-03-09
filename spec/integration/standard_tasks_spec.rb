require 'spec_helper'

describe 'Standard Heathen tasks:' do
  before do
    setup_storage
    allow(Colore::C_).to receive(:storage_directory) { tmp_storage_dir }
  end

  after do
    delete_storage
  end

  let(:converter) { Heathen::Converter.new(logger: Logger.new($stderr)) }

  context 'ocr' do
    it 'runs' do
      content = fixture('heathen/quickfox.jpg').read
      new_content = converter.convert 'ocr', content
      expect(new_content.mime_type).to eq 'application/pdf; charset=binary'
    end
  end

  context 'ocr_text' do
    it 'runs' do
      content = fixture('heathen/quickfox.jpg').read
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

  context 'msoffice' do
    it 'runs' do
      content = fixture('heathen/ooword.odt').read
      new_content = converter.convert 'msoffice', content
      expect(new_content.mime_type).to eq 'application/vnd.openxmlformats-officedocument.wordprocessingml.document; charset=binary'
    end
  end

  context 'ooffice' do
    it 'runs' do
      content = fixture('heathen/msword.docx').read
      new_content = converter.convert 'ooffice', content
      expect(new_content.mime_type).to eq 'application/xml; charset=us-ascii'
    end
  end

  context 'doc' do
    it 'runs' do
      content = fixture('heathen/ooword.odt').read
      new_content = converter.convert 'doc', content
      expect(new_content.mime_type).to eq 'application/vnd.openxmlformats-officedocument.wordprocessingml.document; charset=binary'
    end
  end
end
