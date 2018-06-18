
## The SciCom “language”

SciCom also allows for implementing R scripts in a “language” that is
just like Ruby, so that the developer does not need to know that she
is actually writing an R script.  All R methods are accessible through
an R namespace.

The next script is the same baseball model done in R above using
SciCom ‘language’:

    require ‘scicom’
    # This dataset comes from Baseball-Reference.com.
    baseball = R.read__csv("baseball.csv")
    # Lets look at the data available for Momeyball.
    moneyball = baseball.subset(baseball.Year < 2002)

    # Let's see if we can predict the number of wins, by looking at
    # runs allowed (RA) and runs scored (RS).  RD is the runs difference.
    # We are making a linear model for predicting wins (W) based on RD
    moneyball.RD = moneyball.RS - moneyball.RA
    wins_reg = R.lm("W ~ RD", data: moneyball)
    wins_reg.summary.pp

We show bellow an example of calculating the correlation matrix
without using the build-in functions.  First this is done in an R
script and then using SciCom:

    # Create a matrix and give it rownames and colnames
    set.seed(42)
    Xij <- matrix(sample(seq(0, 9), 40, replace = TRUE), ncol = 4)
    rownames(Xij) <- paste("S", seq(1, dim(Xij)[1]), sep = "")
    colnames(Xij) <- paste("V", seq(1, dim(Xij)[2]), sep = "")
 
    # find the means of the columns
    n <- dim(Xij)[1]
    one <- rep(1, n)
    X.means <- t(one) %*% Xij/n
 
    # find the covariance of the matrix
    X.diff <- Xij - one %*% X.means
    X.cov <- t(X.diff) %*% X.diff/(n - 1)
    round(X.cov, 2)
 
    # find the correlation 
    sdi <- diag(1/sqrt(diag(X.cov)))
    rownames(sdi) <- colnames(sdi) <- colnames(X.cov)
    round(sdi, 2)
    X.cor <- sdi %*% X.cov %*% sdi
    rownames(X.cor) <- colnames(X.cor) <- colnames(X.cov)
    round(X.cor, 2)

Now the same code using SciCom

    require ‘scicom’
    # Create a matrix and give it rownames and colnames
    R.set__seed(42)
	R.seq(0,9).sample(40, replace: TRUE).matrix(ncol: 4)
	  .fassign(:rownames, R.paste("S", R.seq(1, xij.attr.dim[1]), sep: ""))
      .fassign(:colnames, R.paste("V", R.seq(1, xij.attr.dim[2]), sep: ""))
 
    # find the means of the columns
    n = xij.dim[1]
    one = R.rep(1, n)
    x_means = one.t._ :*, xij/n
 
    # find the covariance of the matrix
    x_diff = xij - (one._ :*, x_means)
    x_cov = (x_diff.t._ :*, x_diff/(n - 1)).round(2)
 
    # find the correlation 
    sdi = (1 / x_cov.diag.sqrt).diag.round(2)
    sdi.fassign(:rownames, x_cov.rownames)
    sdi.fassign(:colnames, x_cov.colnames)
    x_cor = ((sdi._ :*, x_cov)._ :*, sdi)
      .round(2)
      .fassign(:rownames, x_cov.rownames)
      .fassign(:colnames, x_cov.colnames)

As another example, here is a SciCom script to print the number of
days for every month is 2005:

    require ‘scicom’
    everyday = R.seq(from: R.as__Date('2005-1-1'), to: R.as__Date('2005-12-31'), by: 'day')
    cmonth = everyday.format('%b')
    cmonth
      .factor(levels: cmonth.unique, ordered: TRUE)
      .table
      .pp

As can be seen from these examples, R methods can be accessed through
the R namespace in SciCom, so, R method ‘seq’ is called in SciCom as
‘R.seq’.  R methods that are applied on objects can be called in two
ways, either using the R namespace as in ‘R.factor’ or directly on the
object, as in this case we did ‘cmonth.factor’.  This last example
shows how SciCom allows method chaining, which is not possible in an R
script.

## R Functions

SciCom allows programmers to access any R function in the R namespace.  For instance, as shown
above, function _c_ in R can be access in SciCom by a call to R.c.  As another example,
method _seq_ in R is accessed in SciCom by a call to R.seq.

Parameters can be passed to R functions normaly.  For example, the code bellow creates a vector
with with doubles:

	> vec = R.c(2.4, 5.55, 10, 18.27, 34.45)
	> vec.pp

	[1]   2,4  5,55    10 18,27 34,45

Ruby variable can also be passed as arguments to R methods:

	> vec2 = R.c(vec, 3.5)
	> vec2.pp

	[1]   2,4  5,55    10 18,27 34,45   3,5

	> dbl = 3.5
	> vec3 = R.c(vec2, dbl)
	> vec3.pp

	[1]   2,4  5,55    10 18,27 34,45   3,5  5,75

More complex Ruby classes, such ar Ruby hashes, of course, cannot be passed as argument to R
methods.  SciCom, in principle, should support every Ruby method that is available in
Renjin.  Note that Renjin is still under development and not all methods and libraries are
available.

Some methods and variables in R have a '.' in their names.  This is standard R notation;
however, '.' in Ruby is interpreted as a method call and thus cannot be part of a
variable name or function.  In order to access names in R that have a '.' on them
in SciCom, the '.' is substituted by '__':

	> # variable defined in R with a '.' in the name
	> R.eval("r.d = 10.35")
	> # access the variable 'r.d' in Ruby by using '__' notation
	> R.r__d.pp

	[1] 10,35

Accessing method _as.complex_ in R is also done by using '__' notation:

	# acess R method 'as.complex' using 'as__complex' notation
	> comp = R.as__complex(-1)
	> p R.Re(comp).gz

	-1.0
	
	> p R.Im(comp).gz

	0.0

	> # now method 'is.complex'
	> p R.is__complex(comp).gt

	true

### Method Chaining

SciCom allows methods to be chained.  The code above can be written as:

	# prints the real part of a complex number by using method chaining
	> R.as__complex(-1)
		.Re
		.pp

	[1] -1

We will see more examples of method chaining later in this documentation.
In principle, we will try to use method chaining whenever possible, but
in some situations normal use of R methods through the 'R.' notation will
be used to remind the reader that this notation is also possible.

### Named Parameters

R allows the use of named parameters in function calls.  SciCom also allows
for named parameters.  Named parameters in SciCom require the use of
Ruby hashes in the normal Ruby way.

    > # R code to create a complex number
	> R.eval("comp = complex(real = 0, imaginary = 1)")
	> R.eval("print(comp)")

	[0.0+1.0i]

	> # Same code as above in SciCom notation, with chaining
	> R.complex(real: 0, imaginary: 1)
	>   .pp

	[0.0+1.0i]

## SciCom with Standard R Interface

SciCom allows R programmers to use R commands inside a Ruby script in
a way similar to RinRuby by calling method eval and passing to it an R
script:

    # Basic integration with R can always be done by calling eval and passing it a valid
    # R expression.
    > R.eval("r.i = 10L")
    > R.eval("print(r.i)")

    [1] 10

    > R.eval("vec = c(10, 20, 30, 40, 50)")
    > R.eval("print(vec)")

    [1] 10 20 30 40 50

    > R.eval("print(vec[1])")

    [1] 10

Programmers can also use here docs to integrate an R script inside a
Ruby script.  The next example show a model for predicting baseball
wins based on runs allowed and runs scored.  The data comes from
Baseball-Reference.com.

      R.eval <<EOF

        # This dataset comes from Baseball-Reference.com.
        baseball = read.csv("baseball.csv")
        # str has a bug in Renjin
        # str(data)

        # Lets look at the data available for Momeyball.
        moneyball = subset(baseball, Year < 2002)

        # Let's see if we can predict the number of wins, by lookin at
        # runs allowed (RA) and runs scored (RS).  RD is the runs difference.
        # We are making a linear model from predicting wins (W) based on RD
        moneyball$RD = moneyball$RS - moneyball$RA
        WinsReg = lm(W ~ RD, data=moneyball)
        print(summary(WinsReg))

    EOF

The output of the program above is:

    Call:
    lm(data = moneyball, formula = W ~ RD)

    Residuals:
        Min      1Q  Median      3Q     Max
    -14,266  -2,651   0,123   2,936  11,657

    Coefficients:
                Estimate   Std. Error t value    Pr(>|t|)             
    (Intercept) 80,881     0,131      616,675    <0         ***       
             RD 0,106      0,001       81,554    <0         ***       
    ---
    Signif. codes:  0 '***' 0,001 '**' 0,01 '*' 0,05 '.' 0,1 ' ' 1 

    Residual standard error: 3,939 on 900 degrees of freedom
    Multiple R-squared: 0,8808,	Adjusted R-squared: 0,8807 
    F-statistic: 6.650,9926 on 1 and 900 DF,  p-value: < 0
