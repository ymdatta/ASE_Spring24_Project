-- vim: set et sts=2 sw=2 ts=2 
local smo = require"smo"
local l = require"smolib"
local o,oo = l.o,l.oo
local the,COLS,DATA,NUM,SYM = smo.the,smo.COLS,smo.DATA,smo.NUM,smo.SYM

local eg={}

function eg.oo()   oo{a=1,b=2,c=3,d={e=3,f=4}} end
function eg.the() oo(the) end 
function eg.help() print(the._help) end

function eg.sym(      s,mode,e)
  s = SYM()
  for _, x in pairs{1,1,1,1,2,2,3} do s:add(x) end
  mode, e = s:mid(), s:div()
  print(mode, e)
  return 1.37 < e and e < 1.38 and mode == 1 end

local function norm(mu,sd,    R)
  R=math.random
  return (mu or 0) + (sd or 1) * math.sqrt(-2 * math.log(R()))
                               * math.cos(2 * math.pi * R()) end

function eg.num(      e,mu,sd)
  e = NUM()
  for _ = 1,1000 do e:add(norm(10, 2)) end
  mu, sd = e:mid(), e:div()
  print(l.rnd(mu,3), l.rnd(sd,3))
  return 9.9 < mu and mu < 10 and 1.95 < sd and sd < 2 end

function eg.csv()
  for i,t in l.csv(the.file) do
    if i%100 == 0 then print(i, o(t)) end end end

function eg.data(     d)
  d = DATA(the.file)
  for i, t in pairs(d.rows) do
    if i % 100 ==0 then oo(t) end end 
  oo(d.cols.x[1]) end

function eg.bayes(     k,d,datas,acc)
  for k=0,3 do
    the.k = k
    for m=0,3 do
      the.m = m
      d = DATA(the.file)
      acc,datas = 0,{}
      for _,row in pairs(d.rows) do
        kl = row[d.cols.klass.at]
        if kl == smo.likes(row, datas, #d.rows, 2) then acc=acc+1 end
        datas[kl] = datas[kl] or DATA{d.cols.names}
        datas[kl]:add(row) end
      print(l.fmt("%5.2f\t%s\t%s",acc/#d.rows,k,m)) end end end

l.cli(the)
math.randomseed(the.seed)
print(eg[the.todo]()==false and "❌ FAIL" or "✅ PASS")
l.rogues()
