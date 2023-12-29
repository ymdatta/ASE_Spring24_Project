
## Lots of Small Functions

More than five lines per function makes me nervous, less than three makes me smile.

## Few globals

_N-1_ globals is better than _N_. I just try to have one: the 
global config settings `the`.

## Function Args
In function args:

- two spaces denotes "start of optionals"
- four spaces denotes "start of locals"

## Lots of small apps


Each `src/app.lua` file:

- Has doco in ``../docs/app.html`;
- Can read from a `-f` file or from standard input;
- Has help text at the top, from which `the` globals are extracted;
- Has tests/examples at the end:
  - From the command line, we can run one specific test or all;
  - Before running a test, we reset the random number seed;
  - After running a test, we reset all the settings to their defaults;
  - Each test returns `true``, `false``, or `nil``.
    -  If `false`, then
    we say a test fails.
  - If we run `all``, the code returns the number of failed tests;
    - so `$?==0` means "no errors"

## Data Files
This code reads data files which names columns on line1:

- Upper case names indicate numerics (and all else are symbols).
- Names ending the `!` are klass columns (there should be only one)
- Names ending with `+` or `-` are goals to be maximized, mimizied
  (there can be many)
- Klass and goal columns are the dependent `y` columns.
- Everything else are the dependent `x` columns.
   
e.g. for  `Age,job,Salary+`:
    
   - `Age` and `Salary` are numeric
   - `Salary` is a goal to be maximized 
   - `Age` and `job` are the `x` independent variables.
       
## Classes
`function ZZZ.new()` is a constructor (since it has an upper case name).   
`function ZZZ:new(...)` updates `zzz1` of type `ZZZ`. 
  
##  Type hints
For function args (not for locals)
    
- `zzz1` (or `zzz``) = instance of class `ZZZ`.
- `x` is anything
- `n` = number
- `s` = string
- `xs` = list of many `x`
- `t` = table.
- `a` = array (index 1,2,3..)
- `h` = hash (indexed by keys)
- `fun` = function
