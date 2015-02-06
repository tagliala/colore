require 'spec_helper'
require 'autoheathen'

describe AutoHeathen::EmailProcessor do
  let(:processor) {
    AutoHeathen::EmailProcessor.new( {
        cc_blacklist: [ 'wikilex@ifad.org' ],
      }, fixture('autoheathen/autoheathen.yml' ) )
  }
  let!(:email_to) { 'bob@localhost.localdomain' }
  let(:email) {
    m = Mail.read( fixture('autoheathen/test1.eml') )
    m.to [ email_to ]
    m.from [ 'bob@deviant.localdomain' ]
    m.cc [ 'mrgrumpy', 'marypoppins', email_to, 'wikilex@ifad.org' ]
    m.return_path [ 'jblackman@debian.localdomain' ]
    m.header['X-Received'] = 'misssilly'
    m
  }

  it 'initializes' do
    expect(processor.cfg).to be_a Hash
    expect(processor.logger).to be_a Logger
    expect(processor.cfg[:from]).to eq 'noreply@ifad.org' # from config file
    expect(processor.cfg[:mail_host]).to_not be_nil
    expect(processor.cfg[:mail_port]).to_not be_nil
    expect(processor.cfg[:text_template]).to_not be_nil
    expect(processor.cfg[:html_template]).to_not be_nil
  end

  it 'sends email onwards' do
    to_address = 'bob@foober'
    expect(processor).to receive(:deliver) do |mail|
      expect(mail.from).to eq email.from
      expect(mail.to).to eq [to_address]
      expect(mail.subject).to eq "Fwd: Convert: please"
      expect(mail.attachments.size).to eq 2 # includes unconvertable attachment
      expect(mail.attachments.map(&:filename)).to match_array %w[ test1.doc quickfox.pdf ]
      expect(mail.delivery_method.settings[:port]).to eq 25
      expect(mail.delivery_method.settings[:address]).to eq 'localhost'
      expect(mail.cc).to be_nil # non-rts should not forward converted docs to anybody else
      #
      # All headers that sharepoint might not like should be removed
      #
      expect(mail.return_path).to be_nil
      expect(mail.header['X-Received']).to be_nil
      expect(mail.header['Message-ID'].to_s).to eq ''
    end
    processor.process email, to_address
  end

  it 'returns to sender' do
    expect(processor).to receive(:deliver) do |mail|
      expect(mail.from).to eq ['noreply@ifad.org']
      expect(mail.to).to eq email.from
      expect(mail.subject).to eq "Re: Fwd: Convert: please"
      expect(mail.attachments.size).to eq 1 # does not include unconvertable attachment
      expect(mail.text_part.decoded.size).to be > 0
      expect(mail.html_part.decoded.size).to be > 0
      expect(mail.delivery_method.settings[:port]).to eq 25
      expect(mail.delivery_method.settings[:address]).to eq 'localhost'
      expect(mail.cc).to eq [ 'mrgrumpy', 'marypoppins' ] # Test to exclude email_to & blacklist
      expect(mail.return_path).to eq 'jblackman@debian.localdomain'
      expect(mail.header['X-Received'].to_s).to eq 'misssilly'
    end
    processor.process_rts email
  end

  it 'blacklist-addres from CC list in rts' do
    expect(processor).to receive(:deliver) do |mail|
      expect(mail.cc).to eq [] # Test to exclude email_to when it's the only cc
    end
    email.cc email_to
    processor.process_rts email
  end

  it 'reads a file' do
    expect(processor.read_file('spec/fixtures/autoheathen/autoheathen.yml').to_s).to_not eq ''
  end

  it 'validates content types' do
    expect(processor.get_action 'image/tiff').to eq 'ocr'
    expect(processor.get_action 'application/pdf; charset=utf-8').to eq 'ocr'
    expect(processor.get_action 'application/msword').to eq 'pdf'
    expect{processor.get_action 'foobar'}.to raise_error(RuntimeError)
  end

end
