local the = {bins=12, cohen=.35}
local as,was={},{}

-- --------- --------- --------- --------- --------- --------- --------- --------- ------
local NUM,SYM,COL,col,discretize
function NUM(s,n) return {txt=s or "", at=n or 0, n=0, mu=0, m2=0, sd=0}   end
function SYM(s,n) return {txt=s or "", at=n or 0, n=0, has={}, isSym=true} end
function COL(s,n) return (s:find"^[A-Z]" and NUM or SYM)(s,n) end

function col(col1,x,    d)
  if x ~= "?" then
    col1.n = col1.n + 1
    if col1.isSym then col1.has[x] = 1+(col1.has[x] or 0) else
      d = x - col1.mu
      col1.mu = col1.mu + d/col1.n
      col1.m2 = col1.m2 + d*(x - col1.mu)
      col1.sd = col1.n < 2 and 0 or (col1.m2/(col1.n - 1))^.5  end end end

function discretize(data1,row1,     x)
  for _,col1 in pairs(data1.cols.all) do
    if col1.at ~= data1.cols.klass then
      x = row1[col1.at]
      x = (col1.isSym or x=="?") and x or ((x-col1.mu)/col1.sd / (6/the.bins) + .5)//1
      row1[col1.at] = x end end end

local COLS,cols
function COLS(t,    all,klass)
  all, klass = {},nil
  for k,v in pairs(t) do
    all[1+#all]= COL(v,k)
    if v:find"!$" then klass = all[#all] end end
  return {all=all, klass=klass} end

function cols(cols1,t)
   for _,col1 in pairs(cols1.all) do col(col1, t[col1.at]) end
   return t end

local DATA,data
function DATA(src,    data1)
  data1={rows = {},cols=nil}
  for t in as.rows(src) do data(data1,t) end
  for t in pairs(data1.rows) do discretize(data1,t) end
  return data1 end

function data(data1,t)
  if   data1.cols
  then data1.rows[1 + #data1.rows] = cols(data1.cols,t)
  else data1.cols = COLS(t) end end
-- --------- --------- --------- --------- --------- --------- --------- --------- ------
local bins={}
local function BINS(rows,klass,    z,t)
  z,t = -1E30, {}
  for c=1,#rows[1] do
    if c ~= klass then
      t[c]= bins.column(rows, c,
              function(a,b)
                return (a[c]=="?" and z or a[c]) < (b[c]=="?" and z or b[c]) end) end end
  return t end

function bins.column(rows, c, sorter)
  table.sort(rows, sorter)
  for i,row in pairs(rows) do
    if row[i][c] ~= "?" then return bins.split(rows,c,i,#rows) end end end

function bins.split(rows, c, imin, imax)
  local p10  = (imin + (imax-imin)*.1)//1
  local p90  = (imin + (imax-imin)*.9)//1
  return bins.split1(rows, c, imin, imax,
                     (imax - imin)/(the.bins-1),
                     the.cohen * (rows[p90][c] - rows[p10][c])/2.56 ) end

function bins.split1(rows, c, imin, imax, ismall, xsmall)
  local ib4, xb4, all = imin, rows[c][imin], {}
  local bin = ib4
  for i = imin, imax do
    if i <= imax-ismall then
      local x,xnext = rows[i][c],rows[i+1][c]
      if x ~= xnext and x - xb4 > xsmall and i - ib4 > ismall then
        all[ 1+#all ] = x
        ib4, xb4 = i, x end end
    rows[i][c] = ib4 end
  return all end

-- --------- --------- --------- --------- --------- --------- --------- --------- ------
function as.num(s)
  return math.tointeger(s) or tonumber(s) end

function as.nonum(s)
  s = s:match'^%s*(.*%S)'
  if s=="nil" then return nil else return s=="true" or (s~="false" and s) end end

function as.thing(s)
  return as.num(s) or as.nonum(s) end

function as.things(s,    t)
  t={}; for s1 in s:gmatch("([^,]+)") do t[1+#t]=as.thing(s1) end; return t end

function as.rows(src)
  src = src==nil and io.stdin or io.input(src)
  return function(   line)
    line = io.read()
    if line then return as.things(line) else io.close(src) end end end

-- --------- --------- --------- --------- --------- --------- --------- --------- ------
function was.x(x,...)
  local is=type(x)
  return is=="number" and was.num(x) or is=="table" and was.tbl(x,...) or tostring(x) end

function was.num(x)
  return string.format(math.floor(x)==x and "%.0f" or "%.3f", x) end

function was.tbl(t,  pre,post,seen,     u)
  seen = seen or {}
  if seen[t] then return "..." end
  seen[t] = true
  u = (#t==0 and was.keys or was.array)(t,pre,post,seen)
  return (pre or "{") .. u .. (post or "}") end

function was.keys(t,...)
  local u={}; for k,v in pairs(t) do u[k]=string.format(":%s %s",k,was.x(v,...)) end
  table.sort(u)
  return table.concat(u," ") end

function was.array(t,...)
  local u={}; for k,v in pairs(t) do u[k]=  was.x(v,...) end
  return table.concat(u,", ") end

function was.matrix(ts,pre,post,    u)
  u={}; for k,t in pairs(ts) do u[k]= was.x(t,pre,post) end
  return (pre or "{") .. table.concat(u,"\n") .. (post or "}") end

-- --------- --------- --------- --------- --------- --------- --------- --------- ------
local d = DATA("../data/auto93.csv")
print(was.x(d.cols.names,"",""))
print(was.matrix(d.rows,"",""))