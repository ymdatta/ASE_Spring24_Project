-- Some trics
local the,help = {},[[

smooth: simple Bayesian sequential model optimization
(c) 2023, Tim Menzies, BSD-2

USAGE:
  lua smooth.lua [OPTIONS] [eg ACTION]

OPTIONS:
  -b --bins    number of bins                    = 10
  -c --cohen  small effect size sd*cohen        = .35
  -e --eg     start up action                   = help
  -f --file   csv data file name                = ../data/diabetes.csv
  -h --help   show help                         = false
  -k --k      handle low class frequencies      = 1
  -m --m      handle low attribute frequencies  = 2
  -s --seed   random number seed                = 1234567891
  -w --wait   wait before classifications       = 20]]
-- ----------------------------------------------------------------------------
-- ## Preliminaries

-- `b4` is used at end to lint for rogue globals,
local b4 = {}; for k, _ in pairs(_ENV) do b4[k] = k end

-- Class constructors
local ROW, DATA, NUM, SYM, COL, COLS

-- Methods
local clone, col, cols, data, discretize,discretizes

-- Library utils, defined later.
local cli, coerce, csv, fmt, inc2, items, lt, o, oo, rows, sort

-- ----------------------------------------------------------------------------
-- ## One Column

-- Create   columns for `NUM`eric  or `SYM`bolic values.
function NUM(s,n) return {txt=s or '', at=n or 0, n=0, f={},mu=0, m2=0, sd=0}   end
function SYM(s,n) return {txt=s or '', at=n or 0, n=0, f={},has={}, isSym=true} end
function COL(s,n) return (s:find'^[A-Z]' and NUM or SYM)(s,n) end

-- Update.
function col(col1,x,     d)
  if x ~= "?" then
    col1.n = col1.n + 1
    if col1.isSym then col1.has[x] = 1+(col1.has[x] or 0) else
      d = x - col1.mu
      col1.mu = col1.mu + d/col1.n
      col1.m2 = col1.m2 + d*(x - col1.mu)
      col1.sd = col1.n < 2 and 0 or (col1.m2/(col1.n - 1))^.5  end end 
  return x end

-- ## Sets of columns

-- Create  a list of column names into columns.
function COLS(t,     all,klass)
  all, klass = {},nil
  for k,v in pairs(t) do
    all[1+#all] = COL(v,k)
    if v:find'!$' then klass = all[#all] end end
  return {all=all, names=t, klass=klass, f={}} end

-- Update.
function cols(cols1,row1)
  for _, col1 in pairs(cols1.all) do col(col1, row1.cells[col1.at]) end
  return row1 end

-- ----------------------------------------------------------------------------
-- ## Row

-- Create.
function ROW(t) return {cells=t, cooked={}} end

-- ----------------------------------------------------------------------------
-- ## DATA = rows + COLS

-- Create.
function DATA(src,    data1)
  data1 = {rows = {}, cols = nil,  f={}}
  for   row1 in rows(src) do data(data1, row1) end
  for _,row1 in pairs(data1.rows) do discretizes(data1, row1) end
  return data1 end

-- Update.
function data(data1, xs, row1)
  row1 = xs.cells and xs or ROW(xs)
  if   data1.cols
  then data1.rows[1 + #data1.rows] = cols(data1.cols, row1)
  else data1.cols = COLS(row1.cells) end end

-- Duplicate the structure of a `DATA`.
function clone(data1,  rows,    data2)
  data2 = DATA{ data1.cols.names }
  for row1 in rows(rows or {}) do data(data2, row1) end
  return data2 end

-- ----------------------------------------------------------------------------
-- ## Descretization
-- Map a column value into a small number of values. Used `m` for the
-- middle value and  `l,j,etc` for values under middle and 
-- `n,o,p,etc' for values above middle.
function discretize(col1,x,     y)
  y= (col1.isSym or x=="?") and x or ((the.bins)*(x-col1.mu) / col1.sd / 6 + .5)//1 
  return string.char(109+y) end

-- Descrretize row values and, as a side effect, update  a `f` frequency table
-- `f[klass][{col.at, val}]=count`. 
function discretizes(data1,row1,f,    x)
  f = f or {}
  for _, col1 in pairs(data1.cols.all) do
    x = row1.cells[col1.at]
    row1.cooked[col1.at] = x   
    if col1.at ~= data1.cols.klass.at and not col1.isSym then
      x = discretize(col1, x)
      row1.cooked[col1.at] = x
      if x ~= "?" then
        inc2(f, row1.cells[data1.cols.klass.at], {col1.at, x}) end end end 
  return f end

-- ----------------------------------------------------------------------------
-- ## Library Routines

-- ### Lists

-- Update frequency table.
function inc2(t,x,y,     a,b)
  a = t[x]; if a==nil then a={}; t[x]=a end
  b = a[y]; if b==nil then b=1 else b=b+1; a[y] = b; end end

-- Iterator.
function items(t,    n)
  n=0; return function() if n<#t then n=n+1; return t[n] end end end

function sort(t, fun,     u)
  if #t==0 then u={}; for _,x in pairs(t) do u[1+#u]=x; end; return sort(u,fun) end
  table.sort(t,fun); return t end

function lt(x) return function(a, b) return a[x] < b[x] end end

-- ### Thing to String

-- Emulate `pritnf`.
fmt = string.format

-- Generate a string from a nested structure.
function o(x,      y,gap, keys, arrays)
  function keys(u)
    for k, v in pairs(x) do u[1 + #u] = fmt(":%s %s", k, o(v)) end; table.sort(u);return u end
  function arrays(u)
    for k, v in pairs(x) do u[k] = o(v) end; return u end
  if type(x) ~= "table" then return tostring(x) end
  y   = (#x==0 and keys or arrays){}
  gap = #x==0 and " " or ", "
  return "{" .. table.concat(y, gap) .. "}" end

-- Print a string representing a nested structure. Return that structure.
function oo(x) print(o(x)); return x end

-- ### String to Thing

-- String to int or float or nil or bool.
local function coerce(s1,    fun)
  function fun(s2)
    if s2=="nil" then return nil
    else return s2=="true" or (s2~="false" and s2) end end
  return math.tointeger(s1) or tonumber(s1) or fun(s1:match'^%s*(.*%S)') end

-- Iterate over the rows in either file `src` or list `src`. 
function rows(src)
  return type(src)=="string" and csv(src) or items(src or {}) end

-- Iterator for files.
function csv(src)
  src = src=="-" and io.stdin or io.input(src)
  return function(      s,t)
    s = io.read()
    if s then
      t={}; for s1 in s:gmatch("([^,]+)") do t[1+#t] = coerce(s1) end; return ROW(t)
    else
      io.close(src) end end end

-- Update table values from CLI `--key value` (or `-k value`). If the  
-- default value is boolean, then you don't need value; 
-- (so `--key` (or `-k`) just flips the default).
function cli(t)
  for k, v in pairs(t) do
    v = tostring(v)
    for argv,s in pairs(arg) do
      if s=="-"..(k:sub(1,1)) or s=="--"..k then
        v = v=="true" and "false" or v=="false" and "true" or arg[argv + 1]
        t[k] = coerce(v) end end end
  return t end

-- ----------------------------------------------------------------------------
-- ## Examples

local eg = {}

-- Run all examples
function eg.all() for k, _ in pairs(eg) do if k ~= "all" then eg.one(k) end end end

-- Run one example, resetting the random seed and control settings beforehand.
function eg.one(k,      old)
    old = {}; for k0,v0 in pairs(the) do old[k0] = v0 end
    math.randomseed(the.seed)
    print(fmt(" %s %s",eg[k]()==false and "❌ FAIL" or "✅ PASS", k))
    for k1,v1 in pairs(old) do the[k1] = v1 end end

function eg.help() return os.exit(print(help)) end

function eg.the() oo(the) end

local function norm(mu, sd)
  return (mu or 0) + (sd or 1) * math.sqrt(-2 * math.log(math.random()))
                               * math.cos(2 * math.pi * math.random()) end

function eg.num(      t,num1,mu,sd)
  t,num1 = {},NUM()
  for _ = 1, 1000 do t[1 + #t] = col(num1, norm(10, 2)) end
  mu, sd = num1.mu, num1.sd
  print(mu, sd)
  return 9.9 < mu and mu < 10 and 1.95 < sd and sd < 2 end

function eg.discretize(           max,num1,sym1,mu,sd,t,u,n,y,v,i)
  the.bins = 10
  t, u, v, num1, sym1 = {}, {},{}, NUM(), SYM()
  max=1000
  for _ = 1, max do t[1+#t]= col(num1, norm(10,2)) end
  table.sort(t)
  for _,x in pairs(t) do
    y = discretize(num1, x)
    col(sym1,y)
    u[y] = y
    v[y] =x  end
  i=0
  for _, y in pairs(sort(u)) do
    n = sym1.has[y]
    i=i+1
    print(fmt("%2s %6s%%   %4.1f  %s",y, n/10, v[y], ('*'):rep(n//10))) end end

function eg.rows()
    for t in rows(the.file) do print(100, o(t)) end
    print ""
    for t in rows {
        { 8, 318, 210, 4382, 13.500, 70, 1, 10 },
        { 8, 429, 208, 4633, 11,     72, 1, 10 },
        { 8, 400, 150, 4997, 14,     73, 1, 10 },
        { 8, 350, 180, 3664, 11,     73, 1, 10 } } do print(200, o(t)) end end

function eg.data()
  for _,row in pairs(DATA(the.file).rows) do oo(row) end end

-- return ((col1.has[x] or 0) + the.m*prior)/(col1.n+the.m)

  -- function l.likesMost(t,datas,n,h,     most,tmp,out)
  --   most = -1E30
  --   for k,data in pairs(datas) do
  --     tmp = l.likes(t,data,n,h)
  --     if tmp > most then out,most = k,tmp end end
  --   return out,most end
  
  -- -- Likes of one row `t` in one `data`.           
  -- -- _P(H|E) = P(E|H) P(H)/P(E)_      
  -- -- or with our crrrent data structures:           
  -- -- _P(data|t) = P(t|data) P(data) / P(t)_      
  -- function l.likes(t,data,n,h,       prior,out,col1,inc)
  --   prior = (#data.rows + the.k) / (n + the.k * h)
  --   out   = math.log(prior)
  --   for at,v in pairs(t) do
  --     col1 = data.cols.x[at]
  --     if col1 and v ~= "?" then
  --       inc = l.like(col1,v,prior)
  --       out = out + math.log(inc) end end
  --   return out end

-- ----------------------------------------------------------------------------
-- ## Start up

-- Convert help string to configuration settings.
for k, v in help:gmatch("\n[%s]+[-][%S][%s]+[-][-]([%S]+)[^\n]+= ([%S]+)") do
  the[k] = coerce(v)  end

-- Call an example (after updating the configuration file from the command line).
eg.one(cli(the).eg)

-- Check for rogue locals.
for k,_ in pairs(_ENV) do if not b4[k] then print("?",k) end end