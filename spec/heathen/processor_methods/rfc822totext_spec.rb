require 'spec_helper'

describe Heathen::Processor do
  let(:content) { File.read(fixture('heathen/email.eml')) }
  let(:job) { Heathen::Job.new 'foo', content, 'en' }
  let(:processor) { described_class.new job: job, logger: Logger.new($stderr) }

  before do
    allow(content).to receive(:mime_type).and_return('message/rfc822')
  end

  after do
    processor.clean_up
  end

  context '#rfc822totext' do
    it 'strips attachments' do
      processor.rfc822totext
      expect(job.content.mime_type).to eq 'message/rfc822; charset=us-ascii'
      expect(job.content).to_not include('reports.csv')
    end
  end
end
