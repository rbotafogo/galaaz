# frozen_string_literal: true

require 'socket'
require_relative 'framing'

module NewBridge
  # Minimal TCP client/server for framed byte payloads (Phase 0).
  module TcpFramed
    class Error < StandardError; end

    module_function

    # Yields bound port; server echoes one frame then closes.
    def with_echo_server(host: '127.0.0.1')
      server = TCPServer.new(host, 0)
      port = server.addr[1]
      thread = Thread.new do
        client = server.accept
        begin
          payload = Framing.read_frame(client)
          Framing.write_frame(client, payload)
        ensure
          client.close rescue nil
        end
      ensure
        server.close rescue nil
      end
      yield port
    ensure
      thread&.join(5)
      server&.close rescue nil
    end

    def send_receive(host, port, payload)
      sock = TCPSocket.new(host, port)
      begin
        Framing.write_frame(sock, payload)
        Framing.read_frame(sock)
      ensure
        sock.close
      end
    end
  end
end
