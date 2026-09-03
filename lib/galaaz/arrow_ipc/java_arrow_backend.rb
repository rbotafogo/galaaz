# frozen_string_literal: true

##########################################################################################
# JRuby Arrow IPC writer via Apache Arrow Java.
#
# JAR loading order:
#   1. GALAAZ_ARROW_JARS directory (all *.jar)
#   2. ~/arrow_jars if present
#   3. jar-dependencies require_jar for pinned Arrow 18.1.0 artifacts
##########################################################################################

module Galaaz
  module ArrowIpc
    module JavaArrowBackend
      ARROW_JAVA_VERSION = '18.1.0'

      module_function

      def available?
        return false unless RUBY_ENGINE == 'jruby'

        load_jars!
        true
      rescue LoadError, StandardError
        false
      end

      def write_columns(columns_hash, path)
        load_jars!
        lengths = columns_hash.values.map(&:length).uniq
        raise ArgumentError, "all columns must have the same length (got #{lengths.inspect})" if lengths.size != 1

        n = lengths.first
        alloc = org.apache.arrow.memory.RootAllocator.new(java.lang.Long::MAX_VALUE)
        fields = []
        kinds = {}

        columns_hash.each do |name, values|
          kind = infer_kind(values)
          kinds[name] = kind
          fields << org.apache.arrow.vector.types.pojo.Field.nullable(name, arrow_type(kind))
        end

        schema = org.apache.arrow.vector.types.pojo.Schema.new(fields)
        root = org.apache.arrow.vector.VectorSchemaRoot.create(schema, alloc)

        begin
          columns_hash.each do |name, values|
            fill_vector(root.getVector(name), kinds[name], values, n)
          end
          root.setRowCount(n)

          fos = java.io.FileOutputStream.new(path)
          begin
            channel = java.nio.channels.Channels.newChannel(fos)
            writer = org.apache.arrow.vector.ipc.ArrowFileWriter.new(root, nil, channel)
            begin
              writer.start
              writer.writeBatch
              writer.end
            ensure
              writer.close
            end
          ensure
            fos.close
          end
        ensure
          root.close
          alloc.close
        end
      end

      def load_jars!
        return if defined?(@jars_loaded) && @jars_loaded

        unless RUBY_ENGINE == 'jruby'
          raise LoadError, 'Galaaz::ArrowIpc::JavaArrowBackend requires JRuby'
        end

        loaded = load_jars_from_dir(ENV['GALAAZ_ARROW_JARS'])
        loaded ||= load_jars_from_dir(File.expand_path('~/arrow_jars'))
        loaded ||= load_jars_via_jar_dependencies

        unless loaded
          raise LoadError,
                'Apache Arrow Java JARs not found. Set GALAAZ_ARROW_JARS to a directory of ' \
                "Arrow #{ARROW_JAVA_VERSION} JARs, place them in ~/arrow_jars, or install " \
                'jar-dependencies so require_jar can resolve them.'
        end

        @jars_loaded = true
      end
      private_class_method :load_jars!

      def load_jars_from_dir(dir)
        return false if dir.nil? || dir.empty?
        return false unless File.directory?(dir)

        jars = Dir[File.join(dir, '*.jar')]
        return false if jars.empty?

        jars.each { |jar| require jar }
        true
      end
      private_class_method :load_jars_from_dir

      def load_jars_via_jar_dependencies
        require 'jar-dependencies'
        require_jar 'org.apache.arrow', 'arrow-format', ARROW_JAVA_VERSION
        require_jar 'org.apache.arrow', 'arrow-memory-core', ARROW_JAVA_VERSION
        require_jar 'org.apache.arrow', 'arrow-memory-netty', ARROW_JAVA_VERSION
        require_jar 'org.apache.arrow', 'arrow-memory-unsafe', ARROW_JAVA_VERSION
        require_jar 'org.apache.arrow', 'arrow-vector', ARROW_JAVA_VERSION
        true
      rescue LoadError
        false
      end
      private_class_method :load_jars_via_jar_dependencies

      def arrow_type(kind)
        case kind
        when :float64
          org.apache.arrow.vector.types.pojo.ArrowType::FloatingPoint.new(
            org.apache.arrow.vector.types.FloatingPointPrecision::DOUBLE
          )
        when :int32
          org.apache.arrow.vector.types.pojo.ArrowType::Int.new(32, true)
        when :utf8
          org.apache.arrow.vector.types.pojo.ArrowType::Utf8.new
        else
          raise ArgumentError, "unsupported kind #{kind.inspect}"
        end
      end
      private_class_method :arrow_type

      def fill_vector(vector, kind, values, n)
        vector.allocateNew
        case kind
        when :float64
          values.each_with_index do |v, i|
            if v.nil?
              vector.setNull(i)
            else
              vector.setSafe(i, v.to_f)
            end
          end
        when :int32
          values.each_with_index do |v, i|
            if v.nil?
              vector.setNull(i)
            else
              vector.setSafe(i, Integer(v))
            end
          end
        when :utf8
          values.each_with_index do |v, i|
            if v.nil?
              vector.setNull(i)
            else
              bytes = v.to_s.to_java_bytes
              vector.setSafe(i, bytes)
            end
          end
        end
        vector.setValueCount(n)
      end
      private_class_method :fill_vector

      def infer_kind(values)
        sample = values.find { |v| !v.nil? }
        return :float64 if sample.nil?

        case sample
        when Float
          :float64
        when Integer
          values.any? { |v| v.is_a?(Float) } ? :float64 : :int32
        when String, Symbol
          :utf8
        when TrueClass, FalseClass
          raise ArgumentError, 'boolean columns are not supported in B1 (use int32/float64/utf8)'
        else
          if sample.is_a?(Numeric)
            sample.is_a?(Integer) ? :int32 : :float64
          else
            :utf8
          end
        end
      end
      private_class_method :infer_kind
    end
  end
end
