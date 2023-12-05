-- <img src="refactor.png" width=400><br>
-- [home](index.html) :: [lib](lib.html)
-- :: count &rightarrow; [counts](counts.html) 


local l   = {}
local lib = require"lib"
local the = {file="",report="mid"}

-- ## Create one column

-- Create NUMs
function l.NUM(at,txt) 
  return {at=at, txt=txt, n=0, has={},
          isSorted=true,
          heaven= (txt or ""):find"-$" and 0 or 1} end

-- Create SYMs
function l.SYM(at,txt) 
  return {at=at, txt=txt, n=0, has={},
          mode=nil, most=0, isSym=true} end

-- Create COLs: (SYMs or NUMs)
function l.COL(at,txt)
  return ((txt or ""):find"^[A-Z]" and l.NUM or l.SYM)(at,txt) end

-- Update one column
function l.col(col1,x)
  return (col1.isSym  and l.sym or l.num)(col1,x) end

-- Update a SYM
function l.sym(sym1,x)
  if x~="?" then
    sym1.n = sym1.n + 1
    sym1.has[x] = 1 + (sym1.has[x] or 0)
    if sym1.has[x] > sym1.most then
      sym1.most, sym1.mode = sym1.has[x],x end end end

-- Update a NUM
function l.num(num1,x)
  if x~="?" then
    num1.n = num1.n + 1
    lib.push(num1.has,x)
    num1.isSorted=false end end 

-- Query one column
function l.has(col1)
  if not (col1.isSym or col1.isSorted) then 
    table.sort(col1.has); col1.isSorted=true end
  return col1.has end

-- Central tendency 
function l.mid(col1) 
  return  col1.isSym and col1.mode or lib.median(l.has(col1)) end

-- Diversity around central tendency
function l.div(col1) 
  return (col1.isSym and lib.entropy or lib.stdev)(l.has(col1)) end

-- ## COLS = multiple colums

-- Creation
function l.COLS(t, -- e.g. "Age,job,Salary+"    
                x,y,all,klass,col1)  
  x, y, all = {}, {}, {}
  for at, txt in pairs(t) do
    col1 =  l.COL(at,txt)
    lib.push(all, col1)
    if not txt:find"X$" then
      if txt:find"!$" then klass=col1 end
      (txt:find "[-!+]$" and y or x)[at]=col1 end end
  return {klass=klass, names=t, x=x, y=y, all=all} end

-- Update a COLS
function l.cols(cols1, t)
  for _, col1 in pairs(cols1.all) do l.col(col1, t[col1.at]) end end

-- ## DATA = rows + a COLS

-- Creation
function l.DATA(src,    data1)
  data1 = {rows={}, cols=nil}
  if src then for t in lib.csv(src) do l.data(data1,t) end end
  return data1 end

-- Update data
function l.data(data1,t)
  if    data1.cols -- not our first row
  then  l.cols(data1.cols, t)
        lib.push(data1.rows, t)
  else  data1.cols= l.COLS(t) end end

--  Query   data
function l.stats(data1, my,     t,fun) 
  my  = lib.defaults(my,{cols="x",ndecs=2,report=the.report})
  fun = l[my.report]
  t   = {[".N"]=#data1.rows}
  for _,col1 in pairs(data1.cols[my.cols]) do
    t[col1.txt] = lib.rnd( fun(col1), my.ndecs) end
  return t end

-- ## Main
lib.oo(
  l.stats(
    l.DATA(
      lib.cli(the).file)))