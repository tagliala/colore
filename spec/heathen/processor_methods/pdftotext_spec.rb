require 'spec_helper'

describe Heathen::Processor do
  let(:content) { File.read(fixture('heathen/quickfox.pdf')) }
  let(:job) { Heathen::Job.new 'foo', content, 'en' }
  let(:processor) { described_class.new job: job, logger: Logger.new($stderr) }

  after do
    processor.clean_up
  end

  context '#pdftotext' do
    it 'converts PDF to TXT' do
      processor.pdftotext
      expect(job.content.mime_type).to eq 'text/plain; charset=us-ascii'
    end
  end
end
