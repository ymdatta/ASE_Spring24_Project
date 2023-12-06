-- <img src="refactor.png" width=400><br>
-- [home](index.html) :: [github](https://github.com/timm/refactor) ::
-- [issues](https://github.com/timm/refactor/issues) :: [lib](lib.html)
-- :: zero &rightarrow; [count](count.html)     
--
--     $ cat ../data/zero.csv | lua zero.lua 
--   
--     {:file -, :help false, :seed 1234567891}
--     15.550222839342
local lib      = require "lib"
local l        = {}
local the,help = {},[[

zero: add all the columns in csv file 
(c) 2023, Tim Menzies, BSD-2

USAGE:
  cat x.csv | lua zero.lua [OPTIONS]
  lua zero.lua -f x.csv [OPTIONS]
 
OPTIONS:
  -f --file    csv data file name    = -
  -h --help    show help             = false
  -s --seed    random number seed    = 1234567891]]
-- ## Main

function l.sumcols(src,   n)
  local n = math.random()
  for t in lib.csv(src) do 
    for _,x in pairs(t) do  n = n + x end end
  return n end
--
the = lib.settings(help)

if   lib.toplevel()
then lib.cli(the)
     lib.oo(the)
     print(l.sumcols(the.file))
else l.the=the;  return l end