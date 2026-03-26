# rdata_frame.rb
module R
  class DataFrame < Object
    include IndexedObject
    include MDIndexedObject

    # Phase 5.2: unbox entire data.frame via NewBridgeAdapter#pull_dataframe.
    # This avoids the generic list-unboxing path which relies on scalar-only eval.
    def unboxed_get(index = nil, depth = 0)
      return ::R.bridge.pull_dataframe(@r_interop) if index.nil?
      super
    end

    def class
      ::R::DataFrame
    end

    def qplot(*args)
      # Use R's print so the plot is displayed on the R device with a single argument (avoids "invalid printing digits" from extra args).
      ::R.print(::R.qplot(*args, data: self))
    end

    def method_missing_assign(column_name, arg)
      # Functional form: df <- `[[<-`(df, i = 'col', value = val)
      res = ::R::Support.exec_function("`[[<-`", self, i: column_name, value: arg)
      @r_interop = res.r_interop
      res
    end

    def []=(index, *args)
      values = args[-1]
      res = if index.is_a? ::Array
        ::R::Support.exec_function("`[[<-`", self, i: index, value: values)
      else
        idx2 = (args.size > 1) ? args[-2] : nil
        if idx2
          ::R::Support.exec_function("`[<-`", self, i: index, j: idx2, value: values)
        else
          ::R::Support.exec_function("`[<-`", self, i: index, value: values)
        end
      end
      @r_interop = res.r_interop
      self
    end

    
    def each_row
      (1..nrow >> 0).each do |i|
        yield self[i, :all], self.rownames[i] >> 0
      end
    end

    def each_column
      (1..ncol >> 0).each do |i|
        yield self[:all, i], self.names[i] >> 0
      end
    end
  end
end
