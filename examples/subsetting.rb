require '../config'
require 'cantata'

# Lookup tables (character subsetting)
# Character matching provides a powerful way to make lookup tables.
# Say you want to convert abbreviations:

x = R.c("m", "f", "u", "f", "f", "m", "m")
lookup = R.c(m: "Male", f: "Female", u: NA)
lookup[x].pp

#       m        f        u        f        f        m        m 
#  "Male" "Female"  "FALSE" "Female" "Female"   "Male"   "Male" 

R.unname(lookup[x]).pp

# [1] "Male"   "Female" "FALSE"  "Female" "Female" "Male"   "Male"  



# Matching and merging by hand (integer subsetting)

# You may have a more complicated lookup table which has multiple columns of information.
# Suppose we have a vector of integer grades, and a table that describes their properties:

grades = R.c(1, 2, 2, 3, 1)

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
