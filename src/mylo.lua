-- .
local b4={}; for k, _ in pairs(_ENV) do b4[k]=k end
local l,the,help = {},{},[[
mylo: recursive bi-clustering via random projections (lo is less. less is more. go lo)
(c) 2023, Tim Menzies, BSD-2

USAGE:
  lua mylo.lua [OPTIONS]

OPTIONS:
  -b --bins   max number of bins              = 16
  -B --Beam   max number of ranges            = 10
  -c --cohen  small effect size               = .35
  -C --Cut    ignore ranges less than C*max   = .1
  -f --file   csv data file name              = ../data/diabetes.csv
  -F --Far    how far to search for faraway?  = .95
  -h --help   show help                       = false
  -H --Half   #items to use in clustering     = 256
  -p --p      weights for distance            = 2
  -s --seed   random number seed              = 31210
  -S --Support coeffecient on best            = 2
  -t --todo   start up action                 = help]]

-- ----------------------------------------------------------------------------
-- ## Classes
local function isa(x,y) return setmetatable(y,x) end
local function is(s,    t) t={a=s}; t.__index=t; return t end

-- ## Columns
-- ### Symbols

-- Create
local SYM=is"SYM"
function SYM.new(s,n)
  return isa(SYM, {txt=s or " ", at=n or 0, n=0, has={}, mode=nil, most=0}) end
 
-- Update
function SYM:add(x)
  if x ~= "?" then 
    self.n = self.n + 1
    self.has[x] = 1 + (self.has[x] or 0)
    if self.has[x] > self.most then 
      self.most,self.mode = self.has[x], x end end end

-- Query
function SYM:mid() return self.mode end

function SYM:div() return l.entropy(self.has) end 
  
function SYM:small() return 0 end

-- Distance
function SYM:dist(x,y)
  return  (x=="?" and y=="?" and 1) or (x==y and 0 or 1) end

-- Discertization 
function SYM:bin(x) return x end

-- ### Numerics

-- Create
local NUM=is"NUM"
function NUM.new(s, n)
  return isa(NUM, {txt=s or " ", at=n or 0, n=0, mu=0, m2=0, hi=-1E30, lo=1E30,
              heaven = (s or ""):find"-$" and 0 or 1}) end

-- Update
function NUM:add(x,     d)
  if x ~="?" then
    self.n  = self.n+1
    d       = x - self.mu
    self.mu = self.mu + d/self.n
    self.m2 = self.m2 + d*(x - self.mu)
    self.lo = math.min(x, self.lo)
    self.hi = math.max(x, self.hi) end end

-- Query
function NUM:mid() return self.mu end

function NUM:div() return self.n < 2 and 0 or (self.m2/(self.n - 1))^.5 end

function NUM:small() return the.cohen*self:div() end

function NUM:norm(x)
  return x=="?" and x or (x - self.lo) / (self.hi - self.lo + 1E-30) end

-- Distance
function NUM:dist(x,y)
  if x=="?" and y=="?" then return 1 end
  x,y = self:norm(x), self:norm(y)
  if x=="?" then x=y<.5 and 1 or 0 end
  if y=="?" then y=x<.5 and 1 or 0 end
  return math.abs(x-y) end

-- Discertization 
function NUM:bin(x,     tmp)
  tmp = (self.hi - self.lo) / (the.bins - 1)
  return self.hi == self.lo and 1 or math.floor(x / tmp + .5) * tmp end
    
-- ### Columns
-- A contrainer storing multiple `NUM`s and `SYM`s.

-- Create a set of columns from a set of strings. If uppercase
-- then `NUM`, else `SYM`. `Klass`es end in `!`. Numeric goals to
-- minimize of maximize end in `-`,`+`. Keep all cols in `all`.
-- Also add dependent columns to `y` (anthing ending in `-`,`+`,`!`) and
-- independent columns in `x` (skipping over anyhing ending in `X`).
local COLS=is"COLS"
function COLS.new(row)
  local x,y,all = {},{},{}
  local klass,col
  for at,txt in pairs(row.cells) do
    col = (txt:find"^[A-Z]" and NUM or SYM).new(txt,at)
    all[1+#all] = col
    if not txt:find"X$" then
      if txt:find"!$" then klass=col end
      (txt:find"[!+-]$" and y or x)[at] = col end end
  return isa(COLS, {x=x, y=y, all=all, klass=klass, names=row.cells}) end

-- Update
function COLS:add(row)
  for _,cols in pairs{self.x, self.y} do
    for _,col in pairs(cols) do
      col:add(row.cells[col.at]) end end 
  return row end 

-- ### ROW

-- Store cells.
local ROW=is"ROW"
function ROW.new(t) return isa(ROW, { cells = t }) end

-- Distance to best values (and _lower_ is _better_).
function ROW:d2h(data,     d,n,p)
  d, n, p = 0, 0, 2
  for _, col in pairs(data.cols.y) do
    n = n + 1
    d = d + math.abs(col.heaven - col:norm(self.cells[col.at])) ^ p end
  return (d/n)^(1/p) end

-- Minkowski dsitance (the.p=1 is taxicab/Manhattan; the.p=2 is Euclidean)
function ROW:dist(other,data,     d,n,p)
  d, n, p = 0, 0, the.p
  for _, col in pairs(data.cols.x) do
    n = n + 1
    d = d + col:dist(self.cells[col.at], other.cells[col.at]) ^ p end
  return (d/n)^(1/p) end

-- All neighbors in `rows`, sorted by dustance to `row1`,
function ROW:neighbors(data,  rows)
  return l.keysort(rows or data.rows,
                   function(row) return self:dist(row,data) end) end


-- ### Data
-- Store `rows`, summarized in `COL`umns.

-- Some Lua trivia (needed to access a class, defined later). 
local NODE

-- Create from either a file name or a list of rows
local DATA=is"DATA"
function DATA.new(src,  fun,     self)
  self = isa(DATA, {rows={}, cols=nil})
  if   type(src) == "string"
  then for _,x in l.csv(src)       do self:add(x, fun) end
  else for _,x in pairs(src or {}) do self:add(x, fun) end end
  return self end

-- Update. First time through, assume the row defines the columns.
-- Otherwise, update the columns then store the rows. If `fun` is
-- defined, call it before updating anything.
function DATA:add(t,  fun,row)
  row = t.cells and t or ROW.new(t)
  if   self.cols
  then if fun then fun(self,row) end
       self.rows[1 + #self.rows] = self.cols:add(row)
  else self.cols = COLS.new(row) end end

-- Query
function DATA:mid(cols,   u) 
  u = {}; for _, col in pairs(cols or self.cols.all) do u[1 + #u] = col:mid() end
  return ROW.new(u) end

function DATA:div(cols,    u) 
  u = {}; for _, col in pairs(cols or self.cols.all) do u[1 + #u] = col:div() end;
  return ROW.new(u) end

function DATA:small(    u)
  u = {}; for _, col in pairs(self.cols.all) do u[1 + #u] = col:small(); end
  return ROW.new(u) end 

function DATA:stats(cols,fun,ndivs,    u)
  u = {[".N"] = #self.rows}
  for _,col in pairs(self.cols[cols or "y"]) do
    u[col.txt] = l.rnd(getmetatable(col)[fun or "mid"](col), ndivs) end
  return u end

function DATA:clone(  rows,     new)
  new=DATA.new{self.cols.names}
  for _,row in pairs(rows or {}) do new:add(row) end
  return new end

-- ### Clustering
-- Recursive binary clustering returns a tree. That tree is build from `NODE`s.
-- See also, some extensions to DATA (below).
NODE=is"NODE"
function NODE.new(data) return isa(NODE, { here = data }) end

-- Walk over a tree, call `fun` on each node.
function NODE:walk(fun, depth)
  depth = depth or 0
  fun(self, depth, not (self.lefts or self.rights))
  if self.lefts  then self.lefts:walk(fun, depth+1) end
  if self.rights then self.rights:walk(fun,depth+1) end end

-- Print a tree by printing each node.
function NODE:show(_show, maxDepth)
  local function d2h(data) return l.rnd(data:mid():d2h(self.here)) end
  maxDepth = 0
  function _show(node, depth, leafp,      post) 
    post     = leafp and (d2h(node.here) .."\t".. l.o(node.here:mid().cells)) or ""
    maxDepth = math.max(maxDepth,depth)
    print(('|.. '):rep(depth), post)  end
  self:walk(_show); print""
  print( ("    "):rep(maxDepth), d2h(self.here),l.o(self.here:mid().cells) )
  print( ("    "):rep(maxDepth), "_",   l.o(self.here.cols.names))
  end

-- Return two distance points, and the distance between them.
-- If `sortp` then ensure `a` is better than `b`.
function DATA:farapart(rows,  sortp,a,    b,far,evals)
  far = (#rows * the.Far) // 1
  evals   = a and 1 or 2
  a   = a or l.any(rows):neighbors(self, rows)[far]
  b   = a:neighbors(self, rows)[far]
  if sortp and b:d2h(self) < a:d2h(self) then a,b=b,a end
  return a, b, a:dist(b,self),evals end

-- Divide `rows` into two halves, based on distance to two far points.
function DATA:half(rows,sortp,before,evals)
  local some,a,b,d,C,project,as,bs
  some  = l.many(rows, math.min(the.Half,#rows))
  a,b,C,evals = self:farapart(some, sortp, before)
  function d(row1,row2) return row1:dist(row2,self)  end
  function project(r)   return (d(r,a)^2 + C^2 -d(r,b)^2)/(2*C) end
  as,bs= {},{}
  for n,row in pairs(l.keysort(rows,project)) do
    table.insert(n <=(#rows)//2 and as or bs, row) end
  return as, bs, a, b, C, d(a, bs[1]), evals end

-- Recursive random projects.  `Half` then data, then recurse on each half.
function DATA:tree(sortp, _tree,      evals,evals1)
  evals = 0
  function _tree(data,above,     lefts,rights,node)
    node = NODE.new(data)
    if   #data.rows > 2*(#self.rows)^.5
    then lefts, rights, node.left, node.right, node.C, node.cut, evals1 =
                self:half(data.rows, sortp, above)
          evals = evals + evals1
          node.lefts  = _tree(self:clone(lefts),  node.left)
          node.rights = _tree(self:clone(rights), node.right) end
    return node end
  return _tree(self),evals end

-- Optimization via tecursive random projects. 
-- `Half` then data, then recurse on the best half. 
function DATA:branch(  stop,           rest, _branch,evals)
  evals, rest = 1, {}
  stop = stop or (2*(#self.rows)^.5)
  function _branch(data, above, left, lefts, rights)
      if #data.rows > stop
      then lefts, rights, left = self:half(data.rows, true, above)
           evals=evals+1
           for _, row1 in pairs(rights) do rest[1+#rest]= row1 end
           return _branch(data:clone(lefts), left)
      else return self:clone(data.rows), self:clone(rest),evals end end
  return _branch(self)  end

-- ----------------------------------------------------------------------------
-- ## -- ## Discretization

-- Return RANGEs that distinguish sets of rows (stored in `rowss`).
-- To reduce the search space,
-- values in `col` are mapped to small number of `bin`s.
-- For NUMs, that number is `the.bins=16` (say) (and after dividing
-- the column into, say, 16 bins, then we call `mergeAny` to see
-- how many of them can be combined with their neighboring bin).
local RANGE=is"RANGE"
function RANGE.new(col,txt,lo,    hi)
  return isa(RANGE, {col=col, txt=txt, scored=0,
                     x = { lo = lo, hi = hi or lo },
                     y = {}}) end

function RANGE:add(x,y)
  self.x.lo = math.min(self.x.lo, x)
  self.x.hi = math.max(self.x.hi, x)
  self.y[y] = (self.y[y] or 0) + 1 end

-- Given a goal class, and a count `B,R`  of what we like/hate,
-- score range by probablity of selecting the liked class.
function RANGE:score(goal, LIKE, HATE)
  return l.score(self.y,goal,LIKE,HATE) end

function RANGE:merge(other,   both)
  both = RANGE.new(self.col, self.txt, self.x.lo)
  both.x.lo = math.min(self.x.lo, other.x.lo)
  both.x.hi = math.max(self.x.hi, other.x.hi)
  for _,t in pairs{self.y, other.y} do
    for k,v in pairs(t) do 
      both.y[k] = (both.y[k] or 0) + v end end
  return both end

function RANGE:merged(other,tooFew,     both,e1,n1,e2,n2)
  both  = self:merge(other) 
  e1,n1 = l.entropy(self.y)
  e2,n2 = l.entropy(other.y)
  if n1 <= tooFew or n2 <= tooFew then return both end
  if l.entropy(both.y) <= (n1*e1 + n2*e2) / (n1+n2) then
    return both end end

-- Study rows, divided into class `y`. For row values, discretize
-- then into a `bin`. Track what `y`s are associated with what `bin`s.
-- Merge bins that are too small or which do not add much information to the mix.
local _ranges, _ranges1, _mergeds
function _ranges(cols,rowss,     t)
  t={}
  for _, col in pairs(cols) do
    for _, range in pairs(_ranges1(col, rowss)) do
      t[1 + #t] = range end end
  return t end
  
function _ranges1(col,rowss,    out,x,bin,nrows)
  out,nrows = {},0
  for y, rows in pairs(rowss) do
    nrows = nrows + #rows
    for _, row in pairs(rows) do
      x = row.cells[col.at]
      if  x ~= "?" then
        bin = col:bin(x)
        out[bin] = out[bin] or RANGE.new(col.at, col.txt, x)
        out[bin]:add(x,y) end end end
  out = l.asList(out)
  table.sort(out, function(a,b) return a.x.lo < b.x.lo end)
  return col.has and out or _mergeds(out, nrows/the.bins) end

-- Bottom-up clustering. Try to merge neighbors. Stop when no new merges found.
-- Before returning, ensure ranges span -inf to +inf with no gaps in the middle.
function _mergeds(ranges,tooFew,  i,a,t,both)
  i,t = 1,{}
  while i <= #ranges do
    a = ranges[i]
    if i < #ranges then
      both = a:merged(ranges[i+1],tooFew)
      if both then 
        a = both
        i = i+1 end end
    t[1+#t] = a
    i = i+1 end
  if #t < #ranges then return _mergeds(t,tooFew) end
  for i = 2,#t do t[i].x.lo = t[i-1].x.hi end
  t[1].x.lo  = -math.huge
  t[#t].x.hi =  math.huge
  return t end

-- ----------------------------------------------------------------------------
-- ## Explanation

-- ## RULE

-- Create
local RULE=is"RULE"
function RULE.new(ranges, rule, t)
    rule = isa(RULE, { parts = {}, scored = 0 })
    for _, range in pairs(ranges) do
        rule.parts[range.txt] = rule.parts[range.txt] or {}
        t                     = rule.parts[range.txt]
        t[1 + #t]             = { lo = range.x.lo, hi = range.x.hi, at = range.at }
    end
    return rule
end
  
function RULE:disjunction(ranges, row, x, lo, hi)
  l.oo(ranges)
  x = row.cells[ranges[1].at]
  if x == "?" then return true end
  for _, range in pairs(ranges) do
    l.oo(range)
    lo,hi = range.x.lo, range.x.hi
    if lo==hi and lo == x or lo<=x and x <hi then return true end end
  return false end

function RULE:conjunction(row)
  for _,ranges in pairs(self.parts) do
    if not self:disjunction(ranges,row) then return false end end
  return true end

function RULE:selects(rows,    t)
  t = {}; for _,r in pairs(rows) do
            if self:conjunction(r) then t[1+#t]=r end end; return t end

function RULE:selectss(rowss, t)
  t={}; for y,rows in pairs(rowss) do t[y] = #self:selects(rows) end; return t end

local _showMerge,_showPretty
function RULE:show(        t,u,v)
  t = {}
  for txt,ranges in pairs(self.parts) do
    table.sort(ranges,function(a,b) return a.lo < b.lo end)
    u,v = {},{}
    for _,r in pairs(ranges) do u[1+#u] = {r.lo, r.hi, r.at} end
    for _,two in pairs(_showMerge(u)) do v[1+#v] = _showPretty(txt,two) end
    t[1+#t] = table.concat(v," or ") end 
  return table.concat(t," and ") end

function _showMerge(t,     i,u,a,b)
  i,u = 1,{}
  while i <= #t do
    a = t[i]
    if i < #t then
      b = t[i+1]
      if a[2] == b[1] then
        a = {a[1], b[2], a[3]}
        i=i+1 end end
    u[1+#u] = a
    i=i+1  end
  return  #u == #t and t or _showMerge(u) end

function _showPretty(txt, r)
  if r[1] == -math.huge then return l.fmt("%s < %s",txt,r[2]) end
  if r[2] ==  math.huge then return l.fmt("%s >= %s",txt,r[1]) end
  if r[1] == r[2]       then return l.fmt("%s == %s",txt,r[1]) end
  return l.fmt("%s <= %s < %s", r[1], txt, r[2]) end

-- ## RULES
-- Manages the process of scoring ranges, trying all their combinations, 
-- scoring the combinations, returning the result.
local RULES=is"RULE"
function RULES.new(ranges, goal, rowss, self)
  for k,v in pairs(rowss) do print(k,#v) end
  self = isa(RULES, {sorted={}, goal=goal,rowss=rowss, LIKE=0, HATE=0})
    self:likeHate()
  print(3)
  for _, range in pairs(ranges) do l.oo(range); range.scored = self:score(range.y) end
  print(1)
  self.sorted = self:top( self:try( self:top(ranges)))
  return self end

function RULES:likeHate()
  for y,rows in pairs(self.rowss) do
    if   y == self.goal
    then self.LIKE = self.LIKE + #rows 
    else self.HATE = self.HATE + #rows end end end

function RULES:score(t, x)
  print(200,l.o(t),self.goal, self.LIKE,self.HATE)
  x =  l.score(t, self.goal, self.LIKE, self.HATE)
    
  print(100,x)
    
  return x end

function RULES:try(ranges,     u, rule)
  u={}
  for _,subset in pairs(l.powerset(ranges)) do
    rule  = RULE.new(subset)
    u[1+#u] = rule
    rule.scored = self:score( rule:selectss(self.rowss) ) end 
  return u end

function RULES:top(t,       u)
  table.sort(t, function(a,b) return a.scored > b.scored end)
  u = {}
  for _,x in pairs(t) do
    if x.scored >= t[1].scored * the.Cut then
      u[1+#u] = x end end
  return l.slice(u, 1, the.Beam) end

-- ----------------------------------------------------------------------------
-- ## Library Functions

-- Scoring 
function l.score(t, goal, LIKE, HATE,         like, hate,tiny)
    like, hate, tiny = 0, 0, 1E-30
    for klass, n in pairs(t) do
        if klass == goal then like=like + n else hate=hate + n end end
    like, hate = like / (LIKE + tiny), hate / (HATE + tiny)
    if hate > like then return 0 else return like ^ the.Support / (like + hate) end end
 
-- ### Linting
function l.rogues()
  for k,v in pairs(_ENV) do if not b4[k] then print("E:",k,type(k)) end end end

-- ### Numbers
function l.rnd(n, ndecs)
  if type(n) ~= "number" then return n end
  if math.floor(n) == n  then return n end
  local mult = 10^(ndecs or 2)
  return math.floor(n * mult + 0.5) / mult end

-- ### Lists

-- subsets
function l.powerset(s,       t)
  t = {{}}
  for i = 1, #s do
    for j = 1, #t do
      t[#t+1] = {s[i],table.unpack(t[j])} end end
   return t end


-- Return `t` in an array with indexes 1,2.3...
function l.asList(t,    u)
  u={}; for _,v in pairs(t) do u[1+#u] =v end; return u end 

-- Effort required to recreate the signal in `t`.
function l.entropy(t, e, n)
  n=0; for _,v in pairs(t) do n = n+v end
  e=0; for _,v in pairs(t) do e = e-v/n * math.log(v/n,2) end; 
  return e,n end

-- Return any item.
function l.any(t) return t[math.random(#t)] end

-- Return any `n` items (there may be repeats).
function l.many(t,  n,     u)
  n = n or #t
  u={}; for _ = 1,n do u[1+#u] = l.any(t) end; return u end
  
-- Sorted keys
function l.keys(t,    u)
  u={}; for k,_ in pairs(t) do u[1+#u]=k end; table.sort(u); return u end

-- Deep copy
function l.copy(t,    u)
  if type(t) ~= "table" then return t end
  u = setmetatable({}, getmetatable(t))
  for k,v in pairs(t) do u[l.copy(k)] = l.copy(v) end
  return u end 

-- Return a new table, with old items sorted randomly.
function l.shuffle(t,    u,j)
  u={}; for _,x in pairs(t) do u[1+#u]=x; end;
  for i = #u,2,-1 do j=math.random(i); u[i],u[j] = u[j],u[i] end
  return u end

-- Return `t` skipping `go` to `stop` in steps of `inc`.
function l.slice(t, go, stop, inc,    u) 
  if go   and go   < 0 then go=#t+go     end
  if stop and stop < 0 then stop=#t+stop end
  u={}
  for j=(go or 1)//1,(stop or #t)//1,(inc or 1)//1 do u[1+#u]=t[j] end
  return u end

-- Schwartzian transform:  decorate, sort, undecorate
function l.keysort(t,fun,      u,v)
  u={}; for _,x in pairs(t) do u[1+#u]={x=x, y=fun(x)} end -- decorate
  table.sort(u, function(a,b) return a.y < b.y end) -- sort
  v={}; for _,xy in pairs(u) do v[1+#v] = xy.x end -- undecoreate
  return v end

-- ### String to Things

-- Coerce string to int, float, nil, true, false, or (it all else fails), a strong.
function l.coerce(s1,    fun) 
  function fun(s2)
    if s2=="nil" then return nil else return s2=="true" or (s2~="false" and s2) end end
  return math.tointeger(s1) or tonumber(s1) or fun(s1:match'^%s*(.*%S)') end

-- Parse help string to infer the settings.
function l.settings(s,    t,pat)
  t,pat = {}, "[-][-]([%S]+)[^=]+= ([%S]+)"
  for k, s1 in s:gmatch(pat) do t[k] = l.coerce(s1) end
  t._help = s
  return t end

-- Return a list of comma seperated values (coerced to things)
function l.cells(s,   t)
  t={}; for s1 in s:gmatch("([^,]+)") do t[1+#t]=l.coerce(s1) end; return t end

-- Return rows of a csv file.
function l.csv(src,    i)
  i,src = 0,src=="-" and io.stdin or io.input(src)
  return function(      s)
    s=io.read()
    if s then i=i+1; return i,l.cells(s) else io.close(src) end end end

-- Update a table of settings using command-line settings.
function l.cli(t)
  for k, v in pairs(t) do
    v = tostring(v)
    for argv,s in pairs(arg) do
      if s=="-"..(k:sub(1,1)) or s=="--"..k then
        v = v=="true" and "false" or v=="false" and "true" or arg[argv + 1]
        t[k] = l.coerce(v) end end end
  if t.help then os.exit(print("\n"..t._help)) end
  return t end

-- ### Things to Strings

-- Emulate sprintf
l.fmt = string.format

-- Print a string of a nested structure.
function l.oo(x) print(l.o(x)); return x end

-- Rerun a string for a nested structure.
function l.o(t,  n,      u)
  if type(t) == "number" then return tostring(l.rnd(t, n)) end
  if type(t) ~= "table"  then return tostring(t) end
  u={}
  for _,k in pairs(l.keys(t)) do
    if tostring(k):sub(1,1) ~= "_" then
      u[1+#u]= #t>0 and l.o(t[k],n) or l.fmt("%s: %s", l.o(k,n), l.o(t[k],n)) end end
  return "{" .. table.concat(u, ", ") .. "}" end

-- ----------------------------------------------------------------------------
-- ## Examples                                                           

-- ### Examples support code

-- Where to store examples
local eg={}

local function run(k, oops, b4)
  if not eg[k] then return print("-- ERROR: unknown start up action ["..k.."]") end
  b4 = l.copy(the) -- set up
  math.randomseed(the.seed) -- set up
  oops = eg[k]()==false
  io.stderr:write(l.fmt("# %s %s\n",oops and "❌ FAIL" or "✅ PASS",k))
  for k,v in pairs(b4) do the[k]=v end -- tear down
  return oops end

-- Run all examples
function eg.all(     bad)
  bad=0
  for _,k in pairs(l.keys(eg)) do 
    if k ~= "all" then 
      if run(k) then bad=bad+1 end end end
  io.stderr:write(l.fmt("# %s %s fail(s)\n",bad>0 and "❌ FAIL" or "✅ PASS",bad))
  os.exit(bad) end

-- List all example names
function eg.egs()
  for _,k in pairs(l.keys(eg)) do print(l.fmt("lua gate.lua -t %s",k)) end end

-- ### The actual examples
function eg.oo()
  return l.o{a=1,b=2,c=3,d={e=3,f=4}}  == "{a: 1, b: 2, c: 3, d: {e: 3, f: 4}}" end

function eg.the() l.oo(the); return the.help ~= nil and the.seed and the.m and the.k  end 

function eg.help() print("\n"..the._help) end

function eg.sym(      s,mode,e)
  s = SYM.new()
  for _, x in pairs{1,1,1,1,2,2,3} do s:add(x) end
  mode, e = s:mid(), s:div()
  print(mode, e)
  return 1.37 < e and e < 1.38 and mode == 1 end

local function norm(mu,sd,    R)
  R=math.random
  return (mu or 0) + (sd or 1) * math.sqrt(-2 * math.log(R()))
                               * math.cos(2 * math.pi * R()) end

function eg.num(      e,mu,sd)
  e = NUM.new()
  for _ = 1,1000 do e:add(norm(10, 2)) end
  mu, sd = e:mid(), e:div()
  print(l.rnd(mu,3), l.rnd(sd,3))
  return 10 < mu and mu < 10.1 and 2 < sd and sd < 2.05 end

function eg.csv(      n)
  n=0
  for i,t in l.csv(the.file) do
    if i%100 == 0 then  n = n + #t; print(i, l.o(t)) end end 
  return n == 63 end

function eg.data(     d,n)
  n=0
  d = DATA.new(the.file)
  for i, row in pairs(d.rows) do
    if i % 100 ==0 then n = n + #row.cells; l.oo(row.cells) end end
  l.oo(d.cols.x[1].cells)
  return n == 63 end

function eg.stats()
  return  l.o(DATA.new("../data/auto93.csv"):stats())  ==
             "{.N: 398, Acc+: 15.57, Lbs-: 2970.42, Mpg+: 23.84}" end

function eg.sorted(   d)
  d = DATA.new("../data/auto93.csv")
  table.sort(d.rows, function(a,b) return a:d2h(d) < b:d2h(d) end)
  print("",l.o(d.cols.names))
  for i, row in pairs(d.rows) do
    if i < 5  or i> #d.rows - 5 then print(i, l.o(row)) end end end 

function eg.dist(   d,rows,r1)
  d  = DATA.new("../data/auto93.csv")
  r1   = d.rows[1]
  rows = r1:neighbors(d)
  for i, row in pairs(rows) do
    if i%30 ==0 then print(l.o(row.cells), l.rnd(row:dist(r1,d))) end end end

function eg.far(      d,rows,a,b,C)
  d  = DATA.new("../data/auto93.csv")
  a,b,C = d:farapart(d.rows)
  print(l.o(a),l.o(b),C) end

function eg.half(      d,o)
  d     = DATA.new("../data/auto93.csv")
  local lefts, rights, left, right, C,cut = d:half(d.rows)
  o = l.o
  print(o(#lefts),o(#rights),o(left.cells),o(right.cells),o(C),o(cut)) end

function eg.tree(t, evals)
    t, evals = DATA.new("../data/auto93.csv"):tree(true)
    t:show()
    print(evals) end
 
function eg.branch(t, d, best, rest, evals)
    d = DATA.new("../data/auto93.csv")
    best, rest, evals = d:branch()
    print(l.o(best:mid().cells), l.o(rest:mid().cells))
    print(evals) end

function eg.doubletap(t, best1, best2, evals2, evals1, _,d,rest)
  d = DATA.new("../data/auto93.csv")
  best1, rest, evals1 = d:branch(32)
  best2, _,    evals2 = best1:branch(4)
  print(l.o(best2:mid().cells), l.o(rest:mid().cells)) 
  print(evals1+evals2) end 

function eg.bins(t, d, best, rest, score,t,HATE,LIKE,max)
  d = DATA.new("../data/auto93.csv")
  best, rest = d:branch()
  LIKE = best.rows
  HATE = l.slice(l.shuffle(rest.rows), 1, 3 * #LIKE)
  function score(range) return range:score("LIKE", #LIKE, #HATE) end
  t={}
  for _,col in pairs(d.cols.x) do
    print ""
    for _, range in pairs(_ranges1(col, { LIKE = LIKE, HATE = HATE })) do
      l.oo(range)
      t[1+#t]=range end end 
  table.sort(t, function(a, b) return score(a) > score(b) end)
  max = score(t[1])
  print "\n#scores:\n"
  for _, v in pairs(l.slice(t, 1, the.Beam)) do
    if score(v) > max * .1 then
      print(l.rnd(score(v)), l.o(v)) end end
  l.oo{LIKE=#LIKE, HATE=#HATE} end
  
function eg.rules(     d,rowss,  best, rest,LIKE,HATE)
  d = DATA.new("../data/auto93.csv")
  best, rest = d:branch()
  LIKE = best.rows
  HATE = l.slice(l.shuffle(rest.rows), 1, 3 * #LIKE)
  rowss = {LIKE=LIKE,HATE=HATE}
  RULES.new(_ranges(d.cols.x, rowss),"LIKE",rowss)
  end
-- ----------------------------------------------------------------------------
-- ## Start-up

the = l.settings(help)
if   not pcall(debug.getlocal, 4, 1) -- if __name__ == "__main__":
then run(l.cli(the).todo) end
l.rogues()
return {the=the, COLS=COLS, DATA=DATA, NODE=NODE, NUM=NUM, ROW=ROW, SYM=SYM}