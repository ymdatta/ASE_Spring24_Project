local l={}

-- ## numbers
function l.rnd(n, ndecs)  
  if type(n) ~= "number" then return n end
  if math.floor(n) == n  then return n end
  local mult = 10^(ndecs or 3)
  return math.floor(n * mult + 0.5) / mult end

-- ## lists
function l.push(t,x) t[1+#t]=x; return x end

function l.sort(t,  fun) --> t
  table.sort(t,fun); return t end

function l.per(t,p)   return t[(p*#t)//1] end
function l.median(t)  return l.per(t,.5) end
function l.stdev(t)   return (l.per(t,.9) - l.per(t,.1))/2.56 end

function l.entropy(t,    e,n) 
  e,n=0,0
  for _,v in pairs(t) do n= n + v end
  for _,v in pairs(t) do e= e - v/n * math.log(v/n,2) end
  return e end
function l.defaults(t, defaults)
  t = t or {}
  for k,v in pairs(defaults) do
    if t[k] == nil then t[k] = v end end 
  return t end

function l.map(t,fun,...) --> t
  local u={};  for k,v in pairs(t) do u[1+#u] = fun(v,...) end; return u end

function l.kap(t,fun,...)  
  local u = {}; for k, v in pairs(t) do
                    u[1+#u] = fun(k,v,...) end; return u end

function l.items(t,fun,    u,i)  
  u={}; for k,_ in pairs(t) do u[1+#u]=k end
  table.sort(u,fun)
  i=0
  return function()
    if i<#u then i=i+1; return u[i], t[u[i]] end end end

function l.report(ts, header, nwidth, u, say)
    print(header)
    function say(x) io.write(l.fmt("%" .. (nwidth or 4) .. "s", x)) end
    u = {}
    for _, t in pairs(ts) do
      for k, _ in pairs(t) do u[1 + #u] = k end  
      table.sort(u)
      say ""; for _, k in pairs(u) do say(k) end; print ""
      for k1, t in l.items(ts) do
        say(k1); for _, k2 in pairs(u) do say(t[k2]) end; print "" end
      return 1 end end

-- ## thing to string
l.fmt = string.format

function l.cat(t)
  return table.concat(l.map(t,tostring),", ") end

function l.oo(any,  ndecs)  
  print(l.o(any,ndecs)); return any end

function l.o(any,  ndecs,     fun, u)  
  function fun(k, v)
    k = tostring(k)
    if not k:find "^_" then
      return l.fmt(":%s %s", k, l.o(v, ndecs)) end end
  if type(any) == "number" then return tostring(l.rnd(any,ndecs)) end
  if type(any) ~= "table" then return tostring(any) end
  u = #any == 0 and l.sort(l.kap(any, fun)) or l.map(any, l.o, ndecs)
  return "{"..table.concat(u,", ").."}" end 

-- ## string to thing
function l.coerce(s,    fun)
  function fun(s)
    if s=="nil" then return nil
    else return s=="true" or (s~="false" and s) end end
  return math.tointeger(s) or tonumber(s) or fun(s:match'^%s*(.*%S)') end

function l.cells(s1,    t)
  t={}; for s2 in s1:gmatch("([^,]+)") do t[1+#t]=l.coerce(s2) end; 
  return t end

function l.csv(src)
  src =  src=="" and io.input() or io.input(src)
  return function(   line)
    line = io.read()
    if line then return l.cells(line) else io.close(src) end end end

function l.cli(t) 
  for k,v in pairs(t) do
    v = tostring(v)
    for n,x in ipairs(arg) do
      if x=="-"..(k:sub(1,1)) or x=="--"..k then
        v= ((v=="false" and "true") or (v=="true" and "false") or arg[n+1])
        t[k] = l.coerce(v) end end end
  return t end
    
return l