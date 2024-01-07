# Notes on Gate.lua

Tim Menzies  
Jan 6 2024

GATE  is a  simple demonstrator  of  an incremental  optimization method  called
sequential model optimzation.  GATE assumes that (a) data divides into X and Y
columns, and (b) it  is expensive to access the Y values.  In that case, GATE
learns how to recognize good Y-values, using just very few  Y values.

GATE was written as a `less is more` exercise. Lua was used since
it so simple. Other languages were explored: LISP was too hard
for newbies; Julia and Crystal had annoying slow start-ups; 
Gawk functions are too limited (cannot  return structs); 
Python was just dull; and I could never crack the Haskell barrier.
  The resulting code is under 500 lines, but that includes
all the
support code (demo suites, library functions, etc).
The actual incremental optimier is just a few dozen lines. 

GATE runs in four phases:

| What | Called | Notes |
|------|--------|-------|
| G    | guess  | quickly generate some examples |
| A    | assess | using a surrogate model, assess which examples are interesting |
| T    | test   | test if the items found during assess are actually useful |
| E    | extend | extend the surrogate |

GATE uses _N1_ examples (picked at random) to initializes a Naive Bayes
classifier that  distinguishes the sqrt(_N_) _best_ examples from the _rest_.

Then, _N2_ times, we look for as-yet-unlabelled examples that might confuse that
classifier.  Specfifically, if an example has probabilties _b,r_ of belonging to
_best,rest_, then the most confused example is the one that maximizes
_abs(b+r)/abs(b-r)_.
That example is then evaluated and the model is extended.


## Installation

Install LUA
```
brew install lua5.3 # mac os/x
sudo apt update; sudp apt install lua5.3 # debian/unix
```

Make directories

```sh
mkdir gate
mkdir gate/data
mkdir gate/src
```

Load the script.

```sh
cd gate/src
curl https://raw.githubusercontent.com/timm/lo/6jan24/src/gate.lua
```

Load the sample data.

```sh
cd ../data
Files="auto93  china   coc1000 coc10000 diabtes
       healthCloseIsses12mths0001-hard healthCloseIsses12mths0011-easy
       nasa93dem pom soybean"
for f in $Files do
  curl https://github.com/timm/lo/blob/6jan24/data/$f.csv
done
```

(Note that the diabetes and soybean and classification data sets (only
one symbolic goal) while the rest are optimization data sets (To test the installation install

Test your installation.

```sh
cd ../src
lua gate.lua -t all
```

If this works, the last line of the test output should be say "PASS 0 fail(s)".

## Data Format

GATE reads comma-seperated files (e.g. auto93.csv) whose first row names the columns.

- Names starting with uppercase are numeries; e.g. `Volume`. All
  other names are symbolic columns (e.g. `origin`)  
- Names ending with X are ignored by the reasoning; e.g. `HpX`.  
- Numeric names ending with `-` or `+` are goals to be minimized or maximized; 
  e.g. `Lbs-` and `Acc+`.  
- Symolic names ending with `!` are classes to be recognized; e.g. `happy!`.

```
          {Clndrs, Volume,HpX,   Model,  origin, Lbs-,  Acc+,  Mpg+}
1         {4,      97,   52,     82,      2,     2130,  24.6,  40}
2         {4,      90,   48,     80,      2,     2335,  23.7,  40}
3         {4,      90,   48,     78,      2,     1985,  21.5,  40}
4         {4,      90,   48,     80,      2,     2085,  21.7,  40}
...
394       {8,      429,  198,    73,      1,     4952,  11.5,  10}
395       {8,      383,  180,    71,      1,     4955,  11.5,  10}
396       {8,      440,  215,    70,      1,     4312,  8.5,   10}
397       {8,      455,  225,    73,      1,     4951,  11,    10}
398       {8,      400,  175,    71,      1,     5140,  12,    10}
```

Most of GATE's reasoning occurs over the X columns with only an occasional
peek at the Y values.

But sometimes, just to generate baselines, we look at everything. For
example, after looking  at all the Y values,
the above rows are sorted by `distance to heaven`:

$$H=\sqrt{\left(\sum^n_i(\overline{y_i} - h_i)^2\right)/n}$$

That is, for $n$ goals normalized to $\overline{x_i}$ as 0..1 min..max,
find the distance to the best value ($h_i=0$ for goals we are minimizing 
and $h_i=1$ for goals we are maximizing). 

The net result is that the rows closest to the goals are shown first (lightest,
fastest, most economical cars) and the worst casrs are shown last
(heaviest, slowest, worst MPG).

## Code Format

gate.lua has four major sections: help text,  examples, classes, 
and library functions (and  all the library functions are stored
in the `l` table; e.g. see the `l.settings` function shown
below).

##a Help Text

The top of gate.lua is a help string from which this code extracts the system's
config.

```txt
help =[[

gate: guess, assess, try, expand
(c) 2023, Tim Menzies, BSD-2
Learn a little, guess a lot, try the strangest guess, learn a little more, repeat

USAGE:
  lua gate.lua [OPTIONS]

OPTIONS:
  -c --cohen    small effect size               = .35
  -f --file     csv data file name              = ../data/diabetes.csv
  -h --help     show help                       = false
  -k --k        low class frequency kludge      = 1
  -m --m        low attribute frequency kludge  = 2
  -s --seed     random number seed              = 31210
  -t --todo     start up action                 = help]]
```

The parser for this help is very simple (it just looks for a regular
expression that finds a word after two dashes: 

       [-][-]([%S]+)[^=]+= ([%S]+)

```lua
function l.settings(s,    t,pat) --> a dictionary with the config options
  t,pat = {}, "[-][-]([%S]+)[^=]+= ([%S]+)"
  for k, s1 in s:gmatch(pat) do t[k] = l.coerce(s1) end
  t._help = s
  return t end
```

That parser needs a function to `coerce` strings to (e.g.) numbers or
booleans. 

```lua
function l.coerce(s1,    fun) --> nil or bool or int or float or string
  function fun(s2)
    if s2=="nil" then return nil else return s2=="true" or (s2~="false" and s2) end end
  return math.tointeger(s1) or tonumber(s1) or fun(s1:match'^%s*(.*%S)') end
```

This code is used to generate a variable `the` storing the
config.

```
the = l.settings(help)
```

Optinonally, we can update the built in defaults via 
command-line flags using the `cli` function (which,
incidently, uses `coerce` to turn command line strings
into values):

```lua
function l.cli(t) --> the table `t` updated from command line
  for k, v in pairs(t) do
    v = tostring(v)
    for argv,s in pairs(arg) do
      if s=="-"..(k:sub(1,1)) or s=="--"..k then
        v = v=="true" and "false" or v=="false" and "true" or arg[argv + 1]
        t[k] = l.coerce(v) end end end
  if t.help then os.exit(print("\n"..t._help)) end
  return t end

the = l.cli(the)
```
### Example library

The code ends with a few dozen tests that test/demo differnt parts
of the system. For example, here are two examples:

- ``eg.oo`` tests the code for printing nested structures.
- ``eg.sym`` tests  class that accepts atoms and can report
   the mode and entropy of that collection (code for `SYM`
   is presented below).

All these tests can be run at the command line:

```
lua gate.lua -t oo
lua gate.lua -t sym
```

```lua
local eg={}

function eg.oo()
  return l.o{a=1,b=2,c=3,d={e=3,f=4}}  == "{a: 1, b: 2, c: 3, d: {e: 3, f: 4}}" end

function eg.sym(      s,mode,e)
  s = SYM.new()
  for _, x in pairs{1,1,1,1,2,2,3} do s:add(x) end
  mode, e = s:mid(), s:div()
  print(mode, e)
  return 1.37 < e and e < 1.38 and mode == 1 end
```

The example library needs some support code.  The `run` function
checks what is returned by each example (and if it is `false`, then
this test returns `true` indicating a failure. Note also that `run`
has does some _setup_ and _tearDown_:

- In the `tearDown` step, we restore the global config.
- As _setup_, the global config is cached (so it can be 
  restored in `tearDown`) and the randomseed is restored
  to some default value.


```lua
local function run(k,   oops,b4)
  b4 = l.copy(the) -- set up
  math.randomseed(the.seed) -- set up
  oops = eg[k]()==false
  io.stderr:write(l.fmt("# %s %s\n",oops and "❌ FAIL" or "✅ PASS",k))
  for k,v in pairs(b4) do the[k]=v end -- tear down
  return oops end
```

The `eg.all` command runs all the examples (via `run`)
and returns to the operating system the number of failures.
Note the use of `l.keys()`: this returns the example names,
sorted alphabetically (so the tests are run in that order).

```lua
function eg.all(     bad)
  bad=0
  for _,k in pairs(l.keys(eg)) do
    if k ~= "all" then
      if run(k) then bad=bad+1 end end end
  io.stderr:write(l.fmt("# %s %s fail(s)\n",bad>0 and "❌ FAIL" or "✅ PASS",bad))
  os.exit(bad) end
```

Note that `eg.all` can be called from the command line

```
lua gate.lua -t all
```
