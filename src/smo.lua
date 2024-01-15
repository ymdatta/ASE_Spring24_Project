-- vim: set ts=2 sw=2 sts=2 et
local the,help={},[[

smo: simple sequential model optimzation (naive bayes as the model)
(c)2024 Tim Menzies timm@ieee.org, BSD (2 clause)

USAGE: lua smo.lua [OPTIONS}

OPTIONS:
  -b --best   size of best: n^best                 = .5
  -c --cohen  indistinguishable if under sd*coehn  = .35
  -f --file   csv file (to be read in)             = ../data/auto93.csv
  -h --help   show help                            = false
  -n --n      start by evaluating n items          = 4
  -N --N      stop after evaliation N items        = 10
  -k --k      a Bayes low frequency hack           = 1
  -m --m      a Bayes low frequency hack           = 2
  -s --seed   random number seed                   = 31210
  -t --todo   startup action                       = help]]
-----------------------------------------------------------------------------------------
--              _     _   _      
--       _  _  | |_  (_) | |  ___
--      | || | |  _| | | | | (_-<
--       \_,_|  \__| |_| |_| /__/

local b4 = {}; for k, _ in pairs(_ENV) do b4[k] = k end
local function rogues()
  for k,v in pairs(_ENV) do if not b4[k] then print("-- ??", k,type(v)) end end end
-----------------------------------------------------------------------------------------
local map,map2,keys,sort,shuffle,slice,adds -- list utils
function map(t,f)   local u={}; for _,x in pairs(t) do u[1+#u]=f(x)   end; return u end
function map2(t,f)  local u={}; for k,x in pairs(t) do u[1+#u]=f(k,x) end; return u end
function keys(t)    return map2(t, function(k,_) return k end) end
function sort(t,f)  table.sort(t,f); return t end

function shuffle(t,    u,j)
  u={}; for _,x in pairs(t) do u[1+#u]=x; end;
  for i = #u,2,-1 do j=math.random(i); u[i],u[j] = u[j],u[i] end
  return u end

function copy(t,    u)
  if type(t) ~= "table" then return t end
  u={}; for k,v in pairs(t) do u[copy(k)] = copy(v) end; return u end 

function slice(t, go, stop, inc,    u)
  if go   and go   < 0 then go=#t+go     end
  if stop and stop < 0 then stop=#t+stop end
  u={}; for j=(go or 1)//1,(stop or #t)//1,(inc or 1)//1 do u[1+#u]=t[j] end
  return u end

function adds(col,t) for _,x in pairs(t) do col:add(x) end; return col end
-----------------------------------------------------------------------------------------
local cat,fmt,show,o,oo,ooo -- pretty print functions
cat=table.concat
fmt=string.format

function ooo(t)    map(t,oo) end
function oo(t, n)  print(o(t,n)); return t end
function o(x,  n,    f,u)    
  f="%."..(n or 3).."f"
  if type(x) == "number" then return math.floor(x)==x and tostring(x) or fmt(f, x) end
  if type(x) ~= "table"  then return tostring(x) end
  u = map2(x, function(k,v) v=o(v,n); return #x>0 and tostring(v) or fmt(":%s %s",k,v) end)
  return (x._isa or "") .. '{'.. cat(#x>0 and u or sort(u)," ") .. '}' end
-----------------------------------------------------------------------------------------
local as,as1,csv,settings -- coerce strings to some type
function as(s)  return math.tointeger(s) or tonumber(s) or as1(s:match'^%s*(.*%S)') end
function as1(s) return s=="true" or (s~="false" and s) end -- or false

function csv(src,    i,fun)
  function fun(s,t) for x in s:gmatch("([^,]+)") do t[1+#t]=as(x) end; return t end
  src = src=="-" and io.stdin or io.input(src)
  return function(      s)
    s=io.read()
    if s then return fun(s,{}) else io.close(src) end end end

function settings(t,s)
  for k, s1 in s:gmatch("[-][-]([%S]+)[^=]+=[%s]*([%S]+)") do t[k] = as(s1) end
  return t end
---------------------------------------------------------------------------------------
local cli -- update a table from command line flags. bools need no values (just flip'em)
function cli(t)
  for k, v in pairs(t) do
    v = tostring(v)
    for argv,s in pairs(arg) do
      if s=="-"..(k:sub(1,1)) or s=="--"..k then
        v = v=="true" and "false" or v=="false" and "true" or arg[argv + 1]
        t[k] = as(v) end end end
  return t end
-----------------------------------------------------------------------------------------
local isa,obj
function isa(x,y)    return setmetatable(y,x) end
function obj(s,   t) t={_isa=s, __tostring=o}; t.__index=t; return t end

--            _                             
--       __  | |  __ _   ___  ___  ___   ___
--      / _| | | / _` | (_-< (_-< / -_) (_-<
--      \__| |_| \__,_| /__/ /__/ \___| /__/

local SYM=obj"SYM"
function SYM.new(s,n)
  return isa(SYM,{txt=s or " ", at=n or 0, n=0, has={}, mode=nil, most=0}) end

function SYM:add(x)
  if x ~= "?" then
    self.n = self.n + 1
    self.has[x] = 1 + (self.has[x] or 0)
    if self.has[x] > self.most then
      self.most,self.mode = self.has[x], x end end end

function SYM:mid() return self.mode end
function SYM:div(    e)
  e=0; for _,v in pairs(self.has) do e=e-v/self.n*math.log(v/self.n,2) end; return e end

function SYM:like(x, prior)
  return ((self.has[x] or 0) + the.m*prior)/(self.n +the.m) end
-----------------------------------------------------------------------------------------
local NUM=obj"NUM"
function NUM.new(at,s) 
  return isa(NUM, {at=at or 0, s=s or "", lo= 1E30, hi= -1E30, mu=0, m2=0, n=0,sd=0,
                   heaven=(s or ""):find"-$" and 0 or 1}) end

function NUM:add(x,    d)
  if x ~= "?" then
    self.n  = self.n + 1
    self.lo = math.min(x,self.lo)
    self.hi = math.max(x,self.hi) 
    d       = x - self.mu
    self.mu = self.mu + d/self.n
    self.m2 = self.m2 + d*(x - self.mu)
    self.sd = self.n < 2 and 0 or (self.m2/(self.n - 1))^.5 end end

function NUM:mid() return self.mu end
function NUM:div() return self.sd end

function NUM:norm(x)
  return x=="?" and x or (x - self.self.lo)/(self.hi - self.lo + 1E-30) end

function NUM:like(x,_,      nom,denom)
  nom   = 2.718^(-.5*(x - self.mu)^2/(self.sd^2 + 1E-30))
  denom = (self.sd*2.5 + 1E-30)
  return  nom/denom end
-----------------------------------------------------------------------------------------
local COLS=obj"COLS"
function COLS.new(t,   x,y,all,col,u) 
  x,y,all={},{},{}
  for at,s in pairs(t.cells) do 
    col = (s:find"^[A-Z]" and NUM or SYM).new(at,s)
    all[1+#all] = col
    if not s:find"X$" then
      table.insert(s:find"[!-+]$" and y or x, col) end end
  return isa(COLS,{names=t, x=x, y=y, all=all}) end

function COLS:add(row,   v)
  for _,xy in pairs{self.x, self.y} do
    for _,col in pairs(xy) do
      v = row.cells[col.at] 
      if v~=nil then col:add(v) end end end
  return row end
-----------------------------------------------------------------------------------------
local ROW=obj"ROW"
function ROW.new(t) return isa(ROW, {evaluated=false, cells=t}) end
function ROW:x(at)  return self.cells[at] end
function ROW:y(at) 
  if not self.evaluated then self:eval() end
  self.evaluated = true
  return self.cells[at] end

function ROW:eval() return true end -- here, we compute _y from _x

function ROW:d2h(data,    d,n,norm)
  d,n = 0,0
  for _,col in pairs(self.cols.y) do
    n = n + 1
    d = d + math.abs(col.heaven - norm(self:y(col.at)))^2 end
  return (d/n)^.5 end

function ROW:likes(datas,       n,nHypotheses,most,tmp,out)
  n, nHypotheses = 0, 0
  for k,data in pairs(datas) do
    n = n + #data.rows
    nHypotheses = 1 + nHypotheses end
  for k,data in pairs(datas) do
    tmp = self:like(data,n,nHypotheses)
    if most==nil or tmp > most then most,out = tmp,k end end
  return out,most end

function ROW:like(data,n,nHypotheses,       prior,out,v,inc)
  prior = (#data.rows + the.k) / (n + the.k * nHypotheses)
  out   = math.log(prior)
  for _,col in pairs(data.cols.x) do
    v= self:x(col.at)
    if v ~= "?" then
      inc = col:like(v,prior)
      out = out + math.log(inc) end end
  return math.exp(1)^out end
-----------------------------------------------------------------------------------------
local DATA=obj"DATA"
function DATA.new(src) return isa(DATA,{rows={},cols=nil}):adds(src) end

function DATA:clone(src) return (DATA{self.cols.names}):adds(src) end

function DATA:adds(src)
  if   type(src) == "string"
  then for   row in csv(src)         do self:add(row) end
  else for _,row in pairs(src or {}) do self:add(row) end end
  return self end

function DATA:add(x,    row)
  row = x.cells and x or ROW.new(x)
  if   self.cols
  then self.rows[1 + #self.rows] = self.cols:add(row)
  else self.cols = COLS.new(row) end end

function DATA:sorter()
  return function(a,b) return a:d2h(self) > b:d2h(self) end  end

--       __   ___   _ _   ___ 
--      / _| / _ \ | '_| / -_)
--      \__| \___/ |_|   \___|

function DATA:smo(    testing)
  local mids,tops,rows,liteRows,darkRows
  mids,tops = {},{}
  rows     = shuffle(self.rows)
  liteRows = slice(rows, 1, the.n)
  darkRows = slice(rows, the.n+1)
  for i = 1, the.N do
    local lite,best,rest,todo,selected
    lite          = self:clone(liteRows)
    best,rest     = lite:besRest(lite.rows^the.best)
    todo, selected = lite:what2lookAtNext(darkRows, best, rest)
    if testing then 
      table.sort(selected.rows, self:sorter())
      mids[i] = selected:mid()
      tops[i] = selected.rows[1] end
    table.insert(liteRows, table.remove(darkRows,todo)) end 
  return liteRows,mids,tops end

function DATA:bestRest(want,     best,rest)
  best,rest= {},{}
  for i,row in pairs(sort(self.rows,self:sorter())) do
    (i<= want and best or rest):add(row) end
  return best,rest end

function DATA:what2lookatNext(darkRows, best,rest)
  local b,r,tmp,max,what2do,selected
  selected = self:clone()
  what2do, max = 1, 1E30
  for i,row in pairs(darkRows) do
    b = row:like(best, #self.rows, 2)
    r = row:like(rest, #self.rows, 2)
    if b>r then selected:add(row) end
    tmp = math.abs(b + r) / math.abs(b - r + 1E-300)
    if tmp>max then what2do,max = i,tmp end end
  return what2do,selected end

function DATA:mid(      u)
  u={}; for _,col in pairs(self.cols.all) do u[col.txt] = col:mid() end
  return ROW(u) end

function DATA:stats(      u,f)
  u={}; for _,c in pairs(self.cols.y) do u[c.txt] = getmetatable(c)[f or "mid"](c) end
  return u end

--       _                _        
--      | |_   ___   ___ | |_   ___
--      |  _| / -_) (_-< |  _| (_-<
--       \__| \___| /__/  \__| /__/

local eg,failure={}

function failure(k,   failed,saved) 
  saved = copy(the) -- set up
  math.randomseed(the.seed) -- set up
  failed = eg[k]()==false
  io.stderr:write(fmt("# %s %s\n",failed and "❌ FAIL" or "✅ PASS",k))
  for k,v in pairs(saved) do the[k]=v end -- tear down
  return failed end

-- Run all examples
function eg.all(     bad)
  bad=0
  for _,k in pairs(keys(eg)) do 
    if k ~= "all" then 
      if failure(k) then bad=bad+1 end end end
  io.stderr:write(fmt("# %s %s fail(s)\n",bad>0 and "❌ FAIL" or "✅ PASS",bad))
  os.exit(bad) end

-- List all example names
function eg.egs()
  for _,k in pairs(l.keys(eg)) do print(l.fmt("lua gate.lua -t %s",k)) end end

function eg.help() 
  print(help) end

function eg.the()  
  oo(the) end

function eg.num()  
  oo(adds(NUM.new(),{1,2,2,3,3,3,3,4,4,5})) end

function eg.sym()  
  print(adds(SYM.new(),{"a","b","b","c","c","c","c","d","d","e"})) end

function eg.cols() 
  ooo(COLS.new(ROW.new{"name","Age","Salary-"}).all) end

function eg.data() 
  ooo(DATA.new(the.file).cols.all) end

function eg.shuffle()
  ooo(shuffle{10,20,30,40,50,60,70,80,90}) end

function eg.fail1() 
  print(1)
  assert(false,"oops 1") end

function eg.fail2() 
  assert(false,"oops 2") end
----------------------------------------------------------------------------------------
the = settings(the,help)

if   pcall(debug.getlocal,4,1) 
then return {the=the, COLS=COLS, DATA=DATA, NUM=NUM, ROW=ROW, SYM=SYM}
else run(cli(the).todo) 
     rogues() 
end
