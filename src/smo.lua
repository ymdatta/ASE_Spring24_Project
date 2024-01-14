-- vim: set ts=2 sw=2 sts=2 et

local the = { best = .5,    cohen = 0.35, file = "../data/auto93.csv",
              go = 4, k = 1, m = 2, seed = 31210, stop=4}
-----------------------------------------------------------------------------------------
local map,map2,keys,sort,shuffle,slice,alls -- list utils
function map(t,f,    u) u={}; for _,x in pairs(t) do u[1+#u]=f(x)   end; return u end
function map2(t,f,   u) u={}; for k,x in pairs(t) do u[1+#u]=f(k,x) end; return u end
function keys(t)       return map2(t, function(k,_) return k end) end
function sort(t,f)     table.sort(t,f) return t end

function shuffle(t,    u,j)
  u={}; for _,x in pairs(t) do u[1+#u]=x; end;
  for i = #u,2,-1 do j=math.random(i); u[i],u[j] = u[j],u[i] end
  return u end

function slice(t, go, stop, inc,    u)
  if go   and go   < 0 then go=#t+go     end
  if stop and stop < 0 then stop=#t+stop end
  u={}
  for j=(go or 1)//1,(stop or #t)//1,(inc or 1)//1 do u[1+#u]=t[j] end
  return u end

function alls(x,t)
  for _,y in pairs(t) do x:add(y) end; return x end
-----------------------------------------------------------------------------------------
local is,is1,csv -- coerce strings from file to some tupe
function is(s)  return math.tointeger(s) or tonumber(s) or is1(s:match'^%s*(.*%S)') end
function is1(s) return s=="true" or (s~="false" and s) end 

function csv(src,    i,cells)
  function fun(s,t) for x in s:gmatch("([^,]+)") do t[1+#t]=is(x) end; return t end
  i,src = 0,src=="-" and io.stdin or io.input(src)
  return function(      s)
    s=io.read()
    if s then i=i+1; return i,fun(s,{}) else io.close(src) end end end
-----------------------------------------------------------------------------------------
local cli -- update a table from command line flags
function cli(t)
  for k, v in pairs(t) do
    v = tostring(v)
    for argv,s in pairs(arg) do
      if s=="-"..(k:sub(1,1)) or s=="--"..k then
        v = is(v=="true" and "false" or v=="false" and "true" or arg[argv + 1])
        t[k] = is(v) end end end
  return t end
-----------------------------------------------------------------------------------------
local cat,fmt,show -- pretty print functions
cat=table.concat
fmt=string.format

function oo(t,   n) print(o(t,n)); return t end
function o(t,  n,    f,u)    
  f="%."..n.."f"
  if type(x) == "number" then return math.floor(x)==x and tostring(x) or fmt(f, x) end
  if type(x) ~= "table"  then return tostring(x) end
  u = map2(t, function(k,v) v=o(v,n); return t>0 and y or fmt(":%s %s",k,v) end)
  return (t._isa or "") .. '('.. cat(#t>0 and u or sort(u)," ") .. ')' end
-----------------------------------------------------------------------------------------
local isa,obj
function isa(x,y)    return setmetatable(y,x) end
function obj(s,   t) t={_isa=s, __tostring=show}; t.__index=t; return t end
-----------------------------------------------------------------------------------------
local ROW=obj"ROW"
function ROW.new(t) return isa(ROW, {evaluated=false, cells=t}) end
function ROW:x(at)  return self.cells[at] end
function ROW:y(at) 
  if not self.evaluated then self:eval() end
  self.evaluated = true
  return self.cells[at] end

function ROW:eval(): return true end -- here, we compute _y from _x

function ROW:d2h(data,    d,n,norm)
  d,n = 0,0
  for _,col in pairs(self.cols.y) do
    n = n + 1
    d = d + math.abs(col.heaven - norm(self:y(col.at)))^2 end
  return (d/n)^.5 end

function ROW:likes(datas,       n,nHypotheses,most,tmp,out)
  n,nHypotheses = 0,0
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
local NUM==obj"NUM"
function NUM.new(at,s) 
  return {at=at or 0, s=s or "", lo= 1E30, hi= -1E30, mu=0, m2=0, n=0,sd=0,
          heaven=(s or ""):find"-$" and 0 or 1} end

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
  return x=="?" and x or (x - self.lo[c])/(self.hi[c] - self.lo[c] + 1E-30) end

function NUM:like(x,_,      nom,denom)
  nom   = 2.718^(-.5*(x - self.mu)^2/(self.sd^2 + 1E-30))
  denom = (self.sd*2.5 + 1E-30)
  return  nom/denom end
-----------------------------------------------------------------------------------------
local COLS=obj"COLS"
function COLS.new(t,   x,y,all,col,u) 
  x,y,all={},{},{}
  for at,s in pairs(t) do 
    col = (s:find"^[A-Z]" and NUM or SYM)(at,s)
    all[1+#all] = col
    if not s:find"X$" then
      table.insert(s:find"[!-+]$" and y or x, col) end end
  return isa(COLS,{names=t, x=x, y=y, all=all}) end

function COLS:add(row)
  for _,xy in pairs{self.x, self.y} do
    for _,col in pairs(xy) do
      v = row.cells[col.at] 
      if v then col:add(v) end end end
  return row end
-----------------------------------------------------------------------------------------
local DATA=obj"DATA"
function DATA.new(src) return isa(DATA,{rows={},cols=nil}):adds(src) end

function DATA:adds(src)
  if   type(src) == "string"
  then for   row in csv(src)         do self:add(row) end
  else for _,row in pairs(src or {}) do self:add(row) end end
  return self end

function DATA:add(x,    row)
  row = x.cells and x or ROW(x)
  if   self.cols
  then self.rows[1+#self.rows] = ROW(row.cells) 
  else self.cols = COLS(row) end end

function DATA:sorter()
  return function(a,b) return a:d2h(self) > b:d2h(self) end  end

function DATA:bestRest(want,     best,rest)
  best,rest=DATA{self.cols.names}, DATA{self.cols.names}
  for i,row in pairs(sort(self.rows,self:sorter())) do
    (i<= want and best or rest):add(row) end
  return best,rest end

function DATA:smo()
  local mids,tops = {},{}
  local rows,lite,dark
  rows = shuffle(self.rows)
  lite = DATA{self.cols.names}:adds(slice(self.rows,1,the.go))
  dark = DATA{self.cols.names}:adds(slice(self.rows,the.go+1))
  for i=1,the.stop do
    local todo,selected = lite:smo1(dark)
    mids[i]      = selected:mid()
    tops[i]      = best.rows[1]
    table.insert(lite, table.remove(dark,i)) end 
  return mids,tops end

function DATA:smo1(dark)
  local b,r,tmp,out,max,best,rest,selected
  best,rest = self:besRest(self.rows^the.best)
  selected  = DATA{self.cols.names}
  out, max  = 1, 1E30
  for i,row in pairs(dark.rows) do
    b = row:like(best, #self.rows, 2)
    r = row:like(rest, #self.rows, 2)
    if b>r then selected:add(row) end
    tmp = maths.abs(b + r) / maths.abs(b - r + 1E-300)
    if tmp>max then out,max = i,tmp end end
  return out,selected end

function DATA:mid()
  u={}; for _,col in pairs(self.cols.all) do u[col.txt] = col:mid() end
  return ROW(u) end

function DATA:stats(  f)
  u={}; for _,c in pairs(self.cols.y) do u[c.txt] = getmetatable(c)[f or "mid"](c) end
  return u end
-----------------------------------------------------------------------------------------
local function main(src)
  print(the.seed)
  d = DATA.new(src)
  b4  = d.cols.y
  b4.d2hs = add(NUM(), map(d.rows, function(row) return row:d2h(d) end))
  mids, tops = d:smo()
  mids[#mids]
end
