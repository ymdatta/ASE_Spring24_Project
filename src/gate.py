"""
gate: guess, assess, try, expand
(c) 2023, Tim Menzies, BSD-2
Learn a little, guess a lot, try the strangest guess, repeat

USAGE:
  python3 gate.lua [OPTIONS] 

OPTIONS:
  -c --cohen  small effect size               = .35
  -f --file   csv data file name              = '../data/diabetes.csv'
  -h --help   show help                       = False
  -k --k      low class frequency kludge      = 1
  -m --m      low attribute frequency kludge  = 2
  -s --seed   random number seed              = 31210
  -t --todo   start up action                 = 'help' """

import re,sys,ast
from collections import Counter
from fileinput import FileInput as file_or_stdin

def o(d,s=""): 
 return s+"{"+ (", ".join([f":{k} {v}" for k,v in d.items() if k[0]!="_"]))+"}" 

class box(dict):
  __getattr__ = dict.get
  __setattr__ = dict.__setitem__
  __repr__    = lambda x:o(x, x.__class__.__name__)

def coerce(s):
  try: return ast.literal_eval(s)
  except Exception:creturn s

the = box(**{m[1]:coerce(m[2]) for m in re.finditer(r"--(\w+)[^=]*=\s*(\S+)",__doc__)})

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

def ent(d):
  e,n = 0,0
  for k in d: n += d[k]
  for k in d: e += d[k]/n * math.log( d[k]/n, 2)
  return -e

def  DATA(lsts):
  def goalp(s): return s[-1] in "+-!"
  def want(s):  return 1 if s[-1] == "+" else 0
  def nump(s):  return s[0].isupper()
  def d2h(lst)
    return (sum(abs(w - norm(all[c],lst[c]))**2 for c,w in ys.items()) / len(ys))**(1/2)
  names,*rows = lsts
  ys   = {c:want(s) for c,s in enumerate(names) if goalp(s)}
  nums = [c         for c,s in enumerate(names) if nump(s)]
  all  = [[y for y in x if y !="?"] for x in zip(*rows)]
  all  = [NUM(a) if c in nums else Counter(a) for c,a in enumerate(all)]
  data =  box(rows=rows, cols=box(names=names, ys=ys, nums=nums, all=all))
  rows.sort(key=d2h)
  return data

def NUM(a):
  a.sort()
  p = len(a)/10
  return box(n=len(a),lo=a[0], hi=a[-1], mid=a[int(p*5)], sd=(a[int(9*p)]-a[int(p)])/2.56)

def norm(col,x):
  return x in x=="?" else (x - col.lo)/(col.hi - col.lo + 1E-30) 

#---------------------------------------------------------------------------
the = cli(the)
DATA([r for r in csv(the.file)])
