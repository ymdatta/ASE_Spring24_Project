local the,help = {},[[

smooth: simple Bayesian sequential model optimization
(c) 2023, Tim Menzies, BSD-2

USAGE:
  lua smooth.lua [OPTIONS] [eg ACTION]

OPTIONS:
  -b --bin    number of bins                    = 10
  -c --cohen  small effect size sd*cohen        = .35
  -e --eg     start up action                   = help
  -f --file   csv data file name                = ../data/auto93.csv
  -h --help   show help                         = false
  -k --k      handle low class frequencies      = 1
  -m --m      handle low attribute frequencies  = 2
  -s --seed   random number seed                = 1234567891
  -w --wait   wait before classifications       = 20]]

local b4={}; for k,_ in pairs(_ENV) do b4[k]=k end
local l={}  -- library utils, defined at end of file

-- --------- --------- --------- --------- --------- --------- --------- --------- ------
local function NUM(s,n) return {txt=s or '', at=n or 0, n=0, f={},mu=0, m2=0, sd=0}   end
local function SYM(s,n) return {txt=s or '', at=n or 0, n=0, f={},has={}, isSym=true} end
local function COL(s,n) return (s:find'^[A-Z]' and NUM or SYM)(s,n) end

local function col(col1,x,     d)
  if x ~= "?" then
    col1.n = col1.n + 1
    if col1.isSym then col1.has[x] = 1+(col1.has[x] or 0) else
      d = x - col1.mu
      col1.mu = col1.mu + d/col1.n
      col1.m2 = col1.m2 + d*(x - col1.mu)
      col1.sd = col1.n < 2 and 0 or (col1.m2/(col1.n - 1))^.5  end end end

local function discretize(col1,x)
  return (col1.isSym or x=="?") and x or ((x-col1.mu) / col1.sd/(6/the.bins) + .5)//1 end

local function inc2(t,x,y,     a,b)
  a = t[x];  if a==nil then a={};  t[x] = a end
  b = a[y];  b = b and b+1 or 1 
  a[y] = b;
  return a end

local function discretizes(data1,row1,    f)
  f = {}
  for _, col1 in pairs(data1.cols.all) do
    if col1.at ~= data1.klass.at and not col1.isSym then
      x = discretize(col1, row1.cells[col1.at])
      row1.cooked[col1.at] = x
      if x ~= "?" then
        inc2(f, row1[data1.cols.klass.at], {col1.at, x}) end end end 
  return f end

local function COLS(t,    all,klass)
  all, klass = {},nil
  for k,v in pairs(t) do
    all[1+#all] = COL(v,k)
    if v:find'!$' then klass = all[#all] end end
  return {all=all, names=t, klass=klass, f={}} end

local function cols(cols1,row1)
  for _, col1 in pairs(cols1.all) do col(col1, row1.cells[col1.at]) end
  return row1 end

local function ROW(t) return {cells=t, cooked={}} end

local function data(data1, xs, row1)
  row1 = xs.cells and xs or ROW(xs)
  if   data1.cols
  then data1.rows[1 + #data1.rows] = cols(data1.cols, row1)
  else data1.cols = COLS(row1.cells) end end

local function DATA(src,    data1)
  data1 = {rows = {}, cols = nil,  f={}}
  for   row1 in l.rows(src) do data(data1, row1) end
  for _,row1 in pairs(data1.rows) do discretizes(data1, row1) end
  return data1 end

local function clone(data1,  rows,    data2)
  data2 = DATA{ data1.cols.names }
  for row1 in as.rows(rows or {}) do data(data2, row1) end
  return data2 end

local fmt = string.format

-- String to int or float or nil or bool.
local function coerce(s1,    fun)
  function fun(s2)
    if s2=="nil" then return nil
    else return s2=="true" or (s2~="false" and s2) end end
  return math.tointeger(s1) or tonumber(s1) or fun(s1:match'^%s*(.*%S)') end

-- Iterate over the rows in either file `src` or list `src`. 
function l.rows(src)
  return type(src)=="string" and l.csv(src) or l.items(src or {}) end

function l.items(t,    n)
  n=0; return function() if n<#t then n=n+1; return t[n] end end end

function l.csv(src)
  src = src=="-" and io.stdin or io.input(src)
  return function(   s)
    s = io.read()
    if s then
      t={}; for s1 in s:gmatch("([^,]+)") do t[1+#t] = coerce(s1) end; return ROW(t)
    else
      io.close(src) end end end

function l.o(x,      y,gap, keys, arrays)
  function keys(u)
    for k, v in pairs(x) do u[1 + #u] = fmt(":%s %s", k, l.o(v)) end; table.sort(u)
    return u end
  function arrays(u)
    for k, v in pairs(x) do u[k] = l.o(v) end
    return u end
  if type(x) ~= "table" then return tostring(x) end
  y   = (#x==0 and keys or arrays){}
  gap = #x==0 and " " or ", "
  return "{" .. table.concat(y, gap) .. "}" end

function l.oo(x) print(l.o(x)); return x end

function l.cli(t)
  for k, v in pairs(t) do
    v = tostring(v)
    for argv,s in pairs(arg) do
      if s=="-"..(k:sub(1,1)) or s=="--"..k then
        v = v=="true" and "false" or v=="false" and "true" or arg[argv + 1]
        t[k] = coerce(v) end end end
  return t end

-- --------- --------- --------- --------- --------- --------- --------- --------- ------
local o, oo = l.o, l.oo
local eg = {}
function eg.all() for k, _ in pairs(eg) do if k ~= "all" then eg.one(k) end end end

function eg.one(k,      old)
    old = {}; for k0,v0 in pairs(the) do old[k0] = v0 end
    math.randomseed(the.seed)
    print(fmt(" %s %s",eg[k]()==false and "❌ FAIL" or "✅ PASS", k))
    for k1,v1 in pairs(old) do the[k1] = v1 end end

function eg.help() return print(help) end

function eg.the() io.write(o(the)) end

local function norm(mu, sd)
  return (mu or 0) + (sd or 1) * math.sqrt(-2 * math.log(math.random()))
                               * math.cos(2 * math.pi * math.random()) end
function eg.norm(     u)
  u={}; for _ = 1,100 do u[1+#u] = norm(100,10)//1 end
  table.sort(u)
  oo(u) end

function eg.num(    num1,mu,sd)
  num1 = NUM()
  for _ = 1, 1000 do col(num1, norm(10, 1)) end
  mu, sd = num1.mu, num1.sd
  return 9.95 < mu and mu < 10.05 and 0.975 < sd and sd < 1.025 end

function eg.rows()
    for t in l.rows(the.file) do print(100, o(t)) end
    print ""
    for t in l.rows {
        { 8, 318, 210, 4382, 13.500, 70, 1, 10 },
        { 8, 429, 208, 4633, 11,     72, 1, 10 },
        { 8, 400, 150, 4997, 14,     73, 1, 10 },
        { 8, 350, 180, 3664, 11,     73, 1, 10 } } do print(200, o(t)) end end

function eg.data()
  for _row in pairs(DATA(the.file).rows) do oo(row) end end

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

-- --------- --------- --------- --------- --------- --------- --------- --------- ------
for k, v in help:gmatch("\n[%s]+[-][%S][%s]+[-][-]([%S]+)[^\n]+= ([%S]+)") do
  the[k] = coerce(v)  end

the = l.cli(the)
eg.one(the.eg)
for k,_ in pairs(_ENV) do if not b4[k] then print("?",k) end end