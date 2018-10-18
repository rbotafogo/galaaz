# coding: utf-8

require 'galaaz'

# This examples were extracted from "Advanced R", by Hadley Wickham, available on the
# web at: http://adv-r.had.co.nz/Subsetting.html#applications

#------------------------------------------------------------------------------------------
# Lookup tables (character subsetting)
# Character matching provides a powerful way to make lookup tables.
# Say you want to convert abbreviations:
#------------------------------------------------------------------------------------------

x = R.c("m", "f", "u", "f", "f", "m", "m")
lookup = R.c(m: "Male", f: "Female", u: R::NA)
lookup[x].pp
print("\n")

#       m        f        u        f        f        m        m 
#  "Male" "Female"       NA "Female" "Female"   "Male"   "Male" 

R.unname(lookup[x]).pp
print("\n")

# [1] "Male"   "Female" NA  "Female" "Female" "Male"   "Male"  


#------------------------------------------------------------------------------------------
# Matching and merging by hand (integer subsetting)
#------------------------------------------------------------------------------------------

# You may have a more complicated lookup table which has multiple columns of information.
# Suppose we have a vector of grades, and a table that describes their properties:
# In R a vector c(1, 2, 3) is a double vector, when using polyglot R.c(1, 2, 3) is an
# integer vector, the equivalent of doing c(1L, 2L, 3L) in R.  Function 'match' does not
# work correctly with integer vector, it has to be a double.  
grades = R.c(1.0, 2.0, 2.0, 3.0, 1.0)

info = R.data__frame(
  grade: (3..1),
  desc: R.c("Excellent", "Good", "Poor"),
  fail: R.c(false, false, true)
)

# We want to duplicate the info table so that we have a row for each value in grades.
# We can do this in two ways, either using match() and integer subsetting,
# or rownames() and character subsetting:

# Using match
id = R.match(grades, info.grade)
info[id, :all].pp
print("\n")

#    grade      desc  fail
# 3       1      Poor  TRUE
# 2       2      Good FALSE
# 2.1     2      Good FALSE
# 1       3 Excellent FALSE
# 3.1     1      Poor  TRUE

# Using rownames
info.rownames = info.grade
info[grades.as__character, :all].pp
print("\n")

#     grade      desc  fail
# 1       3 Excellent FALSE
# 2       2      Good FALSE
# 2.1     2      Good FALSE
# 3       1      Poor  TRUE
# 1.1     3 Excellent FALSE

#------------------------------------------------------------------------------------------
# Random samples/bootstrap (integer subsetting)
#------------------------------------------------------------------------------------------

# You can use integer indices to perform random sampling or bootstrapping
# of a vector or data frame. sample() generates a vector of indices, then
# subsetting to access the values:
df = R.data__frame(x: R.rep((1..3), each: 2), y: (6..1), z: (~:letters)[(1..6)])

# Set seed for reproducibility
R.set__seed(10)

# Randomly reorder
df[R.sample(df.nrow), :all].pp
print("\n")

#   x y z
# 4 2 3 d
# 2 1 5 b
# 5 3 2 e
# 3 2 4 c
# 1 1 6 a
# 6 3 1 f

# Select 3 random rows
df[R.sample(df.nrow, 3), :all].pp
print("\n")

#   x y z
# 2 1 5 b
# 6 3 1 f
# 3 2 4 c

# Select 6 bootstrap replicates
df[R.sample(df.nrow, 6, rep: true), :all].pp
print("\n")

#     x y z
# 3   2 4 c
# 4   2 3 d
# 4.1 2 3 d
# 1   1 6 a
# 4.2 2 3 d
# 3.1 2 4 c

#------------------------------------------------------------------------------------------
# Ordering (integer subsetting)
#------------------------------------------------------------------------------------------

x = R.c("b", "c", "a")
x.order.pp
print("\n")

# [1] 3 1 2

x[x.order].pp
print("\n")

# [1] "a" "b" "c"

# Randomly reorder df
df2 = df[R.sample(df.nrow), (3..1)]
df2.pp
print("\n")

#   z y x
# 3 c 4 2
# 1 a 6 1
# 2 b 5 1
# 4 d 3 2
# 6 f 1 3
# 5 e 2 3

df2[df2.x.order, :all].pp
print("\n")

#   z y x
# 1 a 6 1
# 2 b 5 1
# 3 c 4 2
# 4 d 3 2
# 6 f 1 3
# 5 e 2 3

df2[:all, df2.names.order].pp
print("\n")

#   x y z
# 3 2 4 c
# 1 1 6 a
# 2 1 5 b
# 4 2 3 d
# 6 3 1 f
# 5 3 2 e

#------------------------------------------------------------------------------------------
# Expanding aggregated counts (integer subsetting)
# 
# Sometimes you get a data frame where identical rows have been collapsed into one and a
# count column has been added. rep() and integer subsetting make it easy to uncollapse
# the data by subsetting with a repeated row index:
#------------------------------------------------------------------------------------------

df = R.data__frame(x: R.c(2, 4, 1), y: R.c(9, 11, 6), n: R.c(3, 5, 1))
R.rep((1..(df.nrow << 0)), df.n).pp
print("\n")

# [1] 1 1 1 2 2 2 2 2 3

df[R.rep((1..df.nrow << 0), df.n), :all].pp
print("\n")

#     x  y n
# 1   2  9 3
# 1.1 2  9 3
# 1.2 2  9 3
# 2   4 11 5
# 2.1 4 11 5
# 2.2 4 11 5
# 2.3 4 11 5
# 2.4 4 11 5
# 3   1  6 1

#------------------------------------------------------------------------------------------
# Removing columns from data frames (character subsetting)
#
# There are two ways to remove columns from a data frame. You can set individual columns
# to nil:
#------------------------------------------------------------------------------------------

df = R.data__frame(x: (1..3), y: (3..1), z: (~:letters)[(1..3)])
# Not implemented yet
# df.z = nil
df.pp
print("\n")

df = R.data__frame(x: (1..3), y: (3..1), z: (~:letters)[(1..3)])
df[R.c("x", "y")].pp
print("\n")

#   x y
# 1 1 3
# 2 2 2
# 3 3 1

df[df.names.setdiff("z")].pp
print("\n")

#   x y
# 1 1 3
# 2 2 2
# 3 3 1

#------------------------------------------------------------------------------------------
# Selecting rows based on a condition (logical subsetting)
#
# Because it allows you to easily combine conditions from multiple columns, logical
# subsetting is probably the most commonly used technique for extracting rows out of
# a data frame.
#------------------------------------------------------------------------------------------

mtcars = ~:mtcars

mtcars[mtcars.gear == 5, :all].pp
print("\n")

#                 mpg cyl  disp  hp drat    wt qsec vs am gear carb
# Porsche 914-2  26.0   4 120.3  91 4.43 2.140 16.7  0  1    5    2
# Lotus Europa   30.4   4  95.1 113 3.77 1.513 16.9  1  1    5    2
# Ford Pantera L 15.8   8 351.0 264 4.22 3.170 14.5  0  1    5    4
# Ferrari Dino   19.7   6 145.0 175 3.62 2.770 15.5  0  1    5    6
# Maserati Bora  15.0   8 301.0 335 3.54 3.570 14.6  0  1    5    8

mtcars[(mtcars.gear == 5) & (mtcars.cyl == 4), :all].pp
print("\n")

#                mpg cyl  disp  hp drat    wt qsec vs am gear carb
# Porsche 914-2 26.0   4 120.3  91 4.43 2.140 16.7  0  1    5    2
# Lotus Europa  30.4   4  95.1 113 3.77 1.513 16.9  1  1    5    2


#------------------------------------------------------------------------------------------
# Boolean algebra vs. sets (logical & integer subsetting)
# 
# It’s useful to be aware of the natural equivalence between set operations (integer
# subsetting) and boolean algebra (logical subsetting)
#------------------------------------------------------------------------------------------

x = R.sample(10) < 4
x.which.pp
print("\n")

# [1]  3  7 10

#===
x1 = R.c((1..10)) % 2 == 0
x1.pp
print("\n")

# [1] FALSE  TRUE FALSE  TRUE FALSE  TRUE FALSE  TRUE FALSE  TRUE

#===
x2 = x1.which
x2.pp
print("\n")

# [1]  2  4  6  8 10

#===
y1 = R.c((1..10)) % 5 == 0
y1.pp
print("\n")

# [1] FALSE FALSE FALSE FALSE  TRUE FALSE FALSE FALSE FALSE  TRUE

#===
y2 = y1.which
y2.pp
print("\n")

# [1]  5 10

#===
# X & Y <-> intersect(x, y)
(x1 & y1).pp
print("\n")

# [1] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE  TRUE

#===
# This example shows the problem with having R objects returning either
# vector or scalar.  We don't know the type of the result of applying
# intersect.  If this is a vector, then we need to print it with pp
# but if this is a scalar, we need to print it with regular Ruby 'p' or
# 'print'
puts R.intersect(x2, y2)
print("\n")

# 10

puts x2.intersect y2

# 10

#===
# X | Y <-> union(x, y)
(x1 | y1).pp
print("\n")

# [1] FALSE  TRUE FALSE  TRUE  TRUE  TRUE FALSE  TRUE FALSE  TRUE

#===
R.union(x2, y2).pp
print("\n")

# [1]  2  4  6  8 10  5

(x2.union y2).pp

# [1]  2  4  6  8 10  5

#===
# X & !Y <-> setdiff(x, y)
(x1 & !y1).pp
print("\n")

# [1] FALSE  TRUE FALSE  TRUE FALSE  TRUE FALSE  TRUE FALSE FALSE

#===
R.setdiff(x2, y2).pp
print("\n")

# [1] 2 4 6 8

(x2.setdiff y2).pp

# [1] 2 4 6 8


#===
# xor(X, Y) <-> setdiff(union(x, y), intersect(x, y))
R.xor(x1, y1).pp
print("\n")

#  [1] FALSE  TRUE FALSE  TRUE  TRUE  TRUE FALSE  TRUE FALSE FALSE

# Writing the same as the last example in a Ruby style
(x1.xor y1).pp

#  [1] FALSE  TRUE FALSE  TRUE  TRUE  TRUE FALSE  TRUE FALSE FALSE

#===
R.setdiff(R.union(x2, y2), R.intersect(x2, y2)).pp
print("\n")

# [1] 2 4 6 8 5

# Writing the same as the last example in a Ruby style
((x2.union y2).setdiff (x2.intersect y2)).pp
print("\n")

# [1] 2 4 6 8 5
