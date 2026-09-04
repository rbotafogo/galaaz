# frozen_string_literal: true

module GknitDiagnostics
  @internal_errors = []

  INTERNAL_MESSAGE_PATTERNS = [
    /undefined method .*R::NewBridgeAdapter/i,
    /Result protocol:/i,
    /invalid connection/i,
    /galaaz_callback_call timeout/i,
    /NewBridge::SessionClient::/i,
    /Unsupported graphics device/i,
    /install job timed out/i,
    /R::Job .+ still running after/i
  ].freeze

  def self.reset!
    @internal_errors = []
  end

  def self.internal_errors
    @internal_errors
  end

  def self.internal_error?(error)
    msg = error.message.to_s
    INTERNAL_MESSAGE_PATTERNS.any? { |rx| rx.match?(msg) }
  end

  def self.record(chunk_label:, error:)
    return unless internal_error?(error)

    @internal_errors << {
      chunk: chunk_label.to_s,
      klass: error.class.to_s,
      message: error.message.to_s
    }
  rescue StandardError
    nil
  end

  def self.print_report(io = $stderr)
    return if @internal_errors.nil? || @internal_errors.empty?

    io.puts
    io.puts 'gknit internal errors detected:'
    @internal_errors.each_with_index do |entry, idx|
      io.puts "  #{idx + 1}) chunk=#{entry[:chunk]} | #{entry[:klass]}: #{entry[:message]}"
    end
  end
end

