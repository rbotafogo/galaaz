# frozen_string_literal: true

module NewBridge
  # Length-prefixed frames: 4-byte little-endian uint32 payload length, then payload.
  module Framing
    class Error < StandardError; end
    class TruncatedFrame < Error; end

    module_function

    def write_frame(io, payload)
      raise Error, 'payload must be String' unless payload.is_a?(String)

      io.write([payload.bytesize].pack('V'))
      io.write(payload)
      io.flush
    end

    def read_frame(io)
      len_bytes = read_exact(io, 4)
      len = len_bytes.unpack1('V')
      raise Error, "invalid frame length #{len}" if len > 256 * 1024 * 1024 # 256 MiB cap for phase 0

      read_exact(io, len)
    end

    def read_exact(io, n)
      buf = +''
      while buf.bytesize < n
        chunk = io.read(n - buf.bytesize)
        raise TruncatedFrame, "expected #{n} bytes, got #{buf.bytesize}" if chunk.nil? || chunk.empty?

        buf << chunk
      end
      buf
    end
    private_class_method :read_exact
  end
end
