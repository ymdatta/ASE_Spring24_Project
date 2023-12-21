local lib = require"Lib"
local l   = require"mylo"
local eg  = {}

function eg.sym(     sym1,md,div)
  sym1 = l.SYM()
  for _,x in pairs{1,1,1,1,2,2,3} do l.col(sym1,x)  end
  md,div = l.mid(sym1), l.div(sym1)
  print(md,div)
  return 1.37 < div and div <1.38 and  md==1  end

function eg.num(     num1,md,div)
  num1 = l.NUM() 
  for i=1,100 do l.col(num1, i) end
  md,div = l.mid(num1), l.div(num1)
  print(md,div)
  return 50 == md and md < 51 and 31 < div and div < 32 end

function eg.col(      a,b)
  a = l.COL("Age")
  b = l.COL("job")
  return not a.isSym and b.isSym end

function eg.cols(      cols1,a)
  cols1 = l.COLS{"Age","job","Salary+"}
  a=cols1.all
  return cols1.x and cols1.y and cols1.klass and
         not cols1.x[1].isSym and
         #a==3 and a[2].isSym and
         a[3].heaven==1 end

function eg.csv(       n)
  n=0
  for t in lib.csv("../data/auto93.csv") do n = n + #t end
  return n == 3192 end

function eg.stats(   s)
  s = l.stats(l.DATA("../data/diabetes.csv"))
  return s.Plas == 117 end

lib.run(l.the,eg)
