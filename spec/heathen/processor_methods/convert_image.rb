require 'spec_helper'

describe Heathen::Processor do
  let(:content) { File.read(fixture('heathen/quickfox.jpg')) }
  let(:job) { Heathen::Job.new 'foo', content, 'en' }
  let(:processor) { described_class.new job: job, logger: Logger.new($stderr) }

  after do
    processor.clean_up
  end

  context '#convert_image' do
    it 'converts to tiff' do
      processor.convert_image to: :tiff, params: '-density 72'
      expect(job.content.mime_type).to eq 'image/tiff; charset=binary'
    end
  end
end
