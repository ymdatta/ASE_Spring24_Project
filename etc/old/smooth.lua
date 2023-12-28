-- .
local the,help = {},[[
smooth: simple Bayesian sequential model optimization
(c) 2023, Tim Menzies, BSD-2

USAGE:
  lua smooth.lua [OPTIONS] [eg ACTION]

OPTIONS:
  -c --cohen  small effect size sd*cohen        = .35
  -e --eg     start up action                   = help
  -f --file   csv data file name                = ../data/diabetes.csv
  -h --help   show help                         = false
  -k --k      low class frequency kludge        = 1  
  -m --m      low attribute frequency kludge    = 2
  -s --seed   random number seed                = 1234567891
  -w --wait   wait before classifications       = 20]]
-- ----------------------------------------------------------------------------
-- ## Preliminaries

-- `b4` is used at end to lint for rogue globals.
local b4={}; for k, _ in pairs(_ENV) do b4[k]=k end
-- Class constructors
local COL,COLS,DATA,DATAS,NUM,ROW,SMOOTH,SYM
-- Methods
local clone,col,cols,d2h,data,div,like,likes,likesMost, mid,norm,same
-- Lua is a "batteries not included" langauge. So here are my batteries.
local cli,coerce,csv,ent,fmt,gt,items,lt
local mode,o,oo,R,report,rnd,rows,shuffle,sort,stats
-- ----------------------------------------------------------------------------
-- ## One Column

-- Create   columns for `NUM`eric  or `SYM`bolic values.
function NUM(s,n) return {heaven = s:find"-$" and 0 or 1,
                          txt=s or '',at=n or 0,n=0, f={},mu=0, m2=0, sd=0}   end
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

-- ### Queries

-- `mid` = middle = central tendency.
function mid(col1)
  return col1.isSym and mode(col1.has) or col1.mu end

-- `div` = diversity = tendency to avoid the center.
function div(col1)
  return col1.isSym and ent(col1.has) or col1.sd end

-- norm 
function norm(num1,x) return (x-num1.lo) / (num1.hi - num.lo) end

-- same
function same(num1,num2) 
  return the.cohen > ((num1.n-1)*div(num1)^2 + (num2.n-1)*div(num2)^2 /
                      (num1.n + num2.n - 2))^.5   end
-- ----------------------------------------------------------------------------
-- ## Sets of columns

-- Create  a list of column names into columns.
function COLS(t,     all,klass,col1,x,y)
  x, y, all, klass = {}, {}, {},nil
  for k,v in pairs(t) do
    col1 = COL(v,k)
    all[1+#all] = col1
    if not v:find"X$" then
      if v:find'!$' then klass = col1 end
      table.insert(v:find"[+-!]" and y or x,col1) end end
  return {x=x, all=all, names=t, klass=klass} end

-- Update.
function cols(cols1,row1)
  for _, col1 in pairs(cols1.all) do col(col1, row1.cells[col1.at]) end
  return row1 end
-- ----------------------------------------------------------------------------
-- ## Row

-- Create.
function ROW(t) return {cells=t} end

function d2h(row1,data1)
  n,d=0,0
  for _,col1 in pairs(data1.cols.y) do
    n=n+1
    d = d + (col1.heaven - norm(col1, row1.cells[col1.at]))^2 end
  return d^.5 / n^.5 end

-- ----------------------------------------------------------------------------
-- ## DATA = rows + COLS

-- Create.
function DATA(src,    data1)
  data1 = {rows = {}, cols = nil}
  for _,row1 in rows(src) do data(data1, row1) end
  return data1 end

-- Update.
function data(data1, xs, row1)
  row1 = xs.cells and xs or ROW(xs)
  if   data1.cols
  then data1.rows[1 + #data1.rows] = cols(data1.cols, row1)
  else data1.cols = COLS(row1.cells) end end

-- Duplicate the structure of a `DATA`.
function clone(data1,  rows1,    data2)
  data2 = DATA { data1.cols.names } 
  for _,row1 in rows(rows1 or {}) do data(data2, row1) end
  return data2 end

-- data2stats
function stats(data1,   fun,ndecs,cols,    t)
  t = {[".N"]=#data1.rows}
  for _,col1 in pairs(data1.cols[cols or "x"]) do
    t[col1.txt] = rnd( (fun or mid)(col1), ndecs) end
  return t end

function DATAS(src,  fun,     new,all,want)
  fun= fun or function(...) return true end
  new = {datas={},all=nil}
  for i,t  in rows(src) do 
    if   i==1 
    then new.all = DATA{t}
    else want = t[new.all.cols.klass.at]
         fun(new.datas, i, want, t)
         new.datas[want] = new.datas[want] or clone(new.all)
         data(new.datas[want],t)
         data(new.all,t) end end
  return new end

-- ----------------------------------------------------------------------------
-- ## Like
function like(col1,x,prior,     mu,sd,nom,denom) 
  if   col1.isSym 
  then return ((col1.has[x] or 0) + the.m*prior)/(col1.n +the.m) 
  else mu,sd = mid(col1), div(col1)
       nom    = math.exp(-.5*((x - mu)/sd)^2)
       denom  = (sd*((2*math.pi)^0.5))
       return nom/(denom  + 1E-30) end end
 
-- Likes of one row `t` in one `data`.           
-- _P(H|E) = P(E|H) P(H)/P(E)_      
-- or with our crrrent data structures:           
-- _P(data|t) = P(t|data) P(data) / P(t)_      
function likes(t,data1,n,nHypotheses,       prior,out,col1,inc)
  prior = (#data1.rows + the.k) / (n + the.k * nHypotheses)
  out   = math.log(prior)
  for at,v in pairs(t) do
    col1 = data1.cols.x[at]
    if col1 and col1.at ~= data1.cols.klass.at and v ~= "?" then
      inc = like(col1,v,prior)
      out = out + math.log(inc) end end
  return out end

-- Max like of one row `t` across many  `datas`
-- (and here, `data` == `H`).     
-- _argmax(i)  P(H<sub>i</sub>|E)_      
function likesMost(t, datas,      n,nHypotheses,most,tmp,out)
  n, nHypotheses, most = 0, 0, -1E3
  for _,data1 in pairs(datas) do n=n+#data1.rows; nHypotheses=nHypotheses+1 end
  for k,data1 in pairs(datas) do
    tmp = likes(t,data1,n,nHypotheses)
    if tmp > most then out,most = k,tmp end end
  return out,most end

-- ----------------------------------------------------------------------------
-- ## Smooth

function SMOOTH(src,     data1,rows1,out,seen,b,r,now,most,at)
  data1 = DATA(src)
  rows1 = shuffle(data1.rows)
  out={}
  seen={}
  for i=1,4 do seen[1+#seen]= table.remove(rows1,i) end
  for j=1,10 do
    seen = sort(seen, function(a,b) return d2h(a,data1) < d2h(b,data1) end)
    best,rest = clone(data1), clone(data1)
    for i,row1 in pairs(seen) do
      data( i <= (#seen)^.5 and best or rest, row1) end
    out[1+#out] = stats(best,mid,2,"y")
    if j > 1 and same(out[#out], out[#out-1]) then
      break end
    for i,row1 in pairs(rows1) do
      b,r = likes(best,row1,#t,2), like(rest,row1,#t,2)
      now = (b+r)/math.abs(b - r + 1E-30)
      if now > most then most,at = now,i end end
    table.insert(seen, table.remove(rows1,at)) end
  return out end

  
-- ----------------------------------------------------------------------------
-- ## Library Routines

-- ### Short-cuts

-- Random number genertion.
R=math.random
-- Emulate printf
fmt=string.format

-- ### Numbers

-- Round to `ndecs` decimals.
function rnd(n, ndecs)
  if type(n) ~= "number" then return n end
  if math.floor(n) == n  then return n end
  local mult = 10^(ndecs or 2)
  return math.floor(n * mult + 0.5) / mult end

-- ### Lists

-- Mode
function mode(t,  out,most)
  most=0
  for x,n in pairs(t) do if n>most then out,most = x,n end end
  return out end

-- Entropy
function ent(t,  e,N)
  e,N = 0,0
  for _,n in pairs(t) do N = N+n end
  for _,n in pairs(t) do e = e - n/N * math.log(n/N,2) end
  return e end

        
-- return a (shallow) copy, sorted.
function sort(t, fun,     u)
  u={}; for _,x in pairs(t) do u[1+#u]=x; end;
  table.sort(u,fun); return u end

-- Functions to sort up or down on a field `x`
function lt(x) return function(a, b) return a[x] < b[x] end end
function gt(x) return function(a, b) return a[x] > b[x] end end

-- Return a (shallow) copy, randomly shulled.
function shuffle(t,    u,j)
  u={}; for _,x in pairs(t) do u[1+#u]=x; end;
  for i = #u,2,-1 do j=R(i); u[i],u[j] = u[j],u[i] end
  return u end

-- Iterator. Return items in key order.
function items(t,    n,u,i)
  u={}; for k,v in pairs(t) do u[1+#u] = {k=k,v=v} end
  table.sort(u, lt"k")
  i=0; return function() if i<#u then i=i+1; return u[i].k, u[i].v end end end

-- ### Thing to String

-- Generate a string from a nested structure. Round numbers to `n` decismals.
function o(x,  n,      t)
  if type(x) == "number" then return rnd(x, n) end
  if type(x) ~= "table"  then return tostring(x) end
  t={}
  for k,v in items(x) do
    t[1+#t] = #x>0 and o(v,n) or fmt("%s: %s", o(k,n), o(v,n)) end
  return "{" .. table.concat(t, ", ") .. "}" end

-- Print a string representing a nested structure. Return that structure.
function oo(x) print(o(x)); return x end

function report(ts, nWidth,    say)
  function say(x,    s) return io.write(fmt("%"..(nWidth or 8) .."s", x)) end
  for _,t0 in pairs(ts) do
    say(""); for k,_ in items(t0) do io.write(", "); say(k) end; print"";
    for k,t in pairs(ts) do 
      say(k); for _,x in items(t) do io.write(", "); say(x) end; print"" end
    return nil end end

-- ### String to Thing

-- String to int or float or nil or bool.
function coerce(s1,    fun)
  function fun(s2)
    if s2=="nil" then return nil
    else return s2=="true" or (s2~="false" and s2) end end
  return math.tointeger(s1) or tonumber(s1) or fun(s1:match'^%s*(.*%S)') end

-- Iterate over the rows
-- from either file `src` or list `src`. 
function rows(src,    i)
  if   type(src)=="string"
  then return csv(src)
  else i=0; return function() if i<#src then i=i+1; return i,src[i] end end end end
      
-- Iterator for files.
function csv(src,    i)
  i,src = 0,src=="-" and io.stdin or io.input(src)
  i=0
  return function(      s,t)
    s = io.read()
    if s then 
      i=i+1
      t={}; for s1 in s:gmatch("([^,]+)") do t[1+#t] = coerce(s1) end; return i,t
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
function eg.all() for k, _ in items(eg) do if k ~= "all" then eg.one(k) end end end

-- Run one example, resetting the random seed and control settings beforehand.
function eg.one(k, old,fun)
    if not eg[k] then return print("E: unknown:",k) end
    old = {}; for k0,v0 in pairs(the) do old[k0] = v0 end
    math.randomseed(the.seed)
    print(fmt(" %s %s",eg[k]()==false and "❌ FAIL" or "✅ PASS", k))
    for k1,v1 in pairs(old) do the[k1] = v1 end end

function eg.help() return os.exit(print("\n"..help)) end

function eg.the() oo(the) end

function eg.oo() oo{a="asdas",b=2.2343,c=3,d={10,20,30},e={f=90}} end

local function norm(mu, sd)
  return (mu or 0) + (sd or 1) * math.sqrt(-2 * math.log(R()))
                               * math.cos(2 * math.pi * R()) end

function eg.sym(sym1,mode,e)
  sym1 = SYM()
  for _, x in pairs { 1, 1, 1, 1, 2, 2, 3 } do col(sym1, x) end
  mode, e = mid(sym1), div(sym1)
  print(mode, e)
  return 1.37 < e and e < 1.38 and mode == 1 end
                                
function eg.num(      t,num1,mu,sd)
  t,num1 = {},NUM()
  for _ = 1, 1000 do t[1 + #t] = col(num1, norm(10, 2)) end
  mu, sd = num1.mu, num1.sd
  print(mu, sd)
  return 9.9 < mu and mu < 10 and 1.95 < sd and sd < 2 end

function eg.rows(    i) 
  i=0
  for i,row1  in rows(the.file) do
    i=i+1
    if i %80 == 0 then print(o(row1)) end end
  print ""
  for t in rows {
      { 8, 318, 210, 4382, 13.500, 70, 1, 10 },
      { 8, 429, 208, 4633, 11,     72, 1, 10 },
      { 8, 400, 150, 4997, 14,     73, 1, 10 },
      { 8, 350, 180, 3664, 11,     73, 1, 10 } } do print(200, o(t)) end end

function eg.data()
    for i, row in pairs(DATA(the.file).rows) do
      if i % 80 ==0 then oo(row) end end end

function eg.datas(      acc,fun,datas1,wait)
  for k=0,3,1 do
    for m=0,3,1 do 
      the.k=k
      the.m=m
      acc=0
      wait=5
      function fun(datas1,i,want,t)
        if i> wait and want==likesMost(t,datas1) then acc=acc+1 end end
      datas1 = DATAS(the.file, fun)
      print(m,k,fmt("%.2f",acc/(#(datas1.all.rows) -wait))) end end end

function eg.smooth()
  report(SMOOTH(the.file)) end

  -- for _,fun in pairs{mid,div} do
  --    print""
  --    out={}
  --    for k,data1 in pairs(datas) do out[k] = stats(data1,fun) end
  --    report(out) end 
 
-- function eg.smooth(    d)
--   d=DATA("../auto93.csv") 
--   for _,row in pairs(d) do row.used=0 end
--   while true:
--     sort()
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
for k,v in help:gmatch("\n[%s]+[-][%S][%s]+[-][-]([%S]+)[^\n]+= ([%S]+)") do
  the[k] = coerce(v)  end

-- Call an example (after updating the configuration file from the command line).
the =cli(the)
eg.one(the.eg)

-- Check for rogue locals.
for k,_ in pairs(_ENV) do if not b4[k] then print("?",k) end end