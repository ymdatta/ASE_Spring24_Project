-- vim: set et sts=2 sw=2 ts=2 
local b4={}; for k, _ in pairs(_ENV) do b4[k]=k end
local l,the,help = {},{},[[
gate: guess, assess, try, expand
(c) 2023, Tim Menzies, BSD-2

USAGE:
  lua gate.lua [OPTIONS] 

OPTIONS:
  -a --acquire acqusition function              = acquite
  -f --file   csv data file name                = ../data/diabetes.csv
  -h --help   show help                         = false
  -k --k      low class frequency kludge        = 1
  -m --m      low attribute frequency kludge    = 2
  -s --seed   random number seed                = 1234567891
  -t --todo   start up action                   = help]]

-- -----------------------------------------------------------------------------
local NUM={}
function NUM:new(s, n)
  return {txt=s or " ", at=n or 0, n=0,
          mu=0, m2=0, hi=-1E30, lo=1E30,
          heaven = (s or ""):find"-$" and 0 or 1} end

function NUM:add(x,     d)
  if x ~="?" then
    self.n  = self.n+1
    d       = x - self.mu
    self.mu = self.mu + d/self.n
    self.m2 = self.m2 + d*(x - self.mu)
    self.lo = math.min(x, self.lo)
    self.hi = math.max(x, self.hi) end end

function NUM:mid() return self.mu end
function NUM:div() return self.n < 2 and 0 or (self.m2/(self.n - 1))^.5 end

function NUM:like(x,_)
  local mu, sd =  self:mid(), self:div()
  return 2.718^(-.5*(x - mu)^2/(sd^2)) / (sd*2.5 + 1E-30) end

function NUM:norm(x)
  return x=="?" and x or (x - self.lo) / (self.hi - self.lo + 1E-30) end

-- -----------------------------------------------------------------------------
local SYM={}
function SYM:new(s,n)
  return {txt=s or " ", at=n or 0, n=0,
          has={}, mode=nil, most=0} end

function SYM:add(x)
  if x ~= "?" then 
    self.n = self.n + 1
    self.has[x] = 1 + (self.has[x] or 0)
    if self.has[x] > self.most then 
      self.most,self.mode = self.has[x], x end end end
function SYM:mid() return self.mode end

function SYM:div(    e) 
  e=0
  for _,v in pairs(self.has) do e=e - v/self.n*math.log(v/self.n,2) end
  return e end

function SYM:like(x, prior)
  return ((self.has[x] or 0) + the.m*prior)/(self.n +the.m) end

-- -----------------------------------------------------------------------------
local COLS={}
function COLS:new(t)
  local x,y,all = {},{},{}
  local klass,col
  for at,txt in pairs(t) do
    col = (txt:find"^[A-Z]" and NUM or SYM)(txt,at)
    all[1+#all] = col
    if not txt:find"X$" then
      if txt:find"!$" then klass=col end
      (txt:find"[!+-]$" and y or x)[at] = col end end
  return {x=x, y=y, all=all, klass=klass, names=t} end

function COLS:add(t)
  for _,cols in pairs{self.x, self.y} do
    for _,col in pairs(cols) do
      col:add(t[col.at]) end end 
  return t end 

-- -----------------------------------------------------------------------------
local DATA={}
function DATA:new(src,  fun)
  self.rows, self.cols = {},nil
  if   type(src) == "string"
  then for _,x in l.csv(src)       do self:add(x, fun) end
  else for _,x in pairs(src or {}) do self:add(x, fun) end end end

function DATA:add(t,  fun)
  if   self.cols
  then if fun then fun(self,t) end
       self.rows[1 + #self.rows] = self.cols:add(t)
  else self.cols = COLS(t) end end
 
function DATA:like(t,n,nHypotheses,       prior,out,col1,inc)
  prior = (#self.rows + the.k) / (n + the.k * nHypotheses)
  out   = math.log(prior)
  for at,v in pairs(t) do
    if v ~= "?" and self.cols.x[at] and at ~= self.cols.klass.at then
      inc = self.cols.x[at]:like(v,prior)
      out = out + math.log(inc) end end 
  return out end

local function likes(t,datas,       n,nHypotheses,most,tmp,out)
  n,nHypotheses = 0,0
  for k,data in pairs(datas) do
    n = n + #data.rows
    nHypotheses = 1 + nHypotheses end
  most = -1E30
  for k,data in pairs(datas) do
    tmp = data:like(t,n,nHypotheses)
    if tmp > most then most,out = tmp,k end end
  return out,most end

function DATA:stats(cols,fun,ndivs,    u)
  u = {[".N"] = #self.rows}
  for _,col in pairs(self.cols[cols or "y"]) do
    u[col.txt] = l.rnd(getmetatable(col)[fun or "mid"](col), ndivs) end
  return u end

-- -----------------------------------------------------------------------------
local acquire={}
function acquire.stress(b,r)  return (b+r)/math.abs(b-r) end
function acquire.xplore(b,r)  return 1/(b+r) end
function acquire.xploit(b,r)  return b+r end
function acquire.plan(b,r)    return b end
function acquire.watch(b,r)   return r end

function DATA:gate(       dark,lite,best,rest,todo)
  dark,lite = {},{}
  for i,row in pairs(l.shuffle(self.rows)) do
    if i<=4 then lite[1+#lite]=row else dark[1+#dark]=row end end
  print(#lite, #dark)
  local best,rest
  print("all ",l.o(self:stats()))
  for i=1,6 do
    best,rest = self:bestRest(lite, (#lite)^.5)
    print("best", l.o(best:stats()))
    print("rest", l.o(rest:stats()))
    todo = self:acquisitionFunction(best,rest,lite,dark)  end
  --   lite[1+#lite] = table.remove(dark,todo) end 
  return best end 

function DATA:acquisitionFunction(best,rest,lite,dark)     
  local max,b,r,tmp,what 
  max = 0
  for i,row in pairs(dark) do
    b = best:like(row, #lite, 2)
    r = rest:like(row, #lite, 2)
    tmp = acquire[the.acquire](b,r)
    if tmp > max then what,max = i,tmp end end
  return what end

function DATA:d2h(t,     d,n)
  d,n=0,0
  for _,col in pairs(self.cols.y) do
    n = n + 1
    d = d + math.abs(col.heaven - col:norm(t[col.at]))^2 end
  return d^.5/n^.5 end

function DATA:bestRest(rows,want,      best,rest) 
  table.sort(rows, function(a,b) return self:d2h(a) < self:d2h(b) end)
  best, rest = {self.cols.names}, {self.cols.names}
  for i,row in pairs(rows) do
    if i <= want then best[1+#best]=row else rest[1+#rest]=row end end
  return DATA(best), DATA(rest) end

-- -----------------------------------------------------------------------------
-- ## Objects
function l.objects(t)
  for name,kl in pairs(t) do l.obj(name,kl) end 
  return t end

function l.obj(s,  t)
  t = t or {}
  t.a = s
  t.__index = t  --
  return setmetatable(t, {
    __call=function(_,...)
             local self = setmetatable({},t)
             return setmetatable(t.new(self,...) or self,t) end}) end

-- -----------------------------------------------------------------------------
-- ## Linting
function l.rogues()
  for k,v in pairs(_ENV) do if not b4[k] then print("E:",k,type(k)) end end end

-- -----------------------------------------------------------------------------
-- ## Nums
function l.rnd(n, ndecs)
  if type(n) ~= "number" then return n end
  if math.floor(n) == n  then return n end
  local mult = 10^(ndecs or 3)
  return math.floor(n * mult + 0.5) / mult end

-- -----------------------------------------------------------------------------
-- ## Lists
function l.keys(t,    u)
  u={}; for k,_ in pairs(t) do u[1+#u]=k end; table.sort(u); return u end

function l.copy(t,    u)
  if type(t) ~= "table" then return t end
  u={}; for k,v in pairs(t) do u[l.copy(k)] = l.copy(v) end
  return u end 

function l.shuffle(t,    u,j)
  u={}; for _,x in pairs(t) do u[1+#u]=x; end;
  for i = #u,2,-1 do j=math.random(i); u[i],u[j] = u[j],u[i] end
  return u end
-- -----------------------------------------------------------------------------
-- ## String to Things
function l.coerce(s1,    fun) 
  function fun(s2)
    if s2=="nil" then return nil else return s2=="true" or (s2~="false" and s2) end end
  return math.tointeger(s1) or tonumber(s1) or fun(s1:match'^%s*(.*%S)') end

function l.settings(s,    t,pat)
  t,pat = {}, "\n[%s]+[-][%S][%s]+[-][-]([%S]+)[^\n]+= ([%S]+)"
  for k, s1 in s:gmatch(pat) do t[k] = l.coerce(s1) end
  t._help = s
  return t end

function l.words(s,   t)
  t={}; for s1 in s:gmatch("([^,]+)") do t[1+#t]=l.coerce(s1) end; return t end

function l.csv(src,    i)
  i,src = 0,src=="-" and io.stdin or io.input(src)
  return function(      s)
    s=io.read()
    if s then i=i+1; return i,l.words(s) else io.close(src) end end end

function l.cli(t)
  for k, v in pairs(t) do
    v = tostring(v)
    for argv,s in pairs(arg) do
      if s=="-"..(k:sub(1,1)) or s=="--"..k then
        v = v=="true" and "false" or v=="false" and "true" or arg[argv + 1]
        t[k] = l.coerce(v) end end end
  if t.help then os.exit(print("\n"..t._help)) end
  return t end

-- -----------------------------------------------------------------------------
-- Things to Strings
l.fmt = string.format

function l.oo(x) print(l.o(x)); return x end

function l.o(t,  n,      u)
  if type(t) == "number" then return tostring(l.rnd(t, n)) end
  if type(t) ~= "table"  then return tostring(t) end
  u={}
  for _,k in pairs(l.keys(t)) do
    if tostring(k):sub(1,1) ~= "_" then
      u[1+#u]= #t>0 and l.o(t[k],n) or l.fmt("%s: %s", l.o(k,n), l.o(t[k],n)) end end
  return "{" .. table.concat(u, ", ") .. "}" end

-- -----------------------------------------------------------------------------
local eg={}

local function run(k,   oops,b4) 
  b4 = l.copy(the) -- set up
  math.randomseed(the.seed) -- set up
  oops = eg[k]()==false
  io.stderr:write(l.fmt("# %s %s\n",oops and "❌ FAIL" or "✅ PASS",k))
  for k,v in pairs(b4) do the[k]=v end -- tear down
  return oops end

function eg.all(     bad)
  bad=0
  for _,k in pairs(l.keys(eg)) do 
    if k ~= "all" then 
      if run(k) then bad=bad+1 end end end
  io.stderr:write(l.fmt("# %s %s fail(s)\n",bad>0 and "❌ FAIL" or "✅ PASS",bad))
  os.exit(bad) end

function eg.egs() 
  for _,k in pairs(l.keys(eg)) do print(l.fmt("lua gate.lua -t %s",k)) end end

function eg.oo()   l.oo{a=1,b=2,c=3,d={e=3,f=4}} end

function eg.the() l.oo(the) end 

function eg.help() print("\n"..the._help) end

function eg.sym(      s,mode,e)
  s = SYM()
  for _, x in pairs{1,1,1,1,2,2,3} do s:add(x) end
  mode, e = s:mid(), s:div()
  print(mode, e)
  return 1.37 < e and e < 1.38 and mode == 1 end

local function norm(mu,sd,    R)
  R=math.random
  return (mu or 0) + (sd or 1) * math.sqrt(-2 * math.log(R()))
                               * math.cos(2 * math.pi * R()) end

function eg.num(      e,mu,sd)
  e = NUM()
  for _ = 1,1000 do e:add(norm(10, 2)) end
  mu, sd = e:mid(), e:div()
  print(l.rnd(mu,3), l.rnd(sd,3))
  return 9.9 < mu and mu < 10 and 1.95 < sd and sd < 2 end

function eg.csv()
  for i,t in l.csv(the.file) do
    if i%100 == 0 then print(i, l.o(t)) end end end

function eg.data(     d)
  d = DATA(the.file)
  for i, t in pairs(d.rows) do
    if i % 100 ==0 then l.oo(t) end end 
  l.oo(d.cols.x[1]) end

local function learn(data,t,  my,kl)
  my.n = my.n + 1
  kl   = t[data.cols.klass.at]
  if kl == likes(t, my.datas) then my.acc=my.acc+1 end
  my.datas[kl] = my.datas[kl] or DATA{data.cols.names}
  my.datas[kl]:add(t) end

function eg.bayes()
  print(l.fmt("#%4s\t%s\t%s","acc","k","m"))
  for k=0,3 do
    for m=0,3 do
      the.k = k
      the.m = m
      local wme = {acc=0,datas={},n=0}
      DATA(the.file, function(data,t) learn(data,t,wme) end) 
      print(l.fmt("%5.2f\t%s\t%s",wme.acc/wme.n, k,m)) end end end

function eg.stats()
  l.oo(DATA(the.file):stats()) end

function eg.gate()
  DATA(the.file):gate() end
-- -----------------------------------------------------------------------------
local gate=l.objects{COLS=COLS,DATA=DATA,NUM=NUM,SYM=SYM}
the =  l.settings(help)
if not pcall(debug.getlocal,4,1) then run(l.cli(the).todo) end
l.rogues()
return gate