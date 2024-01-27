"""
gate: Guess, Assess, Try the strangest thing, Expand, repeat     
(c) 2023, Tim Menzies, <timm@ieee.org>, BSD-2  
  
USAGE:    
python3 gate.py [OPTIONS]   
  
OPTIONS:  

     -b --budget0     initial evals                   = 4  
     -B --Budget      subsequent evals                = 6   
     -c --cohen       small effect size               = .35  
     -c --confidence  statistical confidence          =.05
     -e --effectSize  non-parametric small delta      = 0.2385
     -E --Experiments number of Bootstraps            = 512
     -f --file        csv data file name              = '../data/auto93.csv'  
     -k --k      low class frequency kludge      = 1  
     -m --m           low attribute frequency kludge  = 2  
     -s --seed        random number seed              = 31210   
     -t --todo        start up action                 = 'help'   
     -T --Top        best section                    = .5   
"""

import re,sys,ast,math,random
from collections import Counter
from fileinput import FileInput as file_or_stdin

#----------------------------------------------------------------------------------------
def isGoal(s):  return s[-1] in "+-!"
def isHeaven(s): return 0 if s[-1] == "-" else 1
def isNum(s):   return s[0].isupper() 

#----------------------------------------------------------------------------------------
class struct:
  "simple struct-like class, with built-in pretty-print"
  def __init__(self,**d) : self.__dict__.update(d)
  __repr__ = lambda self: o(self.__dict__, self.__class__.__name__)

#----------------------------------------------------------------------------------------
class NUM(struct):
  "stores mean, standard deviation, low, high, of a list of numbers"
  def __init__(self,lst,txt="",rank=0):
    self.has = sorted(lst)
    self.txt, self.rank = txt,0
    self.n, self.sd, self.mu, self.lo, self.hi = len(lst),0,0, sys.maxsize, -sys.maxsize
    if self.n != 0: 
      tmp, self.mu  = 0, sum(lst) / self.n
      for x in lst: 
        tmp += (x-self.mu)**2; self.hi=max(x,self.hi); self.lo=min(x,self.lo)
      self.sd = (tmp/(self.n - 1+1E-30))**.5 

  def mid(i): return self.has[len(self.has)//2]

def sk(nums):
  "sort nums on median. give adjacent nums the same rank if they are statistically the same"
  def sk1(nums, rank)
    all = lambda lst: [x of num in lst for x in num.has]
    b4, max, cut = all(nums), -1, None
    for i in range(1,len(nums) -1): 
      lhs = all(nums[:i])
      rhs = all(nums[i:])
      tmp = (lhs.n*abs(lhs.mid() - b4.mid())**2 + rhs.n*abs(rhs.mid() - b4.mid())**2)/b4.n
      if tmp > max: max,cut = tmp,i
    if cut and different( all(nums[:cut]), all(nums[cut:])):
      rank = sk1(nums[:cut], rank) + 1
      rank = sk1(nums[cut:], rank)
    else:
      for num in nums: num.rank = rank
    return rank
  #------------
  return sk1(sorted(nums, key=lambda num:num.mid()), 0)

#----------------------------------------------------------------------------------------
class COLS(struct):
  "stores NUMs and Counters generated from list of column names"
  def __init__(self,names,rows):
    self.names = names
    self.ys    = {c:isHeaven(s) for c,s in enumerate(self.names) if isGoal(s)}
    self.nums  = [c           for c,s in enumerate(self.names) if isNum(s)]
    tmp        = [[y for y in x if y !="?"] for x in zip(*rows)]
    self.all   = [(NUM if c in self.nums else Counter)(a) for c,a in enumerate(tmp)]

#----------------------------------------------------------------------------------------
class DATA(struct):
  "storage and processing or rows and columns"
  def __init__(self, lsts, order=False):
    names,*rows = list(lsts)
    self.cols = COLS(names,rows)
    self.rows = sorted(rows, key=lambda row:self.d2h(row)) if order else rows

  def mid(self): 
    "returns centroid"
    return [(col.mu if c in self.cols.nums else max(col,key=col.get)) 
            for c,col in enumerate(self.cols.all)] 
  
  def small(self): 
    "returns small delta from centroid"
    return [(col.sd*the.cohen if c in self.cols.nums else 0)
            for c,col in enumerate(self.cols.all)]

  def clone(self, rows=[], order=False):
    "return a new DATA with a similar structure to self"
    return DATA([self.cols.names] + rows, order=order)  

  def d2h(self,lst):  
    "Euclidean distance to a mythical best point"
    return (sum(abs(w-norm(self.cols.all[c], lst[c]))**2 
                for c,w in self.cols.ys.items())/len(self.cols.ys))**.5 

  def ycols(self,row): 
    "returns just the y columns"
    return [row[c] for c,_ in self.cols.ys.items()]

  def like(self,row,nall,nh,m=1,k=2):
    "returns how much self likes row"
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
    """evaluate a few, divide them into best and rest, use that
    information to guess the next most informative example to evaluate"""
    done, todo = self.rows[:the.budget0], self.rows[the.budget0:]
    for i in range(the.Budget):
      data1 = self.clone(done, order=True)
      n = int(len(done)**the.Top + .5)
      j = smo1(i+the.budget0,
                  self.clone(data1.rows[:n],order=True), 
                  self.clone(data1.rows[n:]),
                  len(self.rows),
                  todo,
                  fun) 
    done.append(todo.pop(j))

def smo1(i,best,rest,nall,rows,fun):
  """For rows not evaluated, score how likely they belong to best,rest.
  Return the row nearest the border of best,rest"""
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

#----------------------------------------------------------------------------------------
class THE(struct):
  "Builds config from __doc__ string, maybe update it from command line"
  def __init__(self,txt):
    self.help = txt
    d = {m[1]:coerce(m[2]) for m in re.finditer(r"--(\w+)[^=]*=\s*(\S+)",txt)}
    self.__dict__.update(d)
    
  def cli(self):
    "update settings from command line flags"
    for k,v in self.__dict__.items(): 
      v = str(v)
      for c,arg in enumerate(sys.argv):
        after = "" if c >= len(sys.argv) - 1 else sys.argv[c+1]
        if arg in ["-"+k[0], "--"+k]: 
          v = "false" if v=="true" else ("true" if v=="false" else after)
          self.__dict__[k] = coerce(v) 
    if self.__dict__["help"]:  sys.exit(self.help)
          
#----------------------------------------------------------------------------------------
def o(d,s=""): 
  "pretty print for dictionary"
  return s+"{"+(", ".join([f":{k} {v}" for k,v in d.items() if k[0]!="_"]))+"}" 

def coerce(s):
  "turn a string into some typed atom"
  try: return ast.literal_eval(s)
  except Exception: return s

def norm(col,x):
  "convert `x` to the range 0..1"
  return x if x=="?" else (x - col.lo)/(col.hi - col.lo + 1E-30) 

def entropy(d): 
  "return diversity for symbol counts"
  n = sum(d.values()) 
  return -sum(v/n*math.log(v/n,2) for _,v in d.items() if v>0)

def csv(file=None):
  "iterator: returns rows in csv file"
  with file_or_stdin(file) as src:
    for line in src:
      line = re.sub(r'([\n\t\r"\’ ]|#.*)', '', line)
      if line: yield [coerce(s.strip()) for s in line.split(",")]

isa=isinstance

def rnds(x,n=2): 
  "round a thing, or a list to a few decimal places"
  if isa(x,(int,float)):  return x if int(x)==x else round(x,n)
  if isa(x,(list,tuple)): return [rnds(y,n) for y in x]
  return x

def different(x,y):
  "non-parametric effect size and significance test"
  return cliffsDelta(x,y) and bootstrap(x,y)

def cliffsDelta(x,y,effectSize=.2):
  """non-parametric effect size. threshold is border between small=.11 and medium=.28 
     from Table1 of  https://doi.org/10.3102/10769986025002101"""
  if len(x) > 10*len(y) : return cliffsDelta(random.choices(x,10*len(y)),y)
  if len(y) > 10*len(x) : return cliffsDelta(x, random.choices(y,10*len(x)))
  n,lt,gt = 0,0,0
  for x1 in x:
    for y1 in y:
      n = n + 1
      if x1 > y1: gt = gt + 1
      if x1 < y1: lt = lt + 1
  return abs(lt - gt)/n > effectSize # true if different

def bootstrap(y0,z0,confidence=.05,Experiments=512,):
  """non-parametric significance test From Introduction to Bootstrap, 
     Efron and Tibshirani, 1993, chapter 20. https://doi.org/10.1201/9780429246593"""
  obs = lambda x,y: abs(x.mu-y.mu) / ((x.sd**2/x.n + y.ad**2/y.n)**.5 + 1E-30)
  x, y, z = NUM(y0+z0), NUM(y0), NUM(z0)
  d = obs(y,z)
  yhat = [y1 - y.mu + x.mu for y1 in y0]
  zhat = [z1 - z.mu + x.mu for z1 in z0]
  n      = 0
  for _ in range(Experiments):
    ynum = NUM(random.choices(yhat,k=len(yhat)))
    znum = NUM(random.choices(zhat,k=len(zhat)))
    if obs(ynum, znum) > d:
      n += 1
  return n / Experiments < confidence # true if different

#----------------------------------------------------------------------------------------
class Eg:
  "place to store demos"
  _all = locals()
  def all():
    "run all examples, return to operating system count of failures"
    errors = [f() for s,f in Eg._all.items() if s[0] !="_" and s !="all"]
    sys.exit(sum(0 if x==None else x for x in errors))
    
  def help(): 
    "print help"
    print(__doc__);  

  def nums(): 
    "show NUMS working"
    print(NUM([x**.5 for x in range(100)]))
  
  def data():
    "read rows from csv, sorted by distance to heaven"
    for i,row in enumerate(DATA(csv(the.file),order=True).rows):
       if i % 30 == 0 : print(i,row)

  def likes():
    "reports the likelihood of rows"
    d = DATA( csv(the.file),order=True)
    for i,row in enumerate(d.rows): 
      if i % 25 == 0: 
          print(i, rnds(d.d2h(row)),
                rnds(d.like(row, 1000, 2, m=the.m, k=the.k)))

  def smos():
    "example of smos"
    print(the.seed)
    d=DATA(csv(the.file),order=False) 
    print("names,",d.ycols(d.cols.names))
    print("base,", rnds(d.ycols(d.mid()),2)); print("#")
    random.shuffle(d.rows) 
    d.smo(lambda i,top: print(f"step{i}, ",rnds(d.ycols(top),2)))
    print("#\nbest,",rnds(d.ycols( d.clone(d.rows,order=True).rows[0]),2))

  def smos20():
    print(the.seed)
    d=DATA(csv(the.file),order=False) 
    names = d.ycols(d.cols.names)
    print("names,",names)
    print("mid,", rnds(d.ycols(d.mid()),2));  
    small= d.ycols(d.small())
    print("small,", rnds(small,2)); print("#")
    random.shuffle(d.rows) 
    def delta(x): return x
    def deltas(ys): return [delta(y,small,name) for y,small,name in zip(ys,small,names)]
    d.smo(lambda i,top: print(f"step{i}, ",rnds(deltas(d.ycols(top)),2)))
    print("#\nbest,",rnds(d.ycols( d.clone(d.rows,order=True).rows[0]),2))

#----------------------------------------------------------------------------------------
the = THE(__doc__)
the.cli()
random.seed(the.seed)
getattr(Eg, the.todo, Eg.help)()
