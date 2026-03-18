# frozen_string_literal: true

require 'msgpack'

module NewBridge
  # MsgPack-encoded control-plane envelope (see docs/New_Bridge.md).
  module Envelope
    class Error < StandardError; end
    class InvalidEnvelope < Error; end

    REQUIRED_KEYS = %w[call_id type].freeze
    OPTIONAL_KEYS = %w[parent_id payload status session_id].freeze

    module_function

    def encode(hash)
      h = stringify_keys(hash)
      missing = REQUIRED_KEYS - h.keys
      raise InvalidEnvelope, "missing keys: #{missing.join(', ')}" unless missing.empty?

      extra = h.keys - (REQUIRED_KEYS + OPTIONAL_KEYS)
      raise InvalidEnvelope, "unknown keys: #{extra.join(', ')}" unless extra.empty?

      MessagePack.pack(h)
    rescue MessagePack::MalformedFormatError, MessagePack::UnpackError => e
      raise Error, "MsgPack pack failed: #{e.message}"
    end

    def decode(bytes)
      raise InvalidEnvelope, 'empty envelope' if bytes.nil? || bytes.empty?

      h = MessagePack.unpack(bytes)
      unless h.is_a?(Hash)
        raise Error, 'invalid MsgPack envelope: expected a map (Hash)'
      end

      h = stringify_keys(h)
      missing = REQUIRED_KEYS - h.keys
      raise InvalidEnvelope, "missing keys: #{missing.join(', ')}" unless missing.empty?

      h
    rescue MessagePack::MalformedFormatError, MessagePack::UnpackError => e
      raise Error, "invalid MsgPack envelope: #{e.message}"
    end

    def stringify_keys(hash)
      hash.each_with_object({}) { |(k, v), out| out[k.to_s] = v }
    end
    private_class_method :stringify_keys
  end
end
