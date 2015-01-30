module Colore
  class DocKey
    attr_accessor :app
    attr_accessor :doc_id

    def self.parse doc_key_str
      self.new *(doc_key_str.split '/')
    end

    def initialize app, doc_id
      validate(app)
      validate(doc_id)
      @app = app
      @doc_id = doc_id
    end

    def path
      Pathname.new(app) + doc_id
    end

    def to_s
      path
    end

    def validate val
      raise InvalidParameter.new unless val =~ /^[A-Za-z0-9_-]+$/
    end
  end
end
