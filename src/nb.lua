local the = {bins=12, cohen=.35, seed=1234567891, eg="the", wait=20}
local as,was = {},{}
local o, oo, fmt

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

local function discretizes(data1, t)
  for _, col1 in pairs(data1.colsl) do
    if not col1.isSym then
      t.cooked[col1.at] = discretize(col1, t.raw[col1.at]) end  end end

local function COLS(t,    all,klass)
  all, klass = {},nil
  for k,v in pairs(t) do
    all[1+#all]= COL(v,k)
    if v:find'!$' then klass = all[#all] end end
  return {all=all, names=t, klass=klass, f={}} end

local function cols(cols1,t)
  for _, col1 in pairs(cols1.all) do col(col1, t[col1.at]) end
  return t end

local function ROW(t) return {cells={}, cooked={}} end

local function data(data1,xs,     row1)
  row1 = xs.cells and xs and ROW(xs)
  if   data1.cols
  then data1.rows[1 + #data1.rows] = cols(data1.cols, row1.cells)
  else data1.cols = COLS(row1.cells) end end

local function DATA(src,    data1)
  data1 = {rows = {}, cols = nil}
  for   row1 in as.rows(src)      do data(data1, row1) end
  for _,row1 in pairs(data1.rows) do discretizes(data1, row1) end
  return data1 end

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
fmt = string.format
function o(x) return was.x(x) end
function oo(x) print(o(x)); return x end

function was.x(x,...)
  local is = type(x)
  return is=='number' and was.num(x) or is=='table' and was.tbl(x,...) or tostring(x) end

function was.num(x)
  return string.format(math.floor(x)==x and '%.0f' or '%.3f', x) end

function was.tbl(t,  pre,post,seen,     u)
  seen = seen or {}
  if seen[t] then return '...' end
  seen[t] = true
  u = (#t == 0 and was.keys or was.array)(t, pre, post, seen)
  return (pre or '{') .. u .. (post or '}') end

function was.keys(t, ...)
  local u = {}; for k,v in pairs(t) do u[1+#u] = fmt(':%s %s', k, was.x(v, ...)) end
  table.sort(u)
  return table.concat(u,' ') end

function was.array(t,...)
  local u={}; for k,v in pairs(t) do u[k]=  was.x(v,...) end
  return table.concat(u,', ') end

function was.matrix(ts,pre,post,    u)
  u={}; for k,t in pairs(ts) do u[k] = was.x(t,pre,post) end
  return (pre or '{') .. table.concat(u,'\n') .. (post or '}') end

-- --------- --------- --------- --------- --------- --------- --------- --------- ------
local function cli(t)
  for k, v in pairs(t) do
    v = tostring(v)
    for argv,s in pairs(arg) do
      if s=="-"..(k:sub(1,1)) or s=="--"..k then
        v = v=="true" and "false" or v=="false" and "true" or arg[argv + 1]
        t[k] = as.thing(v) end end end
  return t end

local eg = {}
function eg.all() for k, _ in pairs(eg) do if k ~= "all" then eg.one(k) end end end

function eg.one(k,      old)
    old = {}; for k0,v0 in pairs(the) do old[k0] = v0 end
    math.randomseed(the.seed)
    print(string.format(" %s %s", eg[k]()==false and "❌ FAIL" or "✅ PASS", k))
    for k1,v1 in pairs(old) do the[k1] = v1 end end

local function norm(mu, sd)
  return (mu or 0) + (sd or 1) * math.sqrt(-2 * math.log(math.random()))
                               * math.cos(2 * math.pi * math.random()) end
  
function eg.the() io.write(o(the)) end

function eg.norm(     u)
  u={}; for _ = 1,100 do u[1+#u] = norm(100,10)//1 end
  table.sort(u)
  oo(u) end

function eg.num(    num1)
  num1 = NUM()
  for _ = 1, 1000 do col(num1, norm(10, 1)) end
  mu, sd = num1.mu, num1.sd
  return 9.95 < mu and mu < 10.05 and 0.975 < sd and sd < 1.025 end

eg.one(cli(the).eg)

-- local d = DATA('../data/auto93.csv')
-- print(was.x(d.cols.names,'',''))
-- print(was.matrix(d.rows,'',''))