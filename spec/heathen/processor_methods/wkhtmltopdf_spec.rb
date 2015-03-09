require 'spec_helper'

describe Heathen::Processor do
  let(:content) { File.read(fixture('heathen/quickfox.html')) }
  let(:job) { Heathen::Job.new 'foo', content, 'en' }
  let(:processor) { described_class.new job: job, logger: Logger.new($stderr) }

  after do
    processor.clean_up
  end

  context '#wkhtmltopdf' do
    it 'converts HTML to PDF' do
      processor.wkhtmltopdf
      expect(job.content.mime_type).to eq 'application/pdf; charset=binary'
    end
  end
end
