local lib = require"Lib"
local l   = require"zero"
local eg  = {}

function eg.sumcols(      n) 
  n = l.sumcols("../data/zero.csv") 
  return 15 < n  and n < 15.1 end
  
lib.run(l.the,eg)
