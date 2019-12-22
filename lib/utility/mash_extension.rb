# encoding: UTF-8
require File.expand_path 'array_extension', File.dirname(__FILE__)

module Hashie
  # A Hashie Hash is simply a Hash that has convenience
  # functions baked in such as stringify_keys that may
  # not be available in all libraries.
  class Hash < ::Hash
    #include Hashie::HashExtensions

    # Converts a mash back to a hash.
    def to_hash(options = {})
      out = {}
      keys.each do |k|
        #key = options[:symbolize_keys] ? k.to_sym : k.to_s
        if options[:symbolize_keys] || options[:symbolize_names] then
          key = k.to_sym
        else
          key = k.to_s
        end
        #out[key] = Hashie::Hash === self[k] ? self[k].to_hash : self[k]
        if Hashie::Hash === self[k] then
          out[key] = self[k].to_hash(options)
        else
          if self[k].is_a?(Array) then
            out[key] = self[k].to_hash(options)
          else
            out[key] = self[k]
          end
        end
      end
      return out
    end

  end

end
