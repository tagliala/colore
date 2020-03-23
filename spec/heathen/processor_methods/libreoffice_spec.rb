require 'spec_helper'

describe Heathen::Processor do
  let(:ms_word_content) { File.read(fixture('heathen/msword.docx')) }
  let(:ms_spreadsheet_content) { File.read(fixture('heathen/msexcel.xlsx')) }
  let(:ms_ppt_content) { File.read(fixture('heathen/mspowerpoint.pptx')) }
  let(:oo_word_content) { File.read(fixture('heathen/ooword.odt')) }
  let(:oo_spreadsheet_content) { File.read(fixture('heathen/oospreadsheet.ods')) }
  let(:oo_presentation_content) { File.read(fixture('heathen/oopresentation.odp')) }

  def new_job content
    @job = Heathen::Job.new 'foo', content, 'en'
    @processor = described_class.new job: @job, logger: spec_logger
  end

  after do
    @processor.clean_up
  end

  context '#libreoffice' do
    context 'convert to PDF' do
      it 'from MS word' do
        new_job ms_word_content
        @processor.libreoffice format: 'pdf'
        expect(@job.content.mime_type).to eq 'application/pdf; charset=binary'
      end
      it 'from MS spreadsheet' do
        new_job ms_spreadsheet_content
        @processor.libreoffice format: 'pdf'
        expect(@job.content.mime_type).to eq 'application/pdf; charset=binary'
      end
      it 'from MS powerpoint' do
        new_job ms_ppt_content
        @processor.libreoffice format: 'pdf'
        expect(@job.content.mime_type).to eq 'application/pdf; charset=binary'
      end
      it 'from OO word' do
        new_job oo_word_content
        @processor.libreoffice format: 'pdf'
        expect(@job.content.mime_type).to eq 'application/pdf; charset=binary'
      end
      it 'from OO spreadsheet' do
        new_job oo_spreadsheet_content
        @processor.libreoffice format: 'pdf'
        expect(@job.content.mime_type).to eq 'application/pdf; charset=binary'
      end
      it 'from OO presentation' do
        new_job oo_presentation_content
        @processor.libreoffice format: 'pdf'
        expect(@job.content.mime_type).to eq 'application/pdf; charset=binary'
      end
    end

    context 'convert to MS' do
      it 'from OO word' do
        new_job oo_word_content
        @processor.libreoffice format: 'msoffice'
        expect(ms_word_mime_types).to include(@job.content.mime_type)
      end
      it 'from OO spreadsheet' do
        new_job oo_spreadsheet_content
        @processor.libreoffice format: 'msoffice'
        expect(@job.content.mime_type).to eq 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet; charset=binary'
      end
      it 'from OO presentation' do
        new_job oo_presentation_content
        @processor.libreoffice format: 'msoffice'
        expect(@job.content.mime_type).to eq 'application/vnd.openxmlformats-officedocument.presentationml.presentation; charset=binary'
      end
    end

    context 'convert to OO' do
      it 'from MS word' do
        new_job ms_word_content
        @processor.libreoffice format: 'ooffice'
        expect(oo_mime_types).to include(@job.content.mime_type)
      end
      it 'from MS spreadsheet' do
        new_job ms_spreadsheet_content
        @processor.libreoffice format: 'ooffice'
        expect(oo_mime_types).to include(@job.content.mime_type)
      end
      it 'from MS powerpoint' do
        new_job ms_ppt_content
        @processor.libreoffice format: 'ooffice'
        expect(@job.content.mime_type).to eq 'application/vnd.oasis.opendocument.presentation; charset=binary'
      end
    end

    context 'convert to TXT' do
      it 'from MS word' do
        new_job ms_word_content
        @processor.libreoffice format: 'txt'
        expect(@job.content.mime_type).to eq 'text/plain; charset=us-ascii'
      end
      it 'from OO word' do
        new_job oo_word_content
        @processor.libreoffice format: 'txt'
        expect(@job.content.mime_type).to eq 'text/plain; charset=us-ascii'
      end
    end
  end
end
