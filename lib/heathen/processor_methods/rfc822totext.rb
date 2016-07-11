require 'mail'

module Heathen
  class Processor
    def rfc822totext
      expect_mime_type 'message/rfc822'

      mail = Mail.read(job.content_file).without_attachments!
      job.content = mail.to_s
    end
  end
end
