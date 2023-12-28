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
    src = src or {}
    n=0; return function() if n < #src then n=n+1; return src[n] end end end end

function as.csv(src)
  src = src==nil and io.stdin or io.input(src)
  return function(   line)
    line = io.read()
    if line then return as.things(line) else io.close(src) end end end

-- --------- --------- --------- --------- --------- --------- --------- --------- ------


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
  local u={}; for k,v in pairs(t) do u[1+#u]=  was.x(v,...) end
  return table.concat(u,', ') end

function was.matrix(ts,pre,post,    u)
  u={}; for k,t in pairs(ts) do u[k] = was.x(t,pre,post) end
  return (pre or '{') .. table.concat(u,'\n') .. (post or '}') end