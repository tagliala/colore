require 'spec_helper'

describe Heathen::Processor do
  let(:content) { File.read(fixture('heathen/quickfox.tiff')) }
  let(:job) { Heathen::Job.new 'foo', content, 'en' }
  let(:processor) { described_class.new job: job, logger: Logger.new(nil) }

  after do
    processor.clean_up
  end

  context '#tesseract' do
    it 'converts a tiff to text' do
      processor.tesseract format: nil
      expect(job.content.mime_type).to eq 'text/plain; charset=us-ascii'
    end
    it 'converts a tiff to PDF' do
      processor.tesseract format: 'pdf'
      expect(job.content.mime_type).to eq 'application/pdf; charset=binary'
    end
    it 'converts a tiff to HOCR' do
      processor.tesseract format: 'hocr'
      expect(job.content.mime_type).to eq 'application/xml; charset=us-ascii'
    end
  end
end
