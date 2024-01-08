---
title: |
  ![](../docs/cover.png){width=4in}\vspace{1cm}    
  Notes on Gate.lua
author: Tim Menzies
date: Jan 8, 2024
geometry: margin=1in
documentclass: article
font-size: 8pt
header-includes: |
    \usepackage{graphicx}
    \usepackage{titlesec}\newcommand{\sectionbreak}{\clearpage}
    \usepackage{inconsolata}
    \usepackage{amssymb}
    \usepackage{pifont}
    \usepackage{array}
    \usepackage[T1]{fontenc}
    \usepackage{textcomp}
    \usepackage{mathpazo}
    \usepackage{fancyhdr}\pagestyle{fancy}
    \fancyhead[CO,CE]{}\fancyfoot[CO,CE]{}\fancyfoot[LE,RO]{\thepage}
    \BeforeBeginEnvironment{listings}{\par\noindent\begin{minipage}{\linewidth}}
    \AfterEndEnvironment{listings}{\end{minipage}\par\addvspace{\topskip}}
---

# Overview

GATE  is a  simple demonstrator  of  an incremental  optimization method  called
sequential model optimzation.  GATE assumes that (a) data divides into X and Y
columns, and (b) it  is expensive to access the Y values.  In that case, GATE
learns how to recognize good Y-values, using just very few  Y values.

GATE was written as a `less is more` exercise. Lua was used since
it so simple (see the cheatsheet  at the end of this document for a quick tour or Lua)

 Other languages were explored: LISP was too hard
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

The rest of this document describes GATE:

- First, we talk how to install the system;
- Second, we discuss some of the coding convetions used here.
- After that, we discuss the four main sections of the code
  - Help and settings
  - GATE's input data format
  - The example and demo library
  - Classes
    - The column classes;
    - The DATA classes.
  - A library of support code.  All these functions are stored inside the `l`
    table (e.g. see the`l.settings` function shown below).

# Installation

## Install LUA
```
brew install lua5.3 # mac os/x
sudo apt update; sudp apt install lua5.3 # debian/unix
```

## Make directories

```sh
mkdir gate
mkdir gate/data
mkdir gate/src
```

## Load the script.

```sh
cd gate/src
curl https://raw.githubusercontent.com/timm/lo/6jan24/src/gate.lua
```

## Load the sample data.

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

## Test your installation.

```sh
cd ../src
lua gate.lua -t all
```

If this works, the last line of the test output should be say "PASS 0 fail(s)".

# Coding Convetions

## Small functions
More than six lines per function makes me nervous, five lines makes me happy,
 less than three makes me   gleeful.
Also, if a  line just contains `end`, the I add it to the line above.

## Narrow lines
90 chars/line or less (otherwise the pdf printing messes up).

## Few globals
_N-1_ globals is better than _N_. I just try to have one:
- The  global config settings `the`.
- This `the` variable is parsed from the help text listed at top of file.
- Optionally, `the` can be updated from the command-line options.

## Function arguments
Two spaces denotes "start of optionals" and
four spaces denotes "start of locals"

## Tests
From command line we can run one, or all tests.
-   Before running a test, we reset the random number seed;
-   After running a test, we reset all the settings to their defaults;
- Each test returns `true``, `false``, or `nil``.  If `false`, then
    we say a test fails.
- If we run `all``, the code returns the number of failed tests;
    (so `$?==0` means "no errors").

## Structs
Classes in my Lua are defined as tables that know
know to look up methods in themselves, before looking elsewhere:
```lua
local function isa(x,y) return setmetatable(y,x) end
local function is(s,    t) t={a=s}; t.__index=t; return t end
```
`function ZZZ.new(...)` is a constructor that returns a new struct of type `ZZZ`.
My structs support  encapsulation, polymorphism, but no inheritance. Why?:
- See [^diederich12] [^hatton98] about the errors introduced by objects;
- If you really want inheritance,   use a langua ge that
truly supports it, like Smalltalk or Crystal).

## Type hints
For function argumnets (but not for locals) I try to apply the following stadards:

- `zzz` (or `zzz1``) = instance of class `ZZZ`.
- `x` is anything
- `n` = number
- `s` = string
- `xs` = list of many `x`
- `t` = table.
- `a` = array (index 1,2,3..)
- `h` = hash (indexed by keys)
- `fun` = function


[^hatton98]: Hatton, Les. “Does OO Sync with How We Think?” IEEE Softw. 15 (1
998): 46-54.
https://www.cs.kent.edu/~jmaletic/Prog-Comp/Papers/Hatton98.pdf

[^diederich12]: Jack Diederich. "Stop Writing Classes". Youtube video. Mar 15
, 2012.
https://youtu.be/o9pEzgHorH0?si=KWLVXsHuD_hwGtLz

# GATE's Input Data Format

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

# Help and Settings
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

The help text parser a  regular
expression to  find a word after two dashes:

       [-][-]([%S]+)[^=]+= ([%S]+)

That pattern is used in `l.settings` as follows:
```lua
function l.settings(s,    t,pat) --> a dictionary with the config options
  t,pat = {}, "[-][-]([%S]+)[^=]+= ([%S]+)" -- @\ding{202}@
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
# Examples and Demos Library

The code ends with a few dozen tests that test/demo differnt parts
of the system. For example, here are two examples:

- ``eg.oo`` tests the code for printing nested structures.
- ``eg.sym`` tests  class that accepts atoms and can report
   the mode and entropy of that collection (code for `SYM`
   is presented below).
```lua
local eg={}

function eg.oo() --> bool
  return l.o{a=1,b=2,c=3,d={e=3,f=4}}  == "{a: 1, b: 2, c: 3, d: {e: 3, f: 4}}" end

function eg.sym(      s,mode,e) --> bool
  s = SYM.new()
  for _, x in pairs{1,1,1,1,2,2,3} do s:add(x) end
  mode, e = s:mid(), s:div()
  print(mode, e)
  return 1.37 < e and e < 1.38 and mode == 1 end
```
All these tests can be run at the command line:
```
lua gate.lua -t oo
lua gate.lua -t sym
```
The example library needs some support code.  The `run` function
checks what is returned by each example (and if it is `false`, then
this test returns `true` indicating a failure). Note also that `run`
has does some _setup_ and _tearDown_:

- In the _tearDown_ step, we restore the global config.
- As _setup_, the global config is cached (so it can be 
  restored in `tearDown`) and the randomseed is restored
  to some default value.


```lua
local function run(k,   oops,b4) --> bool
  b4 = l.copy(the)          -- set up
  math.randomseed(the.seed) -- set up
  oops = eg[k]()==false
  io.stderr:write(l.fmt("# %s %s\n",oops and " FAIL" or " PASS",k))
  for k,v in pairs(b4) do the[k]=v end -- tear down
  return oops end
```

The `eg.all` command runs all the examples (via `run`)
and returns to the operating system the number of failures.
Note the use of `l.keys()`: this returns the example names,
sorted alphabetically (so the tests are run in that order).

```lua
function eg.all(     bad) --> failure count to operating system
  bad=0
  for _,k in pairs(l.keys(eg)) do
    if k ~= "all" then
      if run(k) then bad=bad+1 end end end
  io.stderr:write(l.fmt("# %s %s fail(s)\n",bad>0 and " FAIL" or " PASS",bad))
  os.exit(bad) end
```

Note that, like anything else in `eg`, `eg.all` can be called from the command line

```
lua gate.lua -t all
```

# Column Classes

GATE reads data and stores them in rows. Row columns are summarized in either
NUMeric or SYMbolic column classes. 
These classes respond to  the same 
polymorphic methods:

-  `mid()`: central tendancy (mean for NUMs and mode for SYMs);
- `div()`: the tendancy to move away from `mid()` (standard deviation for NUMs
  and entropy for SYMs);
- `small()`: indistinguishable differences. For SYMs, NUMs, that is zero or
   .35*standard deviation [^saw];
- `like(x):` how likely is `x` to belong to the distribution stored in
  the NUM or SYM

[^saw]: Sawilowsky, S.S.: New effect size rules of thumb. Journal of Modern Applied Statistical

## SYMbolic Classes
This class incrementally maintains a count of symbols seen so far, plus
the most seen symbol (the `mode`).
```lua
local SYM=is"SYM"
function SYM.new(s,n) --> SYM
  return isa(SYM,{txt=s or " ", at=n or 0, n=0, has={}, mode=nil, most=0}) end

function SYM:add(x) --> nil
  if x ~= "?" then
    self.n = self.n + 1
    self.has[x] = 1 + (self.has[x] or 0)
    if self.has[x] > self.most then
      self.most,self.mode = self.has[x], x end end end

function SYM:mid()  --> any
   return self.mode end

function SYM:div(    e) --> num
  e=0; for _,v in pairs(self.has) do e=e-v/self.n*math.log(v/self.n,2) end; return e end

function SYM:small() --> 0
   return 0 end

function SYM:like(x, prior) --> num
  return ((self.has[x] or 0) + the.m*prior)/(self.n +the.m) end
```

Note the last method (`like`) has some low frequency tricks to handle
lightly sampled regions of the data space (see `prior` and `the.m`).

\newpage

## NUMeric class
NUMerics incrementally update the control parameters of 
a Gaussian function [^gaussfun].

[^gaussfun]: https://en.wikipedia.org/wiki/Gaussian\_function

This class supports the same methods as SYMbolics; i.e. `mid()`, `div()`,
`small(x)`, `like(x,prior)`.
```lua
local NUM=is"NUM"
function NUM.new(s, n) --> NUM
  return isa(NUM, 
           {txt=s or " ",                                 -- column name
            at=n or 0,                                    -- column position
            n=0, mu=0, m2=0                               -- used to calcuate mean an sd
            hi=-1E30, lo=1E30,                            -- used when normalizing
            heaven = (s or ""):find"-$" and 0 or 1}) end  -- 0,1 for min,maximizationg

function NUM:add(x,     d) --> nil
  if x ~="?" then
    self.n  = self.n+1
    d       = x - self.mu
    self.mu = self.mu + d/self.n
    self.m2 = self.m2 + d*(x - self.mu)
    self.lo = math.min(x, self.lo)
    self.hi = math.max(x, self.hi) end end

function NUM:mid() --> num
  return self.mu end

function NUM:div() --> num
  return self.n < 2 and 0 or (self.m2/(self.n - 1))^.5 end
```
See Finch [^finch] for a proof that the above correctly
and incrementally calulates mean `mu` and standard
devaition  (in `div()`). 

[^finch]: Tony Finch,
"Incremental calculation of weighted mean and variance"
University of Cambridge Computing Service,
February 2009, https://fanf2.user.srcf.net/hermes/doc/antiforgery/stats.pdf

```lua
function NUM:small() --> num
  return the.cohen*self:div() end

function NUM:like(x,_,      nom,denom) --> num
  local mu, sd =  self:mid(), (self:div() + 1E-30)
  nom   = 2.718^(-.5*(x - mu)^2/(sd^2))
  denom = (sd*2.5 + 1E-30)
  return  nom/denom end
```
`NUM:like(x)` is just a standard gaussian proability distribution function[^norm].

[^norm]: https://en.wikipedia.org/wiki/Normal_distribution

NUMs have one specialy method called `norm(x)` that returns 0..1,
min..max.
```lua
function NUM:norm(x) --> num
  return x=="?" and x or (x - self.lo) / (self.hi - self.lo + 1E-30) end
```
# DATA, ROW, and COLS Class

In order to read rows and summarize their contents in NUMeric or
SYMbolic columns, we need three things:

1. Something to read the first row of our CSV files to create the right
   NUMs and SYMs columns. In the following, this will be the COLS object.
2. Some struct to hold the rows.
    In the following, this will be the ROW object.
3. Some place to store the rows and columns generated via points 1,2.
    In the following, this will be the DATA object.

So COLS store columns, ROWs stores a single record, and DATA stores the `rows`
and `cols`. Due to their interconnections, explaining  these
classes have  a  bit of a  "chicken and egg" problem. But lets see how we go: 

## COLS 
Convery a list of stings into sets of columns, according to the rules described in _GATE’s Input Data Format_.

Note some terminology-- our data represents a function $f$:

$$ \underbrace{y_1,y_2,...}_{\mathit{y,\;goals,\;dependents}} = f( \underbrace{x_1,x_2,x_3,x_4,x_5,x_6,x_7,x_8,x_9,x_{10}...}_{\mathit{x,\; independents,\; controllables,\;observables}})$$

COLS divides the columns into `all,x,y,klass`:

```lua
local COLS=is"COLS"
function COLS.new(row) --> COLS
  local x,y,all = {},{},{}
  local klass,col
  for at,txt in pairs(row.cells) do
    col = (txt:find"^[A-Z]" and NUM or SYM).new(txt,at)
    all[1+#all] = col
    if not txt:find"X$" then
      if txt:find"!$" then klass=col end
      (txt:find"[!+-]$" and y or x)[at] = col end end
  return isa(COLS,
           {x     = x,        -- all the independent columns 
            y     = y,        -- all the dependent columns
            all   = all,      -- all the columns
            klass = klass,    -- just the klass column (if it exists)
            names = row.cells -- names of all the columns
           }) end
```
The  `COLS:add()` method takes a ROW and updates the `x,y` columns. 
```lua
-- Update
function COLS:add(row) --> row
  for _,cols in pairs{self.x, self.y} do
    for _,col in pairs(cols) do
      col:add(row.cells[col.at]) end end
  return row end
```

\newpage
## ROWs

COLS store columns, ROWs stores a single record.

```lua
local ROW=is"ROW"
function ROW.new(t) return isa(ROW, { cells = t }) end
```
ROWs know how to compute the distance from heaven (discussed above in
_GATE’s Input Data Format_). To do so, uses two features of DATA
(defined below):

- `data.cols` : what comes out of the above COLS code;
- `data.rows` : stores all the rows.

```lua
function ROW:d2h(data, d, n) --> num in the range 0..1
  d, n = 0, 0
  for _, col in pairs(data.cols.y) do
      n = n + 1
      d = d + math.abs(col.heaven - col:norm(self.cells[col.at])) ^ 2 end
  return d ^ .5 / n ^ .5 end
```
ROWs implment the likelihood calculation of Baye's rule

-  Supppose we have rows describing
`nHypotheses` number different things (dogs, horse, cats) etc. We can work out how much
a ROW `like`s being a dog, horse, or cat.
- The `prior` is the ratio of (e.g.)
`dogs` amongst all the `dogs,horses,cats`. e.g. Suppose we have 100 dogs
horses and cats. Then our prior belief in dogs is $\frac{100}{300}\;=\;0.33$.
- Then we multiply the prior
  by how frequently we see ROW values 
  amongst (e.g.) the dogs; i.e.:

$$\mathit{like}(H|E) = \mathit{prior} \times \sum_x \mathit{like}(E_x|H)$$

Here $H$ is one of the hypotheses (e.g. dogs, horses, or cats);
and $E$ is the _evidence_ seen in each hypothesis (this is just the
distributions seen in ROWs of a DATA).

This likelihood Calculation is coded as follows:
 
```lua
function ROW:like(data,n,nHypotheses,       prior,out,v,inc) --> num
  prior = (#data.rows + the.k) / (n + the.k * nHypotheses)
  out   = math.log(prior)
  for _,col in pairs(data.cols.x) do
    v= self.cells[col.at]
    if v ~= "?" then
      inc = col:like(v,prior)
      out = out + math.log(inc) end end
  return math.exp(1)^out end
```
(Aside: we use some low frequency tricks when calculating _prior_, see
`the.k`.)

Once we can find `like` for one hypothesis, we can implmeent
a classifier that searches many hypotheses:

```lua
function ROW:likes(datas,       n,nHypotheses,most,tmp,out) --> sym,num
  n,nHypotheses = 0,0
  for k,data in pairs(datas) do
    n = n + #data.rows
    nHypotheses = 1 + nHypotheses end
  for k,data in pairs(datas) do
    tmp = self:like(data,n,nHypotheses)
    if most==nil or tmp > most then most,out = tmp,k end end
  return out,most end
```
\newpage
## DATA

```lua
local DATA=is"DATA"
function DATA.new(src,  fun,     self)
  self = isa(DATA,{rows={}, cols=nil})
  if   type(src) == "string"
  then for _,x in l.csv(src)       do self:add(x, fun) end
  else for _,x in pairs(src or {}) do self:add(x, fun) end end
  return self end
```
Update. First time through, assume the row defines the columns.
Otherwise, update the columns then store the rows. If `fun` is
defined, call it before updating anything.
```lua
function DATA:add(t,  fun,row)
  row = t.cells and t or ROW.new(t)
  if   self.cols
  then if fun then fun(self,row) end
       self.rows[1 + #self.rows] = self.cols:add(row)
  else self.cols = COLS.new(row) end end

function DATA:mid(cols,   u)
  u = {}; for _, col in pairs(cols or self.cols.all) do u[1 + #u] = col:mid() end
  return ROW.new(u) end

function DATA:div(cols,    u)
  u = {}; for _, col in pairs(cols or self.cols.all) do u[1 + #u] = col:div() end;
  return ROW.new(u) end

function DATA:small(    u)
  u = {}; for _, col in pairs(self.cols.all) do u[1 + #u] = col:small(); end
  return ROW.new(u) end

function DATA:stats(cols,fun,ndivs,    u)
  u = {[".N"] = #self.rows}
  for _,col in pairs(self.cols[cols or "y"]) do
    u[col.txt] = l.rnd(getmetatable(col)[fun or "mid"](col), ndivs) end
  return u end
```
# And Finally, GATE

```lua
function DATA:gate(budget0,budget,some)
  local rows,lite,dark
  local stats,bests = {},{}
  rows = l.shuffle(self.rows)
  lite = l.slice(rows,1,budget0)
  dark = l.slice(rows, budget0+1)
  for i=1,budget do
    local best, rest     = self:bestRest(lite, (#lite)^some)  -- assess
    local todo, selected = self:split(best,rest,lite,dark)
    stats[i] = selected:mid()
    bests[i] = best.rows[1]
    table.insert(lite, table.remove(dark,todo)) end
  return stats,bests end
```
Find the row scoring based on our acquite function.
```lua
function DATA:split(best,rest,lite,dark)
  local selected,max,out
  selected = DATA.new{self.cols.names}
  max = 1E30
  out = 1
  for i,row in pairs(dark) do
    local b,r,tmp
    b = row:like(best, #lite, 2)
    r = row:like(rest, #lite, 2)
    if b>r then selected:add(row) end
    tmp = math.abs(b+r) / math.abs(b-r+1E-300)
    --print(b,r,tmp)
    if tmp > max then out,max = i,tmp end end
  return out,selected end
```
Sort on distance to heaven, split off the first `want` items to return
a `best` and `rest` data.
```lua
function DATA:bestRest(rows, want, best, rest, top)
    table.sort(rows, function(a, b) return a:d2h(self) < b:d2h(self) end)
    best, rest = { self.cols.names }, { self.cols.names }
    for i, row in pairs(rows) do
        if i <= want then best[1 + #best] = row else rest[1 + #rest] = row end
    end
    return DATA.new(best), DATA.new(rest)
end
```
# Appendix: A Quick Tour of Lua

Source: from https://github.com/rstacruz/cheatsheets/.

Lua looks like a simple language (see below) but it has some advanced features:

- first-class functions, 
- garbage collection, 
- closures, 
- proper tail calls, 
- iterators,
- coercion (automatic conversion between string and number values at run time), 
- coroutines (cooperative multitasking) dynamic module loading.


## Basic examples

### References

- <https://www.lua.org/pil/13.html>

### Comments

    -- comment
    --[[ Multiline
         comment ]]

### Invoking functions

    print()
    print("Hi")

    -- You can omit parentheses if the argument is one string or table literal
    print "Hello World"     <-->     print("Hello World")
    dofile 'a.lua'          <-->     dofile ('a.lua')
    print [[a multi-line    <-->     print([[a multi-line
     message]]                        message]])
    f{x=10, y=20}           <-->     f({x=10, y=20})
    type{}                  <-->     type({})

### Tables / arrays

    t = {}
    t = { a = 1, b = 2 }
    t.a = function() ... end

    t = { ["hello"] = 200 }
    t.hello

    -- Remember, arrays are also tables
    array = { "a", "b", "c", "d" }
    print(array[2])       -- "b" (one-indexed)
    print(#array)         -- 4 (length)

### Loops

    while condition do
    end

    for i = 1,5 do
    end

    for i = start,finish,delta do
    end

    for k,v in pairs(tab) do
    end

    repeat
    until condition

    -- Breaking out:
    while x do
      if condition then break end
    end

### Conditionals

    if condition1 then
      print("yes")
    elseif condition2 then
      print("maybe")
    else
      print("no")
    end

   print(condition1 and "yes" or (condition2 and "maybe" or "no")

### Variables

Variables are global by default. They can be mde local using the `local` keyword, or if they are included as
extra arguments in functions.


    local x = 2
    two, four = 2, 4

### Functions

    function myFunction()
      return 1
    end

If `myFunctionWithArgs` is called with one arguments, then `b` is a local variables.

    function myFunctionWithArgs(a, b)
      -- ...
    end

    myFunction()

    anonymousFunctions(function()
      -- ...
    end)

    -- Not exported in the module
    local function myPrivateFunction()
    end

    -- Splats
    function doAction(action, ...)
      print("Doing '"..action.."' to", ...)
      --> print("Doing 'write' to", "Shirley", "Abed")
    end

    doAction('write', "Shirley", "Abed")

### Lookups

    mytable = { x = 2, y = function() .. end }

    -- The same:
    mytable.x
    mytable['x']

    -- Syntactic sugar, these are equivalent:
    mytable.y(mytable)
    mytable:y()

    mytable.y(mytable, a, b)
    mytable:y(a, b)

    function X:y(z) .. end
    function X.y(self, z) .. end

## More concepts

### Constants

    nil
    false
    true

## Operators (and their metatable names)

### Logic

    -- Logic (and/or)
    nil and false  --> nil
    false and nil  --> false
    0 and 20       --> 20
    10 and 20      --> 20

### Tables

    -- Length
    -- __len(array)
    #array


    -- Indexing
    -- __index(table, key)
    t[key]
    t.key

## API

### API: Some Global Functions

    assert(x)    -- x or (raise an error)
    assert(x, "failed")

    type(var)   -- "nil" | "number" | "string" | "boolean" | "table" | "function" | "thread" | "userdata"

    _ENV  -- Global context
    setfenv(1, {})  -- 1: current function, 2: caller, and so on -- {}: the new _G

    pairs(t)     -- iterable list of {key, value}

    tonumber("34")
    tonumber("8f", 16)

### API: Strings

    'string'..'concatenation'

    s = "Hello"
    s:upper()
    s:lower()
    s:len()    -- Just like #s

    s:find()
    s:gfind()

    s:match()
    s:gmatch()

    s:sub()
    s:gsub()

    s:rep()
    s:char()
    s:dump()
    s:reverse()
    s:byte()
    s:format()

### API: Tables

    table.foreach(t, function(row) ... end)
    table.setn
    table.insert(t, 21)          -- append (--> t[#t+1] = 21)
    table.insert(t, 4, 99)
    table.getn
    table.concat
    table.sort
    table.remove(t, 4)

### API: Math

    math.abs     math.acos    math.asin       math.atan    math.atan2
    math.ceil    math.cos     math.cosh       math.deg     math.exp
    math.floor   math.fmod    math.frexp      math.ldexp   math.log
    math.log10   math.max     math.min        math.modf    math.pow
    math.rad     math.random  math.randomseed math.sin     math.sinh
    math.sqrt    math.tan     math.tanh

### API: Misc

    io.output(io.open("file.txt", "w"))
    io.write(x)
    io.close()

    for line in io.lines("file.txt")

    file = assert(io.open("file.txt", "r"))
    file:read()
    file:lines()
    file:close()
