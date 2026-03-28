# frozen_string_literal: true

# Phase 0: envelope (MsgPack), framing, TCP echo, Rcpp load smoke test.
# Run: bundle exec rspec specs/new_bridge/phase0_protocol_spec.rb

require 'open3'
require 'tempfile'

root = File.expand_path('../..', __dir__)
$LOAD_PATH.unshift(File.join(root, 'lib')) unless $LOAD_PATH.include?(File.join(root, 'lib'))

require 'new_bridge'

RSpec.describe 'NewBridge Phase 0' do
  describe NewBridge::Envelope do
    let(:sample) do
      {
        'call_id' => '550e8400-e29b-41d4-a716-446655440000',
        'parent_id' => nil,
        'type' => 'REQ',
        'payload' => '1 + 1',
        'status' => nil
      }
    end

    it 'round-trips encode/decode' do
      bytes = described_class.encode(sample)
      out = described_class.decode(bytes)
      expect(out['call_id']).to eq(sample['call_id'])
      expect(out['type']).to eq('REQ')
      expect(out['payload']).to eq('1 + 1')
    end

    it 'raises on invalid MsgPack' do
      expect { described_class.decode("\xff\xff\xff") }.to raise_error(NewBridge::Envelope::Error, /invalid MsgPack/)
    end

    it 'raises on missing required keys' do
      bad = MessagePack.pack('foo' => 'bar')
      expect { described_class.decode(bad) }.to raise_error(NewBridge::Envelope::InvalidEnvelope, /missing keys/)
    end
  end

  describe NewBridge::Framing do
    it 'writes and reads one frame' do
      io = StringIO.new(+'', 'r+')
      payload = NewBridge::Envelope.encode(
        'call_id' => 'a',
        'type' => 'REQ',
        'payload' => 'x'
      )
      described_class.write_frame(io, payload)
      io.rewind
      back = described_class.read_frame(io)
      expect(back).to eq(payload)
    end

    it 'raises TruncatedFrame on short length prefix' do
      io = StringIO.new("\x02\x00\x00\x00a", 'r') # length 2, only 1 byte body
      expect { described_class.read_frame(io) }.to raise_error(NewBridge::Framing::TruncatedFrame)
    end
  end

  describe NewBridge::TcpFramed do
    it 'echoes one framed payload over TCP' do
      payload = NewBridge::Envelope.encode('call_id' => 'b', 'type' => 'REQ', 'payload' => 'ok')
      NewBridge::TcpFramed.with_echo_server do |port|
        back = NewBridge::TcpFramed.send_receive('127.0.0.1', port, payload)
        expect(back).to eq(payload)
      end
    end
  end

  describe 'Rcpp phase0 skeleton' do
    cpp_path = File.expand_path('../ext/new_bridge/galaaz_gatekeeper_phase0.cpp', __dir__)

    it 'loads via sourceCpp and runs galaaz_poll / galaaz_shutdown without hanging' do
      skip 'R not on PATH' unless system('command -v R >/dev/null 2>&1')

      cpp = cpp_path.gsub("'", "\\\\'")
      r_script = <<~R
        stopifnot(requireNamespace("Rcpp", quietly = TRUE))
        library(Rcpp)
        sourceCpp("#{cpp}")
        p <- galaaz_poll()
        stopifnot(length(p) == 0L)
        galaaz_shutdown()
        cat("PHASE0_RCPP_OK\\n")
      R

      stdout, stderr, status = Open3.capture3('R', '--slave', '--no-save', '-e', r_script)
      expect(status.success?).to eq(true), "R failed:\nSTDOUT:\n#{stdout}\nSTDERR:\n#{stderr}"
      expect(stdout).to include('PHASE0_RCPP_OK')
    end
  end
end
