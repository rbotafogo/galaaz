# -*- coding: utf-8 -*-

##########################################################################################
# Arrow helpers for Galaaz
# 
# These methods provide a small, Ruby-friendly surface over common R Arrow
# operations (tables, datasets, Feather/Parquet IO). They are thin wrappers
# around the R Arrow package and keep all Arrow data resident in the R process.
##########################################################################################

module R
  module Arrow

    # Build an Arrow table in R from Ruby-produced batches.
    #
    # Input shapes:
    # - Array<Hash>: each hash is a row
    # - Array<Array<Hash>>: each inner array is a row batch
    # - Any Enumerable yielding Hash rows or Array<Hash> batches
    #
    # This keeps batch construction on the Ruby side and creates one R data.frame
    # from the merged column vectors, then converts it to Arrow Table.
    #
    # @param enum_or_array [Enumerable]
    # @return [R::Object] Arrow Table handle in R
    def self.from_ruby_batches(enum_or_array)
      rows = []
      enum_or_array.each do |batch|
        if batch.is_a?(Hash)
          rows << batch
        elsif batch.respond_to?(:each)
          batch.each do |row|
            unless row.is_a?(Hash)
              raise ArgumentError, 'each row must be a Hash'
            end
            rows << row
          end
        else
          raise ArgumentError, 'batches must yield Hash rows or arrays of Hash rows'
        end
      end

      raise ArgumentError, 'from_ruby_batches requires at least one row' if rows.empty?

      keys = rows.flat_map(&:keys).map(&:to_s).uniq
      columns = keys.each_with_object({}) { |k, h| h[k.to_sym] = [] }

      rows.each do |row|
        key_map = row.each_with_object({}) { |(k, v), h| h[k.to_s] = v }
        keys.each { |k| columns[k.to_sym] << key_map[k] }
      end

      df = R::Support.exec_function('data.frame', columns)
      table_from(df)
    end

    # Create an Arrow Table from an R data.frame (or tibble) handle.
    # Uses arrow::as_arrow_table() on the R side.
    #
    # @param r_df [R::DataFrame, R::Object] an R-side data.frame/tibble handle
    # @return [R::Object] handle to an Arrow Table in R
    def self.table_from(r_df)
      R.arrow___as_arrow_table(r_df)
    end

    # Open an Arrow IPC file (written by Galaaz::ArrowIpc or compatible) as an
    # R-side Arrow Table. Materializes the table in R so the Ruby process may
    # unlink the path immediately after this call returns (Stage B1 lifetime).
    #
    # This is IPC/mmap file handoff — not zero-copy shared heap with Ruby.
    #
    # @param path [String] filesystem path visible to the R process
    # @return [R::Object] Arrow Table proxy
    def self.open_ipc(path)
      path = File.expand_path(path.to_s)
      ok = R::Support.eval("requireNamespace('arrow', quietly=TRUE)")
      unless ok == true
        raise LoadError, "R package 'arrow' is required for R::Arrow.open_ipc"
      end

      R.arrow___read_ipc_file(path, as_data_frame: false)
    end

    # Open a Parquet/Feather directory or file as an Arrow Dataset
    # using arrow::open_dataset().
    #
    # @param path [String] file or directory path visible to R
    # @return [R::Object] handle to an Arrow Dataset in R
    def self.dataset(path)
      R.arrow___open_dataset(path)
    end

    # Read a Feather file into an R data.frame/tibble using read_feather().
    #
    # @param path [String]
    # @return [R::DataFrame] Arrow-backed data.frame/tibble in R
    def self.read_feather(path)
      R.arrow___read_feather(path)
    end

    # Write an R data.frame/tibble to a Feather file using write_feather().
    #
    # @param r_df [R::DataFrame, R::Object]
    # @param path [String]
    # @return [nil]
    def self.write_feather(r_df, path)
      R.arrow___write_feather(r_df, path)
      nil
    end

    # Read a Parquet file into an R data.frame/tibble using read_parquet().
    #
    # @param path [String]
    # @return [R::DataFrame] Arrow-backed data.frame/tibble in R
    def self.read_parquet(path)
      R.arrow___read_parquet(path)
    end

    # Write an R data.frame/tibble to a Parquet file using write_parquet().
    #
    # @param r_df [R::DataFrame, R::Object]
    # @param path [String]
    # @return [nil]
    def self.write_parquet(r_df, path)
      R.arrow___write_parquet(r_df, path)
      nil
    end

  end
end

