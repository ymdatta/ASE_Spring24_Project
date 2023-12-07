-- <img src="refactor.png" width=400><br>
-- [home](index.html) :: [github](https://github.com/timm/min) ::
-- [issues](https://github.com/timm/min/issues) :: [lib](lib.html)
-- ::  [count](count.html) &rightarrow;  counts &rightarrow; [bayes](bayes.html)
--       
--     $ lua counts.lua -f ../data/diabetes.csv 
--   
--      mids
--                    .N     Age    Insu    Mass    Pedi    Plas   ...
--          neg     500      27      38      30    0.34     107   ...
--          pos     268      36       0    34.2    0.45     140   ...
--    
--      divs
--                    .N     Age    Insu    Mass    Pedi    Plas   ...
--          neg     500   10.53   71.37    6.63    0.25   23.79   ...
--          pos     268   10.92  105.69    6.24    0.33    31.2   ...

local lib      = require "lib"
local l        = {}
local the,help = {},[[

counts: report stats for each class in a csv file
(c) 2023, Tim Menzies, BSD-2

USAGE:
  cat x.csv | lua counts.lua [OPTIONS]
  lua counts.lua -f x.csv [OPTIONS]
 
OPTIONS:
  -f --file    csv data file name           = ""
  -h --help    show help                    = false ]]

-- ##  One Column

-- Create one NUM
function l.NUM(txt,at) 
  return {at=at, txt=txt, n=0, has={},
          isSorted=true,
          heaven= (txt or ""):find"-$" and 0 or 1} end

-- Create one SYM
function l.SYM(txt,at) 
  return {at=at, txt=txt, n=0, has={},
          mode=nil, most=0, isSym=true} end

-- Create one COL
function l.COL(txt,at)
  return ((txt or ""):find"^[A-Z]" and l.NUM or l.SYM)(txt,at) end

--  Update one column
function l.col(col1,x)
  return (col1.isSym  and l.sym or l.num)(col1,x) end

-- Update a SYM column
function l.sym(sym1,x)
  if x~="?" then
    sym1.n = sym1.n + 1
    sym1.has[x] = 1 + (sym1.has[x] or 0)
    if sym1.has[x] > sym1.most then
      sym1.most, sym1.mode = sym1.has[x],x end end end

-- Update a NUM column
function l.num(num1,x)
  if x~="?" then
    num1.n = num1.n + 1
    lib.push(num1.has,x)
    num1.isSorted=false end end 

-- Query one column.
function l.has(col1)
  if not (col1.isSym or col1.isSorted) then
    table.sort(col1.has); col1.isSorted=true end
  return col1.has end

-- Middle value of a column distribution
function l.mid(col1) 
  return  col1.isSym and col1.mode or lib.median(l.has(col1)) end

-- Diversity of values in a column distribution.
function l.div(col1) 
  return (col1.isSym and lib.entropy or lib.stdev)(l.has(col1)) end

-- ## COLS= multiple colums

-- Create one column.
function l.COLS(t, -- e.g. {"Age","job","Salary+"} 
                x,y,all,klass,col1)
  x, y, all = {}, {}, {}
  for at, txt in pairs(t) do
    col1 = l.COL(txt,at)
    lib.push(all, col1)
    if not txt:find"X$" then
      if txt:find"!$" then klass=col1 end
      (txt:find "[-!+]$" and y or x)[at]=col1 end end
  return {klass=klass, names=t, x=x, y=y, all=all} end

-- update a COLS
function l.cols(cols1, t)
  for _, col1 in pairs(cols1.all) do l.col(col1, t[col1.at]) end end

-- ##  DATA = rows + COLS

-- Create a DATA from a string (assumed to be a file name) or a list of rows.   
-- MODIFIED
function l.DATA(src,    data1)
  data1 = {rows={}, cols=nil}
  if   type(src)=="string"
  then for   t in lib.csv(src) do l.data(data1,t) end
  else for _,t in pairs(src)   do l.data(data1,t) end end
  return data1 end

-- Create a new DATA, using the same structure as an older one.  
-- NEW
function l.clone(data1,  rows,      data2)
  data2 = l.DATA({data1.cols.names})
  for _,t in pairs(rows or {}) do l.data(data2,t) end
  return data2 end

-- Update DATA
function l.data(data1,t)
  if    data1.cols
  then  l.cols(data1.cols, t)
        lib.push(data1.rows, t)
  else  data1.cols= l.COLS(t) end end

-- Query data
function l.stats(data1, my,     t,fun) 
  my  = lib.defaults(my,{cols="x",ndecs=2,report=the.report})
  fun = l[my.report]
  t   = {[".N"]=#data1.rows}
  for _,col1 in pairs(data1.cols[my.cols]) do
    t[col1.txt] = lib.rnd( fun(col1), my.ndecs) end
  return t end

-- ## Main

-- Main         
-- NEW
function l.main(     datas,all,k,divs,mids)
  the=lib.cli(the)
  datas,mids,divs,all = {},{},{},nil
  for row in lib.csv(the.file) do
    if   all
    then k = row[all.cols.klass.at]
         datas[k] = datas[k] or l.clone(all)
         l.data(datas[k], row)
    else all = l.DATA({row}) end
  end
  for k, data1 in pairs(datas) do
    mids[k] = l.stats(data1, { report = "mid" })
    divs[k] = l.stats(data1, { report = "div" })
  end
  lib.report(mids,"\nmids",8)
  lib.report(divs,"\ndivs",8) end

the = lib.settings(help)
l.the = the
if  pcall(debug.getlocal,4,1) then  main() end

return l
