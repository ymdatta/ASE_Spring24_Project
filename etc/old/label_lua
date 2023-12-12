--<!-- vim: set syntax=lua ts=3 sw=3 et : -->
local l   = {}
local lib = require"lib"

function l.DATA(src,    data1)
  data1={rows={}, heaven=nil, ynums}
  lib.csv(src, function(nr,s) l.data(data1,nr,s) end)
for k,t in pairs(data1.ynums) do
  

function l.data(data1,nr,s)
  if nr==0 then
    print(s,"klass")
    for for k,v in pairs(lib.cells(s)) do
      if  v:find"^[A-Z]" then
        if v:find"-$" then data1.heaven[k] = 0 end
        if v:find"+$" then data1.heaven[k] = 1 end end end 
  else
    data1.rows[nr] = {}
    for k,v in pairs(lib.cells(s)) do
      data1.rows[nr][k] = v
      if data1.heaven[k] then
        if v ~="?" then lib.push(data1.ynums[k],v) end end end end end

function distance2heaven(t,data1,    n,d)
  n,d=0,0
  for k,v in pairs(data1.heaven) do
    n=n+1
    d=
function distances2heaven(data1)
  for _,t in pairs(data1.rows) do
    print(cat(t)..","..distance2heaven(t,data1) end end
     