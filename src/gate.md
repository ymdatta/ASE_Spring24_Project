# Notes on Gate.lua

Tim Menzies  
Jan 6 2024

GATE  is a  simple demonstrator  of  an incremental  optimization
method  called sequential model optimzation.  GATE assumes that (a)
data divides into X and Y  columns, and (b) it  is expensive to
access the Y values.  In that case, GATE learns how to recognize
good Y-values, using just very few  Y values.  

This is a four phase process:

| What | Called | Notes |
|------|--------|-------|
| G    | guess  | quickly generate some examples |
| A    | assess | using a surrogate model, assess which examples are interesting |
| T    | test   | test if the items found during assess are actually useful |
| E    | extend | extend the surrogate |

GATE uses _N1_ examples (picked at random) to initializes a Naive
Bayes classifier that  distinguishes the sqrt(_N_) _best_ examples
from the _rest_. Then, _N2_ times, we look for as-yet-unlabelled
examples that might confuse that classifier.  Specfifically, if an
example has probabilties _b,r_ of belonging to _best,rest_, then
the most confused example is the one that maximizes _abs(b+r)/abs(b-r)_.

## Installation

GATE is a single file. To grab the source code:

    curl https://raw.githubusercontent.com/timm/lo/6jan24/src/gate.lua

To find sample files:

    curl https://github.com/timm/lo/blob/6jan24/data/x

where  `x`   is  one   of  auto93.csv,  china.csv,   coc1000.csv,
coc10000.csv, healthCloseIsses12mths0001-hard.csv,
healthCloseIsses12mths0011-easy.csv, nasa93dem.csv, pom.csv.

## Data Format

GATE reads csv files whose first row names the columns.

- Names starting with uppercase are numeries; e.g. `Salary`. All other names are symbolic columns.
- 

