require 'spec_helper'
require 'heathen'

class Heathen::Processor
  def valid_step_1
    job.content << ",step 1"
  end
  def valid_step_2
    job.content << ",step 2"
  end
  def failing_step_1
    raise "It failed"
  end
end


describe Heathen::Converter do
  before do
    Heathen::Task.clear
  end

  it 'runs a successful task' do
    Heathen::Task.register 'test', 'text/plain' do |job|
      valid_step_1
      valid_step_2
    end
    result = described_class.new.convert 'test', 'test content'
    expect(result).to eq 'test content,step 1,step 2'
  end

  it 'finds and runs based on pattern' do
    Heathen::Task.register 'test', 'text/.*' do |job|
      valid_step_1
      valid_step_2
    end
    result = described_class.new.convert 'test', 'test content'
    expect(result).to eq 'test content,step 1,step 2'
  end

  it 'fails with an unsuccessful step' do
    Heathen::Task.register 'test', 'text/plain' do |job|
      valid_step_1
      failing_step_1
    end
    expect {
      described_class.new.convert 'test', 'test content'
    }.to raise_error
  end

  it 'runs a nested task' do
    Heathen::Task.register 'test_nested', 'text/plain' do |job|
      valid_step_1
    end
    Heathen::Task.register 'test', 'text/plain' do |job|
      perform_task 'test_nested'
      valid_step_2
    end
    result = described_class.new.convert 'test', 'test content'
    expect(result).to eq 'test content,step 1,step 2'
  end

  it 'fails if the task is not recognised' do
    Heathen::Task.register 'test', 'text/plain' do |job|
      valid_step_1
      valid_step_2
    end
    expect {
      described_class.new.convert 'test_foo', 'test content'
    }.to raise_error
  end

  it 'fails if the mime_type is not recognised' do
    Heathen::Task.register 'test', 'image/jpeg' do |job|
      valid_step_1
      valid_step_2
    end
    expect {
      described_class.new.convert 'test', 'test content'
    }.to raise_error
  end
end
