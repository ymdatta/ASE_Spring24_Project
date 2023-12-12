local the = {bins=7, cohen=.35}
local as,was={},{}


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
        bin = rows[i][c]
        all[ 1+#all ] = bin
        ib4, xb4 = i, x end end
    rows[i][c] = bin end
  return all end

-- --------- --------- --------- --------- --------- --------- --------- --------- ------
local function COLS(t)
  local rows, nums, klass = {},{},nil
  for k,v in pairs(t) do
    if v:find"^[A-Z]" then nums[k]= {} end
    if v:find"!$"     then klass = k   end end
  return {rows=rows, nums=nums, names=t, klass=klass} end

local function DATA(src, rows,cols)
  local rows = {}
  for t in as.rows(src) do
    if cols then rows[1+#rows]=t else cols=COLS(t) end end
  return {rows=rows, cols=cols} end

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
function was.x(t,  pre,post,seen)
  if type(t) ~= "table" then return tostring(t) end
  seen = seen or {}
  if seen[t] then return "..." end
  seen[t] = t
  return (#t==0 and was.keys or was.array)(t,pre,post,seen) end

function was.keys(t,  pre,post,seen,     u)
  u={}; for k,v in pairs(t) do u[k]= string.format(":%s %s",k, was.x(v,pre,post,seen)) end
  table.sort(u)
  return (pre or "{")..table.concat(u," ")..(post or "}") end

function was.array(t,  pre,post,seen,   u)
  u={}; for k,v in pairs(t) do u[k]=  was.x(v,pre,post,seen) end
  return (pre or "{")..table.concat(u,", ")..(post or "}") end

function was.matrix(ts,pre,post,    u)
  u={} for k,t in pairs(ts) do u[k]= was.x(t,pre,post) end
  return (pre or "{").. table.concat(u,"\n")..(post or "}") end

-- --------- --------- --------- --------- --------- --------- --------- --------- ------
local d = DATA("../data/auto93.csv")
print(was.x(d.cols.names,"",""))
print(was.matrix(d.rows,"",""))