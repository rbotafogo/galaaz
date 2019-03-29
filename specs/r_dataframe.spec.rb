# -*- coding: utf-8 -*-

##########################################################################################
# @author Rodrigo Botafogo
#
# Copyright © 2018 Rodrigo Botafogo. All Rights Reserved. Permission to use, copy, modify, 
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

describe R::DataFrame do

  #----------------------------------------------------------------------------------------
  context "Create DataFrame" do

    it "should create a dataframe from a vector" do
      vec = R.seq(6)
      vec.dim = R.c(2, 3)
      
      # create a DataFrame from a vector
      df = vec.as__data__frame
      expect(df[1, "V1"]).to eq 1
      expect(df[1, 'V2']).to eq 3
      # When you extract a single row from a data frame you get a one-row data frame.
      # Convert it to a numeric vector with 'as__numeric'
      expect(df[1, :all].as__numeric).to eq R.c(1.0, 3, 5)
    end

  end

  #----------------------------------------------------------------------------------------
  context "Subsetting" do
    
    it "should do integer subsetting" do
      grades = R.c(1.0, 2.0, 2.0, 3.0, 1.0)
      
      info = R.data__frame(
        grade: (3..1),
        desc: R.c("Excellent", "Good", "Poor"),
        fail: R.c(false, false, true)
      )
      
      id = R.match(grades, info.grade)
      table = info[id, :all]
      
      expect(table.grade[1]).to eq 1
      expect(table.desc.levels[2]).to eq "Good"
      expect(table.fail[4]).to eq false
      
      info.rownames = info.grade
      table2 = info[grades.as__character, :all]
      
      expect(table2.grade[2]).to eq 2
      expect(table2.desc.levels[1]).to eq "Excellent"
      expect(table2.fail[4]).to eq true
      
    end

  end

  #----------------------------------------------------------------------------------------
  context "Subsetting with '['" do

    before(:each) do
      @mtcars = ~:mtcars
    end

    it "should subset with [ with only the column index" do
      slice = @mtcars[1]
      expect(slice.typeof).to eq "list"
      expect(slice.rclass).to eq "data.frame"
      expect(slice.length).to eq 1
      expect(slice[[1]][1]).to eq 21.0
      expect(slice[[1, 1]]).to eq 21.0
      # undefined columns selected (RError)
      expect { slice['Mazda RX4'] }.to raise_error(RuntimeError)
      expect(slice[['Mazda RX4']]).to eq nil
    end
    
    it "should subset with [ with a column range" do
      slice = @mtcars[(1..3)]
      expect(slice.typeof).to eq "list"
      expect(slice.rclass).to eq "data.frame"
      expect(slice.length).to eq 3
      expect(slice[[2]][10]).to eq 6.0
      expect(slice[10, 2]).to eq 6.0
    end

    it "should subset with [ by row and column indices" do
      expect(@mtcars[1, 1]).to eq 21.0
      expect(@mtcars[6, 5]).to eq 2.76
    end

    it "do not use R style missing value idexing with [" do
      # This array bellow is equivalent to [6]. This can bring some surprises for
      # R people that are used to this indexing notation, as in this case the ','
      # is ignored
      arr = [6, ]
      expect(arr).to eq [6]
      
      # This will output the sixth column of the mtcars dataframe
      slice = @mtcars[6, ]
      expect(slice.typeof).to eq "list"
      expect(slice.rclass).to eq "data.frame"
      expect(slice.length).to eq 1
      expect(slice[[1]][1]).to eq 2.62
    end

    it "should subset with [ by row index and :all" do
      # Hornet Sportabout 18.7   8 360.0 175 3.15 3.440 17.02  0  0    3    2      
      slice = @mtcars[5, :all]
      expect(slice.rclass).to eq "data.frame"
      expect(slice[1, 1]).to eq 18.7
      expect(slice[1, 1]).not_to eq 360.0
      expect(slice.names).to eq R.c("mpg", "cyl", "disp", "hp", "drat",
                                    "wt", "qsec", "vs", "am", "gear", "carb")
    end

    it "should subset with [ by row index, :all and allowing for drop parameter" do
      # will transform the data into a list
      lst = @mtcars[1, :all, drop: true]
      expect(lst.typeof).to eq "list"
      expect(lst[[1]]).to eq 21.0
      expect(lst[1]).to eq R.list(mpg: 21.0)
    end

    it "should subset with [ by :all and column index" do
      # [1] 110 110  93 110 175 105 245  62  95 123 123 180 180 180 205 215 230  66  52
      # [20]  65  97 150 150 245 175  66  91 113 264 175 335 109
      slice = @mtcars[:all, 4]
      expect(slice.rclass).to eq "numeric"
      expect(slice.typeof).to eq "double"
      expect(slice[10]).to eq 123.0
    end

    it "should subset with [ by :all, column index and allowing for 'drop' parameter" do
      expect(@mtcars[:all, 1]).to eq @mtcars[:all, 1, drop: true]
    end

    it "should subset with [ and column name" do
      slice = @mtcars['drat']
      expect(slice.typeof).to eq "list"
      expect(slice.rclass).to eq "data.frame"
      expect(slice.length).to eq 1
      expect(slice[[1]][1]).to eq 3.90
      expect(slice[[1, 1]]).to eq 3.90
      # undefined columns selected (RError)
      expect { slice['Mazda RX4'] }.to raise_error(RuntimeError)
      expect(slice[['Mazda RX4']]).to eq nil
    end

    it "should subset with [ and row name" do
      slice = @mtcars['Merc 450SE', :all]
      expect(slice[[1]]).to eq 16.4
      expect(slice[['hp']]).to eq 180.0
    end

    it "should subset with [ and row and column name" do
      slice = @mtcars['Merc 450SL', 'drat']
      expect(slice).to eq 3.07
    end
    
  end
  
  #----------------------------------------------------------------------------------------
  context "Subsetting with '[['" do

    before(:each) do
      @mtcars = ~:mtcars
    end

    it "should subset with [[ and a column index" do
      slice = @mtcars[[1]]
      expect(slice.typeof).to eq "double"
      expect(slice.rclass).to eq "numeric"
      expect(slice[1]).to eq 21.0
      expect(slice[16]).to eq 10.4
    end

    it "should subset with [[ and a row index" do
      slice = @mtcars
    end

    it "should subset with [[ and row and column indices" do
      expect(@mtcars[[6, 1]]).to eq 18.1
      expect(@mtcars[[6, 5]]).to eq 2.76
      expect(@mtcars[[15, 1]]).to eq 10.4
      expect(@mtcars[[15, 7]]).to eq 17.98
    end

    it "should subset with [[ and row and column names" do
      expect(@mtcars[['Valiant', 'mpg']]).to eq 18.1
      expect(@mtcars[['Valiant', 'drat']]).to eq 2.76
      expect(@mtcars[['Cadillac Fleetwood', 'mpg']]).to eq 10.4
      expect(@mtcars[['Cadillac Fleetwood', 'qsec']]).to eq 17.98
    end

  end
  
  #----------------------------------------------------------------------------------------
  context "Assigning with '[<-'" do

    before(:each) do
      @mtcars = ~:mtcars
    end

    it "should add a column to a dataframe indexing by column" do
      @mtcars["New Column"] = R.c((1..32))
      expect(@mtcars[[1, 12]]).to eq 1
      expect(@mtcars[['Mazda RX4', 'New Column']]).to eq 1
    end

    it "should add a column to a dataframe indexing with :all in the row" do
      @mtcars[:all, 'New Column'] = R.c((1..32))
      expect(@mtcars[[1, 12]]).to eq 1
      expect(@mtcars[['Mazda RX4', 'New Column']]).to eq 1
    end
    
    it "should assign to an element of a dataframe indexing with row and column by number" do
      @mtcars[17, 6] = 1000
      expect(@mtcars[[17, 6]]).to eq 1000.0
      expect(@mtcars[['Chrysler Imperial', 'wt']]).to eq 1000.0
    end

    it "should assign to a range" do
      @mtcars[(10..12)] = R.list((1..32), nil, "New Col": R.c(32..1))
      expect(@mtcars[['Fiat 128', 'gear']]).to eq 18
      expect(@mtcars[['Chrysler Imperial', 'New Col']]).to eq 16
    end

  end
  
  #----------------------------------------------------------------------------------------
  context "Ruby 'each'" do
    
    it "should do 'each_column'" do
      
      mtcars = ~:mtcars
      
      mtcars.each_column do |col, col_name|
        # col_name a Ruby string with the column name
        case col_name
        when "mpg"
          expect(col[1]).to eq 21.0
          expect(col[9]).to eq 22.8
          expect(col[32]).to eq 21.4
          expect(col[1] == 21.0).to eq true
          expect(col[9] == 22.8).to eq true
          expect(col[9] == 30).to eq false
          expect(col[32] == 21.4).to eq true
        when "cyl"
          expect(col[1] == 6.0).to eq true
          expect(col[10] == 6.0).to eq true
          expect(col[32] == 4.0).to eq true
          expect(col[1]).to eq 6.0
          expect(col[10]).to eq 6.0
          expect(col[32]).to eq 4.0
        when "disp"
          expect(col[1]).to eq 160.0
          expect(col[32]).to eq 121.0
          expect(col[1] == 160.0).to eq true
          expect(col[1] == 200.0).to eq false
          expect(col[32] == 121.0).to eq true
        end
        
      end
      
    end

    it "should do 'each_row'" do

      mtcars = ~:mtcars
      
      mtcars.each_row do |row, row_name|
        # row_name a Ruby string with the column name
        case row_name
        when "Mazda RX4"
          expect(row[['mpg']]).to eq 21.0
          # indexig with only '[ returns a data.frame which is not
          # equal to 21.0
          expect(row['mpg']).not_to eq 21.0
          expect(row.mpg).to eq 21.0
          expect(row.qsec).to eq 16.46
          expect(row[['mpg']] == 21.0).to eq true
          expect(row.qsec == 16.46).to eq true
        when "Hornet Sportabout"
          expect(row[['cyl']]).to eq 8.0
          expect(row.cyl).to eq 8.0
          expect(row[['wt']]).to eq 3.44
        when "Merc 240D"
          expect(row[['hp']]).to eq 62.0
          expect(row[['hp']] == 62.0).to eq true
          expect(row[['cyl']] == 4.0).to eq true
          expect(row[['wt']] == 3.19).to eq true
          expect(row.drat).to eq 3.69
        when "Volvo 142E"
          expect(row.hp).to eq 109.0
          expect(row.am).to eq 1.0
          expect(row.carb).to eq 2.0
        end
        
      end
      
    end
    
  end

  #----------------------------------------------------------------------------------------
  context "Boostraping" do
    
    before(:each) do
      @df = R.data__frame(x: R.rep((1..3), each: 2), y: (6..1), z: (~:letters)[(1..6)])
      R.set__seed(10)
    end
    
    it "should do reordering with integer subsetting" do
      
      table = @df[R.sample(@df.nrow), :all]
      expect(table.x[3]).to eq 3
      expect(table.y[2]).to eq 5
      expect(table.z.levels[6]).to eq "f"
      
    end
    
    it "should select random rows with integer subsetting" do
      table = @df[R.sample(@df.nrow, 3), :all]
      
      expect(table.x[3]).to eq 3
      expect(table.y[1]).to eq 3
      expect(table.z.levels[table.z[2]]).to eq "b"
    end
    
    it "should randomly reorder a dataframe" do
      df2 = @df[R.sample(@df.nrow), (3..1)]
      
      expect(df2.z.levels[df2.z[4]]).to eq "c"
      expect(df2.y[2]).to eq 5
      expect(df2.x[5]).to eq 1
    end
    
    it "should reorder by a given variable" do
      df2 = @df[R.sample(@df.nrow), (3..1)]
      df2 = df2[df2.x.order, :all]
      
      expect(df2.x[1]).to eq 1
      expect(df2.y[1]).to eq 5
      expect(df2.z.levels[df2.z[1]]).to eq "b"
    end
    
    it "should reorder variables" do
      df2 = @df[R.sample(@df.nrow), (3..1)]
      df2 = df2[df2.x.order, :all]
      
      df2 = df2[:all, df2.names.order]
      
      expect(df2.names.all__equal R.c("x", "y", "z")).to eq true
    end
    
  end

  # df = R.tibble::tibble(x = 1:3, y = 3:1, z = letters[1:3])
  
end

