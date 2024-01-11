local the = {file="../data/auto93.csv", k=1, m=2}

local function csv(src,    i,words,fun,coerce)
  function f1(s) return s=="true" or s~="false" and s end
  function f(s)  return math.tointeger(s) or tonumber(s) or f1(s:match'^%s*(.*%S)') end
  function fs(s) local t={}; for x in s:gmatch"([^,]+)" do t[1+#t]=f(x) end; return t end
  i,src = 0,src=="-" and io.stdin or io.input(src)
  return function(      s)
    s=io.read()
    if s then i=i+1; return i,fs(s) else io.close(src) end end end


