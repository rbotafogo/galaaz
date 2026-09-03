# frozen_string_literal: true

require 'fileutils'
require 'securerandom'
require 'tmpdir'

##########################################################################################
# Stage B: Ruby ↔ R Arrow IPC file handoff (B1 ingest, B2 export).
#
# NewBridge carries only the path. This is IPC/mmap file handoff — not zero-copy
# shared heap between Ruby and R.
##########################################################################################

module Galaaz
  class ArrowIpcError < StandardError; end

  module ArrowIpc
    module_function

    # @return [Boolean] true when the current Ruby engine's Arrow backend can load
    def available?
      backend.available?
    rescue StandardError
      false
    end

    # Write columnar data to an Arrow IPC file.
    #
    # @param columns_hash [Hash{String,Symbol => Array}] column name → values
    # @return [String] absolute path to the IPC file (fsync'd / closed)
    def write(columns_hash)
      raise ArgumentError, 'columns_hash must be a Hash' unless columns_hash.is_a?(Hash)
      raise ArgumentError, 'columns_hash must not be empty' if columns_hash.empty?

      normalized = normalize_columns(columns_hash)
      path = next_path
      backend.write_columns(normalized, path)
      fsync_path(path)
      path
    end

    # Convenience: Array of row Hashes → columnar write.
    #
    # @param row_hashes [Enumerable<Hash>]
    # @return [String] path
    def write_batches(row_hashes)
      rows = []
      row_hashes.each do |row|
        raise ArgumentError, 'each row must be a Hash' unless row.is_a?(Hash)

        rows << row
      end
      raise ArgumentError, 'write_batches requires at least one row' if rows.empty?

      keys = rows.flat_map(&:keys).map(&:to_s).uniq
      columns = keys.each_with_object({}) { |k, h| h[k] = [] }
      rows.each do |row|
        key_map = row.each_with_object({}) { |(k, v), h| h[k.to_s] = v }
        keys.each { |k| columns[k] << key_map[k] }
      end
      write(columns)
    end

    # Read an Arrow IPC file into a column hash (String keys → Arrays).
    # B2 types: float64, int32/int64, utf8 (nulls preserved).
    #
    # @param path [String]
    # @return [Hash{String => Array}]
    def read(path)
      path = File.expand_path(path.to_s)
      raise ArgumentError, "Arrow IPC file not found: #{path}" unless File.file?(path)

      backend.read_columns(path)
    end

    # Read an Arrow IPC file as an Array of row Hashes (symbol keys).
    #
    # @param path [String]
    # @return [Array<Hash>]
    def read_batches(path)
      columns = read(path)
      raise ArgumentError, 'IPC file has no columns' if columns.empty?

      n = columns.values.map(&:length).uniq
      raise ArgumentError, "ragged columns after read: #{n.inspect}" if n.size != 1

      n.first.times.map do |i|
        columns.each_with_object({}) { |(name, values), row| row[name.to_sym] = values[i] }
      end
    end

    # Unique scratch path for a new IPC file (used by R::Arrow.write_ipc when path omitted).
    #
    # @return [String]
    def allocate_path
      File.join(scratch_dir, "galaaz_ipc_#{Process.pid}_#{SecureRandom.hex(8)}.arrow")
    end

    # Unlink an IPC scratch file if present.
    #
    # @param path [String]
    # @return [void]
    def release(path)
      return if path.nil? || path.to_s.empty?

      File.unlink(path) if File.exist?(path)
    rescue Errno::ENOENT
      nil
    end

    # Prefer /dev/shm when writable; else Dir.tmpdir / gem tmp.
    #
    # @return [String]
    def scratch_dir
      @scratch_dir ||= begin
        candidates = []
        candidates << '/dev/shm' if File.directory?('/dev/shm')
        candidates << File.join(Dir.tmpdir, 'galaaz_arrow_ipc')
        candidates << File.expand_path('../../../tmp/galaaz_arrow_ipc', __dir__)

        chosen = candidates.find do |dir|
          begin
            FileUtils.mkdir_p(dir)
            File.writable?(dir)
          rescue StandardError
            false
          end
        end
        raise ArrowIpcError, 'no writable scratch directory for Arrow IPC' unless chosen

        chosen
      end
    end

    # @return [Module] RedArrowBackend or JavaArrowBackend
    def backend
      @backend ||=
        if RUBY_ENGINE == 'jruby'
          require_relative 'arrow_ipc/java_arrow_backend'
          JavaArrowBackend
        else
          require_relative 'arrow_ipc/red_arrow_backend'
          RedArrowBackend
        end
    end

    def normalize_columns(columns_hash)
      columns_hash.each_with_object({}) do |(name, values), out|
        key = name.to_s
        raise ArgumentError, "column #{key.inspect} values must be an Array" unless values.is_a?(Array)

        out[key] = values
      end
    end
    private_class_method :normalize_columns

    def next_path
      allocate_path
    end
    private_class_method :next_path

    def fsync_path(path)
      File.open(path, 'rb') { |f| f.fsync }
    end
    private_class_method :fsync_path
  end
end
