-- ## Search control

-- Assumes access to `b,r`; i.e. the probability of belonging to best or rest.
local acquire={}

-- Go where you have not gone before
function acquire.xplore(b,r) return 1/(b+r + 1E-30) end

-- Only go where you have got beore
function acquire.xploit(b,r) return b+r end

-- Go to where its best
function acquire.plan(b,r) return b end

-- Go to where its worst.
function acquire.watch(b,r) return r end

-- Go to where we are most confused.
function acquire.stress(b,r)  
  return b>r and (b+r)/(1E-30 + math.abs(b-r)) or -300 end



function eg.discretize(           max,num1,sym1,mu,sd,t,u,n,y,v,i)
  t, u, v, num1, sym1 = {}, {},{}, NUM(), SYM()
  max=1000
  for _ = 1, max do t[1+#t]= col(num1, norm(10,2)) end
  table.sort(t)
  for _,x in pairs(t) do
    y = discretize(num1, x)
    col(sym1,y)
    u[y] = y
    v[y] =x  end
  i=0
  for _, y in pairs(sort(u)) do
    n = sym1.has[y]
    i=i+1
    print(fmt("%2s %6s%%   %4.1f  %s",y, n/10, v[y], ('*'):rep(n//10))) end end

 

-- Update nested frequency table.
function inc3(c,x,y,z,    a,b)
  b = c[x] if b==nil then b={} c[x] = b end
  a = b[y] if a==nil then a={} b[y] = a end
  a[z] = (a[z] or 0) + 1 end
  
-- Lookup nested frequency table.
function has3(c,x,y,z,     a,b)
  b = c[x]
  if b ~= nil then
    a = b[y]
    if a ~= nil then return a[z] end end end

function eg.inc3(f)
  f={}
  for r = 1, 4 do
    for _,i in pairs{"a","b","c","d"}   do
      for _,j in pairs{"a","b","c","d"}   do
        for _,k in pairs{"a","b","c","d"}   do
           inc3(f, i, j, k) end end end end
  oo(f); print(f.a.c.b) end 
-- Map a column value into a small number of values. Used `m` for the
-- middle value and  `l,j,etc` for values under middle and 
-- `n,o,p,etc` for values above middle.
function discretize(col1,x,     y)
  if col1.isSym or x == "?" then return x end
  return string.char(109+((the.bins) * (x - col1.mu) / col1.sd / 6 + .5) // 1) end

-- Descrretize row values and, as a side effect, update  a `f` frequency table
-- `f[klass][{col.at, val}]=count`. 
function discretizes(data1, row1,      x,y,d)
  for _, col1 in pairs(data1.cols.all) do
    x = row1.cells[col1.at]
    y = row1.cells[data1.cols.klass.at]
    d = discretize(col1, x)
    row1.cooked[col1.at] = d
    if d ~= "?" then 
      inc3(data1.f, y, col1.at, d) end end end


function eg.f(     d)
  d = DATA('../data/diabetes.csv')
  oo(d.f) end

  function eg.contrast(d, yes, no, R, B, r, b, w)
the.bins = 5
d = DATA('../data/diabetes.csv')
yes = "pos"; B = d.cols.klass.has[yes] + 1E-30
no  = "neg"; R = d.cols.klass.has[no]  + 1E-30
for col, valcount in pairs(d.f[yes]) do
  for val, b in pairs(valcount) do
    r = has3(d.f, no, col, val) or 0
    b, r = b / B, r / R
    if b > r then
      print(fmt("%5.3f  %.3f  %.3f %3s %3s",b^2/r, b,r,
                d.cols.names[col],val)) end end end end