R.library('dplyr')
R.library('nycflights13')

puts R.filter(:flights, (:month.eq 1), (:day.eq 1))  # exec time: 0.15 sec

flights = ~:flights

puts flights

# In this call, 'flights' will be inlined in the expression and
# passed to method 'filter'. If 'filter' wants to print it's
# first argument, it will print the dataframe.
puts flights.filter((:month.eq 1), (:day.eq 1))       # exec time: 0.146 sec

# In this call, the symbol 'flights' is the first argument to method
# filter.  If 'filter' wants to print it's arguments, it will print
# 'flights'.
puts :flights.filter((:month.eq 1), (:day.eq 1))

puts flights.filter((:month.eq 12), (:day.eq 25))
puts flights.filter(:month._ :in, R.c(11, 12))
puts flights.filter(!((:arr_delay > 120) | (:dep_delay > 120)))
puts flights.arrange(:year, :month, :day)
puts flights.arrange(E.desc(:arr_delay))
puts flights.select(:year, :month, :day)
puts flights.select(R::S.columns(:year, :day))
puts flights.select(R::S.columns(:year, :day, remove: true))
puts flights.rename(tail_num: :tailnum)
puts flights.select(:time_hour, :air_time, E.everything)

#=begin
flights_sml =
  flights.
    select(R::S.columns(:year, :day),
           E.ends_with("delay"),
           :distance,
           :air_time)

puts flights_sml

puts flights_sml.mutate(gain: (:arr_delay - :dep_delay),
                        speed: (:distance / :air_time * 60))

puts flights_sml.mutate(gain: :arr_delay - :dep_delay,
                        hours: (:air_time / 60),
                        gain_per_hour: (:gain / :hours))

#=end

#=begin
expr = E.transmute(:flights, :dep_time,
                   hour: (:dep_time.int_div 100.0),
                   minute: :dep_time % 100.0)
puts expr
puts expr.ast
puts expr.eval


lst = R.list(x: 10, y: 20)
e = E.eval(:sum, :x, :y, lst)
e.eval

#=end
