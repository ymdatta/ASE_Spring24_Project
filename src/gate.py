"""
gate: guess, assess, try, expand
(c) 2023, Tim Menzies, BSD-2
Learn a little, guess a lot, try the strangest guess, repeat

USAGE:
  python3 gate.lua [OPTIONS] 

OPTIONS:
  -b --budget0 initial evals                   = 4
  -B --Budget  subsequent evals                = 6 
  -c --cohen   small effect size               = .35
  -f --file    csv data file name              = '../data/auto93.csv'
  -h --help    show help                       = False
  -k --k       low class frequency kludge      = 1
  -m --m       low attribute frequency kludge  = 2
  -s --seed    random number seed              = 31210 
  -t --todo    start up action                 = 'help' 
  -T --Top     best section                    = .5 """

import re,sys,ast,math,random
from collections import Counter
from fileinput import FileInput as file_or_stdin

#----------------------------------------------------------------------------------------
def goalp(s):  return s[-1] in "+-!"
def heaven(s): return 0 if s[-1] == "-" else 1
def nump(s):   return s[0].isupper() 

#----------------------------------------------------------------------------------------
class struct:
  def __init__(self,**d) : self.__dict__.update(d)
  __repr__ = lambda self: o(self.__dict__, self.__class__.__name__)

#----------------------------------------------------------------------------------------
class NUM(struct):
  def __init__(self,lst):
    self.n, self.sd, self.mu, self.lo, self.hi = len(lst),0,0, sys.maxsize, -sys.maxsize
    if self.n != 0: 
      tmp, self.mu  = 0, sum(lst) / self.n
      for x in lst: 
        tmp += (x-self.mu)**2; self.hi=max(x,self.hi); self.lo=min(x,self.lo)
      self.sd = (tmp/(self.n - 1+1E-30))**.5 

#----------------------------------------------------------------------------------------
class COLS(struct):
  def __init__(self,names,rows):
    self.names = names
    self.ys    = {c:heaven(s) for c,s in enumerate(self.names) if goalp(s)}
    self.nums  = [c           for c,s in enumerate(self.names) if nump(s)]
    tmp        = [[y for y in x if y !="?"] for x in zip(*rows)]
    self.all   = [(NUM if c in self.nums else Counter)(a) for c,a in enumerate(tmp)]

#----------------------------------------------------------------------------------------
class DATA(struct):
  def __init__(self, lsts, order=False):
    names,*rows = list(lsts)
    self.cols = COLS(names,rows)
    self.rows = sorted(rows, key=lambda row: d2h(row,self.cols)) if order else rows

  def clone(self, rows=[], order=False):
    return DATA([self.cols.names] + rows, order=order)  

  def like(self,row,nall,nh,m=1,k=2):
    def num(col,x):
      v = col.sd**2 + 10**-64
      nom = math.e**(-1*(x - col.mu)**2/(2*v)) + 10**-64
      denom = (2*math.pi*v)**.5
      return min(1, nom/(denom + 10**-64))
    def sym(col,x):
      return (col.get(x, 0) + m*prior) / (len(self.rows) + m)
    #------------------------------------------
    prior = (len(self.rows) + k) / (nall + k*nh)
    out   = math.log(prior)
    for c,x in enumerate(row):
      if x != "?" and c not in self.cols.ys:
        col  = self.cols.all[c]
        inc  = (sym if isinstance(col, Counter) else num)(col, x) 
        out += math.log(inc)
    return out

  def smo(self,fun=None):  
    done, todo = self.rows[:the.budget0], self.rows[the.budget0:]
    for i in range(the.Budget):
      data1 = self.clone(done, order=True)
      n = int(len(done)**the.Top + .5)
      j = what2do(i+the.budget0,
                  self.clone(data1.rows[:n],order=True), 
                  self.clone(data1.rows[n:]),
                  len(self.rows),
                  todo,
                  fun) 
    done.append(todo.pop(j))

def what2do(i,best,rest,nall,rows,fun):
  todo,max,selected = 0,-1E300,[]
  for k,row in enumerate(rows):
    b = best.like(row,nall,2,the.m,the.k)
    r = rest.like(row,nall,2,the.m,the.k) 
    if b>r: selected.append(row)
    #tmp = abs(b+r) / abs(b-r + 1E-300)
    tmp = b - r #abs(b+r) / abs(b-r + 1E-300)
    if tmp > max: todo,max = k,tmp  
  if fun: fun(i,best.rows[0])
  return todo

def d2h(lst,Cs): 
  return (sum(abs(w-norm(Cs.all[c],lst[c]))**2 for c,w in Cs.ys.items())/len(Cs.ys))**.5

def centroid(data): 
  Cs = data.cols
  return [(C.mu if c in Cs.nums else max(C,key=C.get)) for c,C in enumerate(Cs.all)]

def ycols(data,row): 
  return [row[c] for c,_ in data.cols.ys.items()]

#----------------------------------------------------------------------------------------
class THE(struct):
  def __init__(self,txt):
    self.help = txt
    d = {m[1]:coerce(m[2]) for m in re.finditer(r"--(\w+)[^=]*=\s*(\S+)",txt)}
    self.__dict__.update(d)
  def cli(self):
    for k,v in self.__dict__.items(): 
      v = str(v)
      for c,arg in enumerate(sys.argv):
        if arg in ["-h", "--help"]: sys.exit(self.help)
        after = "" if c >= len(sys.argv) - 1 else sys.argv[c+1]
        if arg in ["-"+k[0], "--"+k]: 
          v = "false" if v=="true" else ("true" if v=="false" else after)
          self.__dict__[k] = coerce(v) 
          
def o(d,s=""): 
  return s+"{"+(", ".join([f":{k} {v}" for k,v in d.items() if k[0]!="_"]))+"}" 

#----------------------------------------------------------------------------------------
def coerce(s):
  try: return ast.literal_eval(s)
  except Exception: return s

def norm(col,x):
  return x if x=="?" else (x - col.lo)/(col.hi - col.lo + 1E-30) 

def csv(file=None):
  with file_or_stdin(file) as src:
    for line in src:
      line = re.sub(r'([\n\t\r"\’ ]|#.*)', '', line)
      if line: yield [coerce(s.strip()) for s in line.split(",")]

isa=isinstance

def rnds(x,n): 
  if isa(x,(int,float)):  return x if int(x)==x else round(x,n)
  if isa(x,(list,tuple)): return [rnds(y,n) for y in x]
  return x

#----------------------------------------------------------------------------------------
class Eg:
  _all = locals()
  def all():
    errors = [f() for s,f in Eg._all.items() if s[0] !="_" and s !="all"]
    sys.exit(sum(0 if x==None else x for x in errors))
    
  def help(): print(__doc__);  

  def nums(): print(NUM([x**.5 for x in range(100)]))
  
  def data():
    for i,row in enumerate(DATA([r for r in csv(the.file)]).rows):
       if i % 30 == 0 : print(i,row)

  def likes():
    d = DATA( csv(the.file))
    for i,row in enumerate(d.rows): 
      if i % 25 ==0: print(d.like(row, 1000, 2, m=the.m, k=the.k))

  def smos():
    print(the.seed)
    d=DATA(csv(the.file),order=False) 
    print("names,",ycols(d,d.cols.names))
    print("base,", rnds(ycols(d,centroid(d)),2)); print("#")
    random.shuffle(d.rows) 
    d.smo(lambda i,top: print(f"step{i}, ",rnds(ycols(d,top),2)))
    print("#\nbest,",rnds(ycols(d, d.clone(d.rows,order=True).rows[0]),2))

#----------------------------------------------------------------------------------------
the = THE(__doc__)
the.cli()
random.seed(the.seed)
getattr(Eg, the.todo, Eg.help)()