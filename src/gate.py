"""
gate: guess, assess, try, expand
(c) 2023, Tim Menzies, BSD-2
Learn a little, guess a lot, try the strangest guess, repeat

USAGE:
  python3 gate.lua [OPTIONS] 

OPTIONS:
  -c --cohen  small effect size               = .35
  -f --file   csv data file name              = '../data/auto93.csv'
  -h --help   show help                       = False
  -k --k      low class frequency kludge      = 1
  -m --m      low attribute frequency kludge  = 2
  -s --seed   random number seed              = 31210
  -t --todo   start up action                 = 'help' """

import re,sys,ast,math
from collections import Counter
from fileinput import FileInput as file_or_stdin

#----------------------------------------------------------------------------------------
def  DATA(lsts):
  def goalp(s):  return s[-1] in "+-!"
  def heaven(s): return 0 if s[-1] == "-" else 1
  def nump(s):   return s[0].isupper()  
  def d2h(lst):
    return (sum(abs(w - norm(all[c],lst[c]))**2 for c,w in ys.items()) / len(ys))**.5
  #-----------------
  names,*rows = lsts
  ys   = {c:heaven(s) for c,s in enumerate(names) if goalp(s)}
  nums = [c           for c,s in enumerate(names) if nump(s)]
  all  = [[y for y in x if y !="?"] for x in zip(*rows)]
  all  = [(NUM(a) if c in nums else Counter(a)) for c,a in enumerate(all)]
  return box(rows = sorted(rows, key=d2h), 
             cols = box(names=names, ys=ys, nums=nums, all=all))

def clone(data,rows=[]):
  return DATA( [data.cols.names] +  rows )  

def NUM(a):
  n,sd,sum, lo,hi = 0,0,0, sys.maxsize, -sys.maxsize
  for x in a: n  += 1; sum += x; hi=max(x,hi); lo=min(x,lo)
  for x in a: sd += (x-sum/n)**2 
  return box(n=n,lo=lo, hi=hi, mu=sum/n, sd= (sd/(n-1))**.5)

def like(data,row,all,nh,m=1,k=2):
  def num(col,x):
    v = col.sd**2 + 10**-64
    nom = math.e**(-1*(x - col.mu)**2/(2*v)) + 10**-64
    denom = (2*math.pi*v)**.5
    return min(1, nom/(denom + 10**-64))
  def sym(col,x):
    return (col.get(x, 0) + m*prior) / (sum(col.values()) + m)
  #------------------------------------------
  prior = (len(data.rows) + k) / (all + k*nh)
  out   = math.log(prior)
  for c,x in enumerate(row):
    if x != "?" and c not in data.cols.ys:
      col  = data.cols.all[c]
      inc  = (sym if isinstance(col, Counter) else num)(col, x)
      print(inc)
      out += math.log(inc)
  return out

#----------------------------------------------------------------------------------------
def o(d,s=""): 
 return s+"{"+ (", ".join([f":{k} {v}" for k,v in d.items() if k[0]!="_"]))+"}" 

class box(dict):
  __getattr__ = dict.get
  __setattr__ = dict.__setitem__
  __repr__    = lambda x : o(x, x.__class__.__name__)

def coerce(s):
  try: return ast.literal_eval(s)
  except Exception: return s

def norm(col,x):
  return x if x=="?" else (x - col.lo)/(col.hi - col.lo + 1E-30) 

def cli(d):
  for k,v in d.items(): 
    v = str(v)
    for c,arg in enumerate(sys.argv):
      if arg in ["-h", "--help"]: sys.exit(print(__doc__))
      after = "" if c >= len(sys.argv) - 1 else sys.argv[c+1]
      if arg in ["-"+k[0], "--"+k]: 
        v = "false" if v=="true" else ("true" if v=="false" else after)
        d[k] = coerce(v) 
  return d

def csv(file=None):
  with file_or_stdin(file) as src:
    for line in src:
      line = re.sub(r'([\n\t\r"\’ ]|#.*)', '', line)
      if line: yield [coerce(s.strip()) for s in line.split(",")]

#----------------------------------------------------------------------------------------
class Eg:
  def all():
    sys.exit(sum((f() or 0) for f in [Eg.data, Eg.likes]))
    
  def data():
    for i,row in enumerate(DATA([r for r in csv(the.file)]).rows):
       if i % 30 == 0 : print(i,row)

  def likes():
    d = DATA([r for r in csv(the.file)])
    for row in d.rows: like(d, row, 1000, 2, m=the.m, k=the.k)

#----------------------------------------------------------------------------------------
the = box(**{m[1]:coerce(m[2]) for m in re.finditer(r"--(\w+)[^=]*=\s*(\S+)",__doc__)})
the = cli(the)
getattr(Eg, the.todo)()