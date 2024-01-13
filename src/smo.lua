-- vim: set ts=2 sw=2 sts=2 et

local the = { cohen = 0.35, file = "../data/auto93.csv", 
              k = 1, m = 2, seed = 31210 }

local map,map2,keys,sort,shuffle
function map(t,f,    u) u={}; for _,x in pairs(t) do u[1+#u]=f(x)   end; return u end
function map2(t,f,   u) u={}; for k,x in pairs(t) do u[1+#u]=f(k,x) end; return u end
function keys(t)       return map2(t, function(k,_) return k end) end
function sort(t,f)     table.sort(t,f) return t end

function shuffle(t,    u,j)
  u={}; for _,x in pairs(t) do u[1+#u]=x; end;
  for i = #u,2,-1 do j=math.random(i); u[i],u[j] = u[j],u[i] end
  return u end

local is,is1,csv
function is(s)  return math.tointeger(s) or tonumber(s) or is1(s:match'^%s*(.*%S)') end
function is1(s) return s=="true" or (s~="false" and s) end 

function csv(src,    i,cells)
  function cells(s,t) for x in s:gmatch("([^,]+)") do t[1+#t]=is(x) end; return t end
  i,src = 0,src=="-" and io.stdin or io.input(src)
  return function(      s)
    s=io.read()
    if s then i=i+1; return i,cells(s,{}) else io.close(src) end end end

local cli
function cli(t)
  for k, v in pairs(t) do
    v = tostring(v)
    for argv,s in pairs(arg) do
      if s=="-"..(k:sub(1,1)) or s=="--"..k then
        v = is(v=="true" and "false" or v=="false" and "true" or arg[argv + 1])
        t[k] = is(v) end end end
  return t end

local cat,fmt,show
cat=table.concat
fmt=string.format

function o(t, ndecs,    f,u)    
  f="%."..n.."f"
  if type(x) == "number" then return math.floor(x)==x and tostring(x) or fmt(f, x) end
  if type(x) ~= "table"  then return tostring(x) end
  u = map(keys(t), function(k,y) y=o(t[k],n); return t>0 and y or fmt(":%s %s",k,y) end)
  return (t._isa or "") .. '('.. cat(#t==0 and sort(u) or u," ") .. ')' end

local isa,obj
function isa(x,y)    return setmetatable(y,x) end
function obj(s,   t) t={_isa=s, __tostring=show}; t.__index=t; return t end

local ROW=obj"ROW"
function ROW.new(cols) return isa(ROW,{cols=cols, evaluated=false,_x={}, _y={}}) end
function ROW:x(n) return self._x[n] endf
function ROW:y(n) 
  if not self.evaluated then self:eval() end
  self.evaluated = true
  return self._y[n] end

function ROW:eval(): return true -- ie need to compute _y from _x, include that code here

function ROW:read(t)  -- is missing values, skip that item
  for _,xy in pairs{self.cols.x, self.cols.y} do
    for at,_ in pairs(xy) do
      self.x[at] = t[at] end end -- nil if not there.
  return t end

function ROW:d2h(t,nums,    d,n)
  d,n = 0,0
  for at,num in pairs(nums) do
    n = n + 1
    d = d + math.abs(self.cols.y[at]  - num:norm(self.y[at]))^2 end
  return (d/n)^.5 end

local COLS=obj"COLS"
function COLS.new(t,   x,y) 
  x,y={},{}
  for n,s in pairs(t) do 
    if     s:find"+$" then y[n]=  1
    elseif s:find"-$" then y[n]= -1
    else   x[n] = n end end
  return isa(COLS,{names=t, x=x, y=y}) end

local DATA=obj"DATA"
function DATA.new() return isa(DATA,{rows={},cols={}}) end

function DATA.read(file)
for i,t in csv(file) do
  if   i==1 
  then self.cols = COLS(t)
  else self.rows[1+#self.rows] = ROW(self.cols):read(t)

local NUM=obj"NUM"
function NUM.new() return {lo= 1E30, hi= -1E30} end
function NUM:add(x)
  self.lo = math.min(x,self.lo)
  self.hi = math.max(x,self.hi) end

function NUM:norm(x)       return (x-self.lo) / (self.hi - self.lo + 1E-30) end
function NUM:d2h(x,heaven) return math.abs(heaven - self:norm(x)) end

function split(rows)
  nums={}
  for _,row in pairs(rows) do
    for at,_ in pairs(row.cols.y) do
      nums[at] = nums[at] or NUM.new()
      nums[at]:add(row.y[at]) end end
       
