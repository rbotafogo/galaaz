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

    # Create an Arrow Table from an R data.frame (or tibble) handle.
    # Uses arrow::as_arrow_table() on the R side.
    #
    # @param r_df [R::DataFrame, R::Object] an R-side data.frame/tibble handle
    # @return [R::Object] handle to an Arrow Table in R
    def self.table_from(r_df)
      R.arrow___as_arrow_table(r_df)
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
      R.read_feather(path)
    end

    # Write an R data.frame/tibble to a Feather file using write_feather().
    #
    # @param r_df [R::DataFrame, R::Object]
    # @param path [String]
    # @return [nil]
    def self.write_feather(r_df, path)
      R.write_feather(r_df, path)
      nil
    end

    # Read a Parquet file into an R data.frame/tibble using read_parquet().
    #
    # @param path [String]
    # @return [R::DataFrame] Arrow-backed data.frame/tibble in R
    def self.read_parquet(path)
      R.read_parquet(path)
    end

    # Write an R data.frame/tibble to a Parquet file using write_parquet().
    #
    # @param r_df [R::DataFrame, R::Object]
    # @param path [String]
    # @return [nil]
    def self.write_parquet(r_df, path)
      R.write_parquet(r_df, path)
      nil
    end

  end
end

