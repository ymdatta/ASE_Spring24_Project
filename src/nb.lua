local the = {bins=12, cohen=.35,wait=20}
local as,was={},{}

-- --------- --------- --------- --------- --------- --------- --------- --------- ------
local function NUM(s,n) return {txt=s or '', at=n or 0, n=0, f={},mu=0, m2=0, sd=0}   end
local function SYM(s,n) return {txt=s or '', at=n or 0, n=0, f={},has={}, isSym=true} end
local function COL(s,n) return (s:find'^[A-Z]' and NUM or SYM)(s,n) end

local function col(col1, x, d)
  if x ~= "?" then
    col1.n = col1.n + 1
    if col1.isSym then col1.has[x] = 1+(col1.has[x] or 0) else
      d = x - col1.mu
      col1.mu = col1.mu + d/col1.n
      col1.m2 = col1.m2 + d*(x - col1.mu)
      col1.sd = col1.n < 2 and 0 or (col1.m2/(col1.n - 1))^.5  end end end

local function discretize(col1,x)
  return (col1.isSym or x=="?") and x or ((x-col1.mu) / col1.sd/(6/the.bins) + .5)//1 end

local function discretizes(data1, t)
  for _, col1 in pairs(data1.colsl) do
    if col1.isNum then
        t[col1.at] = discretize(col1, t[col1.at]) end  end end

local function COLS(t,    all,klass)
  all, klass = {},nil
  for k,v in pairs(t) do
    all[1+#all]= COL(v,k)
    if v:find'!$' then klass = all[#all] end end
  return {all=all, names=t, klass=klass, f={}} end

local function cols(cols1,t) 
  for _,col1 in pairs(cols1.all) do col(col1,t[col1.at]) end end

local function data(data1,t)
  if   data1.cols
  then data1.rows[1 + #data1.rows] = t
       cols(data1.cols, t, #data1.rows > the.wait)
  else data1.cols = COLS(t) end end

local function DATA(src, data1)
    data1 = { rows = {}, cols = nil }
    for t in as.rows(src) do data(data1, t) end
    for t in data1.rows do discretizes(data1, t) end
    return data1 end

-- local function learn(data1)
--   for _,row in pairs(data1.rows) do

-- --------- --------- --------- --------- --------- --------- --------- --------- ------
function as.num(s) return math.tointeger(s) or tonumber(s) end

function as.nonum(s)
  s = s:match'^%s*(.*%S)'
  if s=='nil' then return nil else return s=='true' or (s~='false' and s) end end

function as.thing(s) return as.num(s) or as.nonum(s) end

function as.things(s,    t)
  t={}; for s1 in s:gmatch('([^,]+)') do t[1+#t]=as.thing(s1) end; return t end

function as.rows(src,     n)
  if type(src)=='string' then return as.csv(src) else
    n=0; return function() if n < #src then n=n+1; return src[n] end end end end

function as.csv(src)
  src = src==nil and io.stdin or io.input(src)
  return function(   line)
    line = io.read()
    if line then return as.things(line) else io.close(src) end end end

-- --------- --------- --------- --------- --------- --------- --------- --------- ------
function was.x(x,...)
  local is=type(x)
  return is=='number' and was.num(x) or is=='table' and was.tbl(x,...) or tostring(x) end

function was.num(x)
  return string.format(math.floor(x)==x and '%.0f' or '%.3f', x) end

function was.tbl(t,  pre,post,seen,     u)
  seen = seen or {}
  if seen[t] then return '...' end
  seen[t] = true
  u = (#t==0 and was.keys or was.array)(t,pre,post,seen)
  return (pre or '{') .. u .. (post or '}') end

function was.keys(t,...)
  local u={}; for k,v in pairs(t) do u[k]=string.format(':%s %s',k,was.x(v,...)) end
  table.sort(u)
  return table.concat(u,' ') end

function was.array(t,...)
  local u={}; for k,v in pairs(t) do u[k]=  was.x(v,...) end
  return table.concat(u,', ') end

function was.matrix(ts,pre,post,    u)
  u={}; for k,t in pairs(ts) do u[k]= was.x(t,pre,post) end
  return (pre or '{') .. table.concat(u,'\n') .. (post or '}') end

-- --------- --------- --------- --------- --------- --------- --------- --------- ------
local d = DATA('../data/auto93.csv')
print(was.x(d.cols.names,'',''))
print(was.matrix(d.rows,'',''))