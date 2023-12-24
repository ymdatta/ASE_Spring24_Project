-- vim: set et sts=2 sw=2 ts=2 
local b4={}; for k, _ in pairs(_ENV) do b4[k]=k end
local l={}

-- -----------------------------------------------------------------------------
-- ## Objects
function l.obj(s,    t)
  t = {a=s}
  t.__index = t
  return setmetatable(t, {
    __call=function(_,...)
      local self = setmetatable({},t)
      return setmetatable(t.new(self,...) or self,t) end}) end

-- -----------------------------------------------------------------------------
-- ## Linting
function l.rogues()
  for k,v in pairs(_ENV) do if not b4[k] then print("E:",k,type(k)) end end 

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
  u={}; for k,v in pairs(t) do u[1+#u]=k end; table.sort(u); return u end

function l.copy(t,    u)
  if type(t) ~= "table" then return t end
  u={}; for k,v in pairs(t) do u[l.copy(k)] = l.copy(v) end
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
    u[1+#t]= #x>0 and l.o(t[k],n) or l.fmt("%s: %s", l.o(k,n), l.o(t[k],n)) end
  return "{" .. table.concat(u, ", ") .. "}" end

-- -----------------------------------------------------------------------------
return l
