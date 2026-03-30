# frozen_string_literal: true

require 'galaaz'

describe R::DataFrame do
  context 'creation and basic access' do
    it 'creates a data.frame from a shaped vector' do
      vec = R.seq(6)
      vec.dim = R.c(2, 3)

      df = vec.as__data__frame
      expect(df).to be_a(R::DataFrame)
      expect(df[1, 'V1']).to eq 1
      expect(df[1, 'V2']).to eq 3
      expect(df[1, :all].as__numeric).to eq R.c(1.0, 3, 5)
    end
  end

  context "subsetting with '[' and '[['" do
    before(:each) do
      @mtcars = ~:mtcars
    end

    it 'subsets a single column by index' do
      slice = @mtcars[1]
      expect(slice).to be_a(R::DataFrame)
      expect(slice.length).to eq 1
      expect(slice[[1]][1]).to eq 21.0
      expect(slice[[1, 1]]).to eq 21.0
    end

    it 'raises bridge process error for invalid column selection with []' do
      slice = @mtcars[1]
      expect { slice['Mazda RX4'] }.to raise_error(NewBridge::SessionClient::RProcessError)
      expect(slice[['Mazda RX4']]).to eq nil
    end

    it 'supports row+column by names and indices' do
      expect(@mtcars[1, 1]).to eq 21.0
      expect(@mtcars['Merc 450SL', 'drat']).to eq 3.07
      expect(@mtcars[['Valiant', 'mpg']]).to eq 18.1
      expect(@mtcars[[6, 5]]).to eq 2.76
    end

    it 'supports drop parameter for row extraction' do
      lst = @mtcars[1, :all, drop: true]
      expect(lst).to be_a(R::List)
      expect(lst[[1]]).to eq 21.0
      expect(lst[1]).to eq R.list(mpg: 21.0)
    end
  end

  context "assignment with '[<-'" do
    before(:each) do
      @mtcars = ~:mtcars
    end

    it 'adds a column and updates cells by index' do
      @mtcars['New Column'] = R.c((1..32))
      expect(@mtcars[[1, 12]]).to eq 1
      expect(@mtcars[['Mazda RX4', 'New Column']]).to eq 1

      @mtcars[17, 6] = 1000
      expect(@mtcars[[17, 6]]).to eq 1000.0
      expect(@mtcars[['Chrysler Imperial', 'wt']]).to eq 1000.0
    end
  end

  context 'iteration helpers' do
    it 'iterates columns with each_column and exposes column names' do
      mtcars = ~:mtcars
      seen = {}

      mtcars.each_column do |col, col_name|
        seen[col_name] = col[1] if %w[mpg cyl disp].include?(col_name)
      end

      expect(seen['mpg']).to eq 21.0
      expect(seen['cyl']).to eq 6.0
      expect(seen['disp']).to eq 160.0
    end

    it 'iterates rows with each_row and exposes row names' do
      mtcars = ~:mtcars
      seen = {}

      mtcars.each_row do |row, row_name|
        if ['Mazda RX4', 'Merc 240D'].include?(row_name)
          seen[row_name] = [row[['mpg']], row[['hp']]]
        end
      end

      expect(seen['Mazda RX4']).to eq([21.0, 110.0])
      expect(seen['Merc 240D']).to eq([24.4, 62.0])
    end
  end

  context 'bootstrap-style row reordering' do
    before(:each) do
      @df = R.data__frame(
        x: R.rep((1..3), each: 2),
        y: (6..1),
        z: R.factor((~:letters)[(1..6)])
      )
      R.set__seed(10)
    end

    it 'reorders rows using sampled integer indices' do
      table = @df[R.sample(@df.nrow), :all]
      expect(table.x[3]).to eq 1
      expect(table.y[2]).to eq 6
      expect(table.z.levels[table.z[4]]).to eq 'f'
    end

    it 'selects a sampled subset of rows' do
      table = @df[R.sample(@df.nrow, 3), :all]
      expect(table.x[3]).to eq 1
      expect(table.y[1]).to eq 4
      expect(table.z.levels[table.z[2]]).to eq 'a'
    end
  end
end
