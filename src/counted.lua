local lib = require"Lib"
local l   = require"count"
local eg  = {}

function eg.sym(s)
  sym1 = l.SYM()
  for _,x in pairs{1,1,1,1,2,2,3} do col(sym1,x)  end
  md,sd = l.mid(sym1), l.div(sym1)
  print(md,div)
  return 1.37< md and div < 1.38 end

function eg.num(     n,md,sd)
  num1 = l.NUM() 
  for i=1,100 do col(num1, i) end
  md,div = l.mid(num1), l.div(num1)
  print(md,div)
  return 50 < md and md < 51 and 29 < div and div < 30 end

lib.run(l.the,eg)