require 'digest'

module Colore
  module Utils
    # Deep conversion of all hash keys to symbols.
    def self.symbolize_keys obj
      case obj
        when Hash
          h = {}
          obj.each do |k,v|
            h[k.to_sym] = symbolize_keys v
          end
          h
        when Array
          obj.map{ |o| symbolize_keys o }
        else
          obj
      end
    end

    # Deep conversion of all hash keys to symbols.
    def symbolize_keys obj
      Colore::Utils.symbolize_keys obj
    end
  end
end
