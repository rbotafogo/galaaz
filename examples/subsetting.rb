require '../config'
require 'cantata'

# This examples are extracted from "Advanced R", by Hadley Wickham, available on the
# web at: http://adv-r.had.co.nz/Subsetting.html#applications

#------------------------------------------------------------------------------------------
# Lookup tables (character subsetting)
# Character matching provides a powerful way to make lookup tables.
# Say you want to convert abbreviations:
#------------------------------------------------------------------------------------------

x = R.c("m", "f", "u", "f", "f", "m", "m")
lookup = R.c(m: "Male", f: "Female", u: NA)
lookup[x].pp

#       m        f        u        f        f        m        m 
#  "Male" "Female"  "FALSE" "Female" "Female"   "Male"   "Male" 

R.unname(lookup[x]).pp

# [1] "Male"   "Female" "FALSE"  "Female" "Female" "Male"   "Male"  


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

#    grade      desc  fail
# 3       1      Poor  TRUE
# 2       2      Good FALSE
# 2.1     2      Good FALSE
# 1       3 Excellent FALSE
# 3.1     1      Poor  TRUE

# Using rownames
info.rownames = info.grade
info[grades.as__character, :all].pp

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
df = R.data__frame(x: R.rep((1..3), each: 2), y: (6..1), z: R.letters[(1..6)])

# Set seed for reproducibility
R.set__seed(10)

# Randomly reorder
df[R.sample(df.nrow), :all].pp

#   x y z
# 4 2 3 d
# 2 1 5 b
# 5 3 2 e
# 3 2 4 c
# 1 1 6 a
# 6 3 1 f

# Select 3 random rows
df[R.sample(df.nrow, 3), :all].pp

#   x y z
# 2 1 5 b
# 6 3 1 f
# 3 2 4 c

# Select 6 bootstrap replicates
df[R.sample(df.nrow, 6, rep: true), :all].pp

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

# [1] 3 1 2

x[x.order].pp

# [1] "a" "b" "c"

# Randomly reorder df
df2 = df[R.sample(df.nrow), (3..1)]
df2.pp

#   z y x
# 3 c 4 2
# 1 a 6 1
# 2 b 5 1
# 4 d 3 2
# 6 f 1 3
# 5 e 2 3

df2[df2.x.order, :all].pp

#   z y x
# 1 a 6 1
# 2 b 5 1
# 3 c 4 2
# 4 d 3 2
# 6 f 1 3
# 5 e 2 3

df2[:all, df2.names.order].pp

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
R.rep((1..df.nrow), df.n).pp

# [1] 1 1 1 2 2 2 2 2 3

df[R.rep((1..df.nrow), df.n), :all].pp

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

df = R.data__frame(x: (1..3), y: (3..1), z: R.letters[(1..3)])
# Not implemented yet
# df.z = nil
df.pp


df = R.data__frame(x: (1..3), y: (3..1), z: R.letters[(1..3)])
df[R.c("x", "y")].pp

#   x y
# 1 1 3
# 2 2 2
# 3 3 1

df[df.names.setdiff("z")].pp

#   x y
# 1 1 3
# 2 2 2
# 3 3 1
