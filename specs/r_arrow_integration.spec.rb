# -*- coding: utf-8 -*-

##########################################################################################
# @author Rodrigo Botafogo
#
# Copyright © 2025 Rodrigo Botafogo. All Rights Reserved. Permission to use, copy, modify,
# and distribute this software and its documentation, without fee and without a signed
# licensing agreement, is hereby granted, provided that the above copyright notice, this
# paragraph and the following two paragraphs appear in all copies, modifications, and
# distributions.
#
# IN NO EVENT SHALL RODRIGO BOTAFOGO BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL,
# INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST PROFITS, ARISING OUT OF THE USE OF
# THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF RODRIGO BOTAFOGO HAS BEEN ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# RODRIGO BOTAFOGO SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
# SOFTWARE AND ACCOMPANYING DOCUMENTATION, IF ANY, PROVIDED HEREUNDER IS PROVIDED "AS IS".
# RODRIGO BOTAFOGO HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS,
# OR MODIFICATIONS.
##########################################################################################

require 'galaaz'

describe "R Arrow integration" do

  #----------------------------------------------------------------------------------------
  context "Arrow tables created via R module" do

    it "creates an Arrow table from an R data.frame using Arrow helpers" do
      df = R.data__frame(x: (1..3), y: (3..1))

      # as_arrow_table() lives in the arrow package; call it via the Arrow helper.
      tbl = R::Arrow.table_from(df)

      # The returned object should be an R handle whose class on the R side
      # includes "Table" from the Arrow package.
      expect(tbl.rclass.split(' ')).to include("Table")
    end

  end

  #----------------------------------------------------------------------------------------
  context "Feather roundtrip driven from Ruby" do

    it "writes and reads a Feather file using Arrow helpers" do
      path = "/dev/shm/galaaz_arrow_integration_test.feather"

      df1 = R.data__frame(
        x: (1..5),
        y: (~:letters)[(1..5)]
      )

      # Use the Arrow helpers so Ruby code is concise and Arrow-aware.
      R::Arrow.write_feather(df1, path)
      df2 = R::Arrow.read_feather(path)

      # Verify basic structure and a few values through galaaz accessors.
      # read_feather() usually returns a tibble (tbl_df, tbl, data.frame);
      # we only require that it is a data.frame-like object with expected content.
      expect(df2.names).to eq R.c("x", "y")
      expect(df2.nrow >> 0).to eq 5
      expect(df2.rclass.split(' ')).to include("tbl_df").or include("data.frame")

      # Check that the first column behaves like an integer vector and the second like character.
      x_col = df2[[1]]
      y_col = df2[[2]]

      expect(x_col.rclass).to eq "integer"
      expect(y_col.rclass).to eq "character"

      expect(x_col[1]).to eq 1
      expect(x_col[5]).to eq 5
      expect(y_col[1]).to eq "a"
      expect(y_col[5]).to eq "e"

    end

  end

  #----------------------------------------------------------------------------------------
  # Arrow dataset and dplyr-style pipeline
  #
  # NSE RULES (applied uniformly to any data.frame-like backend, including Arrow):
  #
  # - Always pass the data as the first argument to dplyr verbs:
  #     R.dplyr___group_by(df, :group)
  #     R.dplyr___summarise(df, total: E.sum(:value))
  #
  # - Pass column expressions using the E module: E.sum(:col), E.mean(:col), E.n, etc.
  #   The E module creates unevaluated R expressions (R::Language objects) that
  #   dplyr can evaluate in the data mask. Do NOT use R.sum(:col) (evaluates immediately
  #   in global env) and do NOT use ~:col (triggers early evaluation).
  #
  # - These rules are backend-agnostic: they work for data.frames, tibbles and
  #   Arrow datasets, because dplyr provides the same data-mask semantics for all.
  #
  context "Arrow dataset and dplyr-style pipeline" do

    before(:all) do
      # Ensure dplyr (and arrow, if needed) are available in the R session.
      R.install_and_loads("dplyr", "arrow")
    end

    it "opens a small Parquet dataset and runs a grouped aggregation (using NSE)" do
      path = "/dev/shm/galaaz_arrow_integration_test.parquet"

      # Create a small data.frame in R and persist it as Parquet via Arrow.
      df = R.data__frame(
        group: R.c("a", "a", "b", "b"),
        value: R.c(1, 2, 3, 4)
      )

      R::Arrow.write_parquet(df, path)

      # Open as an Arrow Dataset and run a simple group_by/summarise pipeline.
      ds = R::Arrow.dataset(path)

      # Use dplyr via the R module with the same NSE rules we use for regular
      # data.frames: data is the first argument, and column expressions are
      # passed via the E module (E.sum(:col), E.mean(:col), etc.) inside the
      # verb call. The E module creates unevaluated expressions that dplyr
      # resolves in the data mask.
      #
      # Note: use dplyr___group_by (one underscore before by), not
      # dplyr___group__by, to get dplyr::group_by. The double underscore
      # pattern creates a dot (group.by) which is wrong.
      grouped = R.dplyr___group_by(ds, :group)
      summed  = R.dplyr___summarise(grouped, total: E.sum(:value))

      # Collect the result back into an R data.frame/tibble.
      result = R.dplyr___collect(summed)

      # There should be one row per group with the correct sums:
      # group "a": 1 + 2 = 3, group "b": 3 + 4 = 7.
      expect(result.nrow >> 0).to eq 2

      groups = result[['group']]
      totals = result[['total']]

      # Order of groups is not strictly guaranteed, so we assert set-wise.
      pairs = (1..(result.nrow >> 0)).map do |i|
        [groups[i], totals[i]]
      end

      expect(pairs).to contain_exactly(["a", 3], ["b", 7])
    end

  end

end

