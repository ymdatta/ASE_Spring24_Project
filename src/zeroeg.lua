-- <img src="refactor.png" width=400><br>
-- [home](https://timm.github.io/min/index.html) :: [github](https://github.com/timm/min) ::
-- [issues](https://github.com/timm/min/issues) :: [lib](lib.html)
local lib = require"Lib"
local l   = require"zero"
local eg  = {}

function eg.sumcols(      n) 
  n = l.sumcols("../data/zero.csv") 
  return 15 < n  and n < 15.1 end
  
lib.run(l.the,eg)
