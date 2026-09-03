# frozen_string_literal: true

require 'rbconfig'

##########################################################################################
# CRuby Arrow IPC writer via red-arrow (gem "arrow").
##########################################################################################

module Galaaz
  module ArrowIpc
    module RedArrowBackend
      module_function

      def available?
        load!
        true
      rescue LoadError, StandardError
        false
      end

      def write_columns(columns_hash, path)
        load!
        lengths = columns_hash.values.map(&:length).uniq
        raise ArgumentError, "all columns must have the same length (got #{lengths.inspect})" if lengths.size != 1

        table_hash = {}
        columns_hash.each do |name, values|
          table_hash[name] = build_array(name, values)
        end
        table = ::Arrow::Table.new(table_hash)
        table.save(path)
      end

      def read_columns(path)
        load!
        table = ::Arrow::Table.load(path)
        table.schema.fields.each_with_object({}) do |field, out|
          col = table[field.name]
          values = col.respond_to?(:to_a) ? col.to_a : col.data.to_a
          out[field.name] = values
        end
      end

      def load!
        return if defined?(@loaded) && @loaded

        begin
          require 'arrow'
        rescue LoadError
          prepend_user_red_arrow_load_path!
          begin
            require 'arrow'
          rescue LoadError => e
            raise LoadError,
                  "Galaaz::ArrowIpc on CRuby requires the red-arrow gem " \
                  "(gem install red-arrow, matching pkg-config arrow-glib). #{e.message}"
          end
        end
        @loaded = true
      end
      private_class_method :load!

      # bundle exec only exposes Gemfile gems; red-arrow is optional and often
      # user-installed. Put its lib + native extension on $LOAD_PATH.
      def prepend_user_red_arrow_load_path!
        names = '{red-arrow,gobject-introspection,glib2,gio2,native-package-installer,pkg-config,extpp}'
        roots = []
        roots << Gem.user_dir if Gem.respond_to?(:user_dir)
        rubylibdir = RbConfig::CONFIG['rubylibdir']
        if rubylibdir
          roots << File.join(File.dirname(rubylibdir), 'gems', RbConfig::CONFIG['ruby_version'])
        end
        roots.concat(Array(Gem.path))
        roots.compact.uniq.each do |root|
          next unless File.directory?(root)

          Dir.glob(File.join(root, 'gems', "#{names}-*", 'lib')).sort.each do |lib|
            $LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
          end
          Dir.glob(File.join(root, 'extensions', '**', "#{names}-*")).select { |p| File.directory?(p) }.sort.each do |ext|
            $LOAD_PATH.unshift(ext) unless $LOAD_PATH.include?(ext)
          end
        end
      end
      private_class_method :prepend_user_red_arrow_load_path!

      def build_array(name, values)
        kind = infer_kind(values)
        case kind
        when :float64
          ::Arrow::DoubleArray.new(values.map { |v| v.nil? ? nil : v.to_f })
        when :int32
          ::Arrow::Int32Array.new(values.map { |v| v.nil? ? nil : Integer(v) })
        when :utf8
          ::Arrow::StringArray.new(values.map { |v| v.nil? ? nil : v.to_s })
        else
          raise ArgumentError, "unsupported column type for #{name.inspect}"
        end
      end
      private_class_method :build_array

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
          if sample.respond_to?(:to_f) && sample.is_a?(Numeric)
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
