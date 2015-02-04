module Colore
  class Error < StandardError
    attr_accessor :http_code
    def initialize http_code, message
      super message
      @http_code = http_code
    end
  end
  class InvalidParameter < Error
    def initialize; super 400, 'Invalid parameter'; end
  end
  class DocumentExists < Error
    def initialize; super 409, 'A document with this doc_id already exists'; end
  end
  class DocumentNotFound < Error
    def initialize; super 400, 'Document not found'; end
  end
  class VersionNotFound < Error
    def initialize; super 400, 'Version not found'; end
  end
  class InvalidVersion < Error
    def initialize; super 400, 'Invalid version name'; end
  end
  class VersionIsCurrent < Error
    def initialize; super 400, 'Version is current, change current version first'; end
  end
  class InvalidFormat < StandardError
    def initialize; super 400, 'Invalid format'; end
  end
  class FileNotFound < Error
    def initialize; super 400, 'Requested file not found'; end
  end
end
