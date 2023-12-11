-- [counts](counts.html) &rightarrow;  bayes
local l   = {}
local lib = require"lib"
local the,help = {},[[

golo: for ez SSL MOEA XAI, lo is less, less is more, go lo 
(c) 2023, Tim Menzies, BSD-2

USAGE:
  cat x.csv | lua golo.lua [OPTIONS]
  lua golo.lua -f x.csv [OPTIONS]
 
OPTIONS:
  -f --file   csv data file name                = -
  -h --help   show help                         = false 
  -k --k      handle low class frequencies      = 1
  -m --m      handle low attribute frequencies  = 2
  -p --p      distance coeffecient              = 2
  -w --wait   wait before classifications       = 20]]
-- --------- --------- --------- --------- --------- --------- -------- ----------
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

-- Update a SYM column. The default is to add one to
-- `sym1` (and that can be customized).
function l.sym(sym1,x,  n)
  if x~="?" then
    sym1.n      = (n or 1) + sym1.n
    sym1.has[x] = (n or 1) + (sym1.has[x] or 0)
    if sym1.has[x] > sym1.most then
      sym1.most, sym1.mode = sym1.has[x],x end end end

-- Update a NUM column
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

-- Middle value of a column distribution
function l.mid(col1)
  return  col1.isSym and col1.mode or lib.median(l.has(col1)) end

-- Diversity of values in a column distribution
function l.div(col1)
  return (col1.isSym and lib.ent or lib.stdev)(l.has(col1)) end

-- --------- --------- --------- --------- --------- --------- --------- ---------
-- ## COLS= multiple colums

-- Create one column
function l.COLS(t, -- e.g. {"Age","job","Salary+"}  
                x,y,all,klass,col1)
  x, y, all = {}, {}, {}
  for at, txt in pairs(t) do
    col1 =  l.COL(at,txt)
    lib.push(all, col1)
    if not txt:find"X$" then
      if txt:find"!$" then klass=col1 end
      (txt:find "[-!+]$" and y or x)[at]=col1 end end
  return {klass=klass, names=t, x=x, y=y, all=all} end

-- update a COLS
function l.cols(cols1, t)
  for _, col1 in pairs(cols1.all) do l.col(col1, t[col1.at]) end end

-- --------- --------- --------- --------- --------- --------- --------- ---------
-- ##  ROW 

-- store one row of data
function l.ROW(t) return {cells=t} end

-- --------- --------- --------- --------- --------- --------- --------- ---------
-- ##  DATA = rows + COLS

-- Create a DATA from a string (assumed to be a file name) or a list of rows.   
function l.DATA(src,    data1)
  data1 = {rows={}, cols=nil}
  if   type(src)=="string"
  then for   t in lib.csv(src) do l.data(data1,t) end
  else for _,t in   pairs(src) do l.data(data1,t) end end
  return data1 end

-- Create a new DATA, using the same structure as an older one.  
function l.clone(data1,  rows,      data2)
  data2 = l.DATA{data1.cols.names}
  for _,t in pairs(rows or {}) do l.data(data2,t) end
  return data2 end

-- Update DATA
function l.data(data1,xs)
  xs = xs.cells and xs or l.ROW(xs)
  if    data1.cols
  then  l.cols(data1.cols, xs.cells)
        lib.push(data1.rows, xs)
  else  data1.cols= l.COLS(xs.cells) end end

-- data2stats
function l.stats(data1, my,     t,fun)
  my  = lib.defaults(my,{cols="x",ndecs=2,report=the.report})
  fun = l[my.report]
  t   = {[".N"]=#data1.rows}
  for _,col1 in pairs(data1.cols[my.cols]) do
    t[col1.txt] = lib.rnd( fun(col1), my.ndecs) end
  return t end

-- --------- --------- --------- --------- --------- --------- --------- ---------
-- ## Naivve Bayes Classifier

-- Make new classifier (same creation pattern as `DATA`
function l.NB(src,    nb1)
  nb1 = {h=0, all=nil, datas={}, wait=the.wait, log=lib.ABCD()}
  if   type(src)=="string"
  then for   t in lib.csv(src) do l.nb(nb1,t) end
  else for _,t in   pairs(src) do l.nb(nb1,t) end end
  return nb1 end

-- Update NB
function l.nb(nb1,xs,     want)
  xs = xs.cells and xs or ROW(xs)
  if    nb1.all
  then  want = l.nbHas(nb1, xs)
        l.nbTest(nb1, xs,want)
        l.nbTrain(nb1, xs, want)
  else  nb1.all = l.DATA{xs} end end

-- Ensure we have a place to store data for this klass. 
function l.nbHas(nb1, row,       want)
  want = row.has[nb1.all.cols.klass.at]
  if not nb1.klasses[want] then
    nb1.h = nb1.h + 1
    nb1.klasses[want] = l.clone(nb1, nb1.all) end
  return nb1.klasses[want] end

-- If we've waited enough, try classifying something.
function l.nbTest(nb1 ,row,want,       got)
  if   nb1.wait > 1  
  then nb1.wait = nb1.wait - 1
  else got = l.likesMost(row.cells, nb1.datas,
                          #nb1.all.rows, nb1.h)
       l.abcd(nb1.abcd, want, got) end end

-- Update our distributions.
function l.nbTrain(nb1,row,want)
  l.data(nb1.datas[want], row)
  l.data(nb1.all,         row) end

-- Max like of one row `t` across many  `datas`
-- (and here, `data` == `H`).     
-- _argmax(i)  P(H<sub>i</sub>|E)_      
function l.likesMost(t,datas,n,h,     most,tmp,out)
  most = -1E30
  for k,data in pairs(datas) do
    tmp = l.likes(t,data,n,h)
    if tmp > most then out,most = k,tmp end end
  return out,most end

-- Likes of one row `t` in one `data`.           
-- _P(H|E) = P(E|H) P(H)/P(E)_      
-- or with our crrrent data structures:           
-- _P(data|t) = P(t|data) P(data) / P(t)_      
function l.likes(t,data,n,h,       prior,out,col1,inc)
  prior = (#data.rows + the.k) / (n + the.k * h)
  out   = math.log(prior)
  for at,v in pairs(t) do
    col1 = data.cols.x[at]
    if col1 and v ~= "?" then
      inc = l.like(col1,v,prior)
      out = out + math.log(inc) end end
  return out end

-- How much does a column like one value `x`?       
function l.like(col1,x,prior,    nom,denom)
  if   col1.isSym
  then return ((col1.has[x] or 0) + the.m*prior)/(col1.n+the.m)
  else local mid,sd = l.mid(col1),l.div(col1)
       if x > mid + 4*sd then return 0 end
       if x < mid - 4*sd then return 0 end
       nom   = math.exp(-.5*((x - mid)/sd)^2)
       denom = (sd*((2*math.pi)^0.5))
       return nom/(denom  + 1E-30) end end

-- --------- --------- --------- --------- --------- --------- --------- ---------
-- ## Clustering 

-- Normalize `x` 0..1 min..max (for NUMs), else return `x`.
function l.norm(col1,x,    a)
  a = l.has(col1)
  return (x=="?" or col1.isSym) and x or
         (x - a[1]) / (a[#a] - a[1] + 1E-30) end

-- Distance to heaven (using goal values).
function l.d2h(data1,row1,       n,d)
  n,d = 0,0
  for _,col1 in pairs(data1.cols.y) do
    n= n + 1
    d= d + (col1.heaven - l.norm(data1,row1.cells[col1.at]))^2 end
  return (d/n) ^ (1/the.p) end

-- Distance between two values in one column.
function l.dist(col1,x,y)
  if     x=="?" and y=="?" then return 1
  elseif col1.isSym
  then   return x==y and 0 or 1
  else   x,y = l.norm(col1,x), l.norm(col1,y)
         if x=="?" then x = y<.5 and 1 or 0 end
         if y=="?" then y = x<.5 and 1 or 0 end
         return math.abs(x - y) end end

-- Distance between two rows.
function l.dists(data1,row1,row2,      n,d,t1,t2)
  n,d,t1,t2   = 0, 0, row1.cells, row2.cells
  for _,col1 in pairs(data1.cols.y) do
    n = n +1
    d = d + l.dist(col1, t1[col1.at],t2[col1.at])^the.p end
  return (d/n) ^ (1/the.p) end

-- All neighbors in `rows`, sorted by dustance to `row1`,
function l.neighbors(data1,row1,rows,     fun)
  fun = function(row2) return l.dists(data1,row1,row2) end
  return l.keysort(rows or data1.rows, fun) end

-- Return two distance points, and the distance between them.
function l.twoFarPoints(data1,rows,  sortp,a,    b,far)
  far = (#rows*the.Far)//1
  a   = a or l.neighbors(data1, l.any(rows), rows)[far]
  b   = l.neighbors(data1, a, rows)[far]
  if sortp and l.d2h(data1,b) < l.d2h(data1,a) then a,b=b,a end
  return a, b, l.dists(data1,a,b) end

-- Divide `rows` into two halves, based on distance to two far points.
function l.half(data1,rows,sortp,before)
  local some,a,b,d,C,project,as,bs
  some  = l.many(rows, math.min(the.Half,#rows))
  a,b,C = l.twoFarPoints(data1, some, sortp, before)
  function d(row1,row2) return l.dists(data1,row1,row2) end
  function project(r)   return (d(r,a)^2 + C^2 -d(r,b)^2)/(2*C) end
  as,bs= {},{}
  for n,row1 in pairs(l.keysort(rows,project)) do
    l.push(n <=(#rows)//2 and as or bs, row1) end
  return as, bs, a, b, C, d(a, bs[1])  end

function l.tree(data1,sortp,      _tree)
  function _tree(data2,above,     lefts,rights,node)
    node = {here=data2}
    if   #data2.rows > 2*(#data1.rows)^.5
    then lefts, rights, node.left, node.right, node.C, node.cut =
                            l.half(data1,data2.rows,sortp,above)
         node.lefts  = _tree(l.clone(data1, lefts),  node.left)
         node.rights = _tree(l.clone(data1, rights), node.right) end
    return node end
  return _tree(data1) end

function l.branch(data1,  sortp,      _,rest,_branch)
  rest = {}
  function _branch(data2,  above,    left,lefts,rights)
    if #data2.rows > 2*(#data1.rows)^.5
    then lefts,rights,left = l.half(data1,data2.rows,sortp,above)
         for _,row1 in pairs(rights) do l.push(rest,row1) end
         return _branch(l.clone(data1,lefts),left)
    else return data2.rows, rest end end
  return _branch(data1) end

function l.climb(node, fun, depth)
  if node then
    depth = depth or 0
    fun(node, depth, not (node.lefts or node.rights))
    l.climb(node.lefts,  fun, depth+1)
    l.climb(node.rights, fun, depth+1) end end

function l.tshow(node1,     _show,depth1)
  depth1 = 0
  function _show(node2,depth,leafp,     post)
    post = leafp and l.o(l.stats(node2.here)) or ""
    depth1  = depth
    print(('|.. '):rep(depth), post) end
  l.climb(node1, _show); print""
  print( ("    "):rep(depth1), l.o(l.stats(node1.here))) end

-- --------- --------- --------- --------- --------- --------- --------- ---------
--- ## Discretization

-- Create a RANGE  that tracks the y dependent values seen in 
-- the range `lo` to `hi` some independent variable in column number `at` whose name is `txt`. 
-- Note that the way this is used (in the `bins` function, below)
-- for  symbolic columns, `lo` is always the same as `hi`.
function l.RANGE(at,txt,lo,hi)
  return {n=0,at=at,txt=txt,lo=lo,hi=lo or hi or lo,y=l.SYM()} end

-- Update a RANGE to cover `x` and `y`
function l.range(range1,n,s)
  range1.lo = math.min(n, range1.lo)
  range1.hi = math.max(n, range1.hi)
  range1.n  = range1.n + 1
  l.sym(range1.y, s) end

function l.merge(range1,range2,     range3)
  range3   = l.RANGE(range1.at, range1.txt, range1.lo, range2.hi)
  range3.n = range1.n + range2.n
  for _,t in pairs{range1.y,range2.y} do
    for k,v in pairs(t) do 
      l.sym(range3,k,v) end end
  return range3 end

function l.merged(range1,range2,few,   range3,e1,e2,e3,n1,n2,n3) 
  range3 = l.merge(range1, range2)
  e1, e2, e3 = lib.ent(range1.y), lib.ent(range2.y), lib.ent(range3.y)
  n1, n2, n3 = range1.n, range2.n, range3.n 
  if n1 <= few or  n2 <= few or e3 <= (e1*n1 + e2*n2) / n3 then
    return range3 end end

-- Map `x` into a small number of bins. `SYM`s just get mapped
-- to themselves but `NUM`s get mapped to one of `is.bins` values.
function l.bin(col1,x,      gap,t,lo,hi)
  if x=="?" or col1.isSym then return x end
  t     = l.has(col1)
  lo,hi = t[1], t[#t]
  gap   = (hi - lo) / (the.bins - 1)
  return hi == lo and 1 or math.floor(x/gap + .5)*gap end

-- Return RANGEs that distinguish sets of rows (stored in `rowss`).
-- To reduce the search space,
-- values in `col` are mapped to small number of `bin`s.
-- For NUMs, that number is `the.bins=16` (say) (and after dividing
-- the column into, say, 16 bins, then we call `merges` to see
-- how many of them can be combined with their neighboring bin).
function l.discretize(rowss,cols,   t,tmp,n)
  t={}
  for k,col1 in pairs(cols) do
    tmp,n = l.bins(rowss, col1)
    t[k]  = col1.isSym and tmp or l.noGaps(l.merges(tmp, n^the.min)) end
  return t end

function l.bins(rowss,col1,   t,c,x,k,n)
  t = {}
  n = 0
  for y,rows in pairs(rowss) do
    for _,row1 in pairs(rows) do
      x = row1.cells[col1.at]
      if x ~= "?" then
        n    = n + 1
        k    = l.bin(col1,x)
        t[k] = t[k] or l.RANGE(col1.at, col1.txt, x)
        l.range(t[k],x,y) end end end
  return lib.sort(lib.map(t, lib.self), lib.lt"lo"),n end

function l.noGaps(t)
  for j = 2,#t do t[j].lo = t[j-1].hi end
  t[1].lo  = -math.huge
  t[#t].hi =  math.huge
  return t end

function l.merges(ranges,few,    tmp,i,a,b)
  tmp,i = {},1
  while i <= #ranges do
    a = ranges[i]
    if i < #ranges then
      b = l.merged(a, ranges[i+1], few)
      if b then
        a = b
        i = i + 1 end end
    lib.push(tmp, a)
    i = i + 1 end
  return #tmp == #ranges and ranges or l.merges(tmp,few) end