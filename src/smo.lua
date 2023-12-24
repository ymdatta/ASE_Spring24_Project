-- vim: set et sts=2 sw=2 ts=2 
local l = require"smolib"
local help = [[
smo: simple Bayesian sequential model optimization
(c) 2023, Tim Menzies, BSD-2

USAGE:
  lua smoeg.lua [OPTIONS] 

OPTIONS:
  -a --acquire acqusition function              = acquite
  -f --file   csv data file name                = ../data/diabetes.csv
  -h --help   show help                         = false
  -k --k      low class frequency kludge        = 1
  -m --m      low attribute frequency kludge    = 2
  -s --seed   random number seed                = 1234567891
  -t --todo   start up action                   = help]]
  
local the = l.settings(help)
local o, obj, oo = l.o, l.obj, l.oo
local COLS,DATA,NUM,SYM = obj"COLS",obj"DATA",obj"NUM",obj"SYM"

-- -----------------------------------------------------------------------------
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
function NUM:div() return (self.m2/(self.n - 1))^.5 end

function NUM:like(x,_)
  local mu, sd =  self:mid(), self:div()
  return 2.718^(-.5*(x - mu)^2/(sd^2)) / (sd*2.5 + 1E-30) end

function NUM:norm(x)
  return x=="?" and x or (x - self.lo) / (self.hi - self.lo + 1E-30) end

-- -----------------------------------------------------------------------------
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
function DATA:new(src)
  self.rows, self.cols = {},nil
  if   type(src) == "string"
  then for _,x in l.csv(src)       do self:add(x) end
  else for _,x in pairs(src or {}) do self:add(x) end end end

function DATA:add(t)
  if   self.cols
  then self.rows[1 + #self.rows] = self.cols:add(t)
  else self.cols = COLS(t) end end
 
function DATA:like(t,n,nHypotheses,       prior,out,col1,inc)
  prior = (#self.rows + the.k) / (n + the.k * nHypotheses)
  out   = math.log(prior)
  for at,v in pairs(t) do
    if v ~= "?" and self.cols.x[at] and at ~= self.cols.klass.at then
      inc = self.cols.x[at]:like(v,prior)
      out = out + math.log(inc) end end 
  return out end

local function likes(t,datas,n,nHypotheses,     most,tmp,out)
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
    u[col.txt] = l.rnd(getmetatable(col)[fun or "mid"](), ndivs) end
  return u end

-- -----------------------------------------------------------------------------
local acquire={}
function acquire.stress(b,r)  return (b+r)/math.abs(b-r) end
function acquire.xplore(b,r)  return 1/(b+r) end
function acquire.xploit(b,r)  return b+r end
function acquire.plan(b,r)    return b end
function acquire.watch(b,r)   return r end

function DATA:smooth(       dark,lite,best,rest,todo)
  dark,lite = {},{}
  table.sort(self.rows, function(_,__) return math.random() <= .5 end)
  for i,row in pairs(self.rows) do
    if i<=4 then lite[1+#lite]=row else dark[1+#dark]=row end end
  local best,rest
  for i=1,10 do
    best,rest = self:bestRest(lite, (#lite)^.5)
    oo(i,lite:stats())
    todo = self:acqisitionFunction(best,rest,lite,dark) 
    lite[1+#lite] = table.remove(dark,todo) end 
  return best end 

function DATA:acquisitionFunction(best,rest,lite,dark)     
  local max,b,r,tmp,what     
  max = 0
  for i,row in pairs(dark) do
    b = best:like(row, #lite.rows, 2)
    r = rest:like(row, #lite.rows, 2)
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
return {the=the, COLS=COLS, DATA=DATA, NUM=NUM, SYM=SYM,
        likes =likes}