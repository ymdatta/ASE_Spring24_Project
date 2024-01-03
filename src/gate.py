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
import re,sys
from typing import List
from ast import literal_eval as val
from fileinput import FileInput as file_or_stdin

class box(dict): 
  __getattr__=dict.get; __setattr__=dict.__setitem__; __repr__=lambda x:o(x)
#---------------------------------------------------------------------------
class Col:
  def __init__(self,txt=" ",at=0):
    self.txt,self.at,self.goalp = txt,at,(txt[-1] in "!+-")
  def add(self,x):
    if x=="?": self.n += 1; self.add1(x)

class Num(Col):
  def __init__(self,**d):
    Col.__init__(**d)
    self.lo, self.hi = 1E30, -1E30
    self.heaven = 0 if self.txt[-1]=="-" else 1
  def mid(self, h:hold): 
    a= h:has(); return a[length(a)//2]
  def div(self, h:hold): 
    a= h:has(); return (a[length(a)*.9//1] - a[length(a)*.1//1])/2.56
  
class Sym(Col):
  def __init__(self,**d): Col.__init__(**d) 
  def mid(self,d: dict) -> float: return max(d, key=d.get)
  def div(self,d: dict) -> float: return ent(d) 

class Hold:
  def __init__(i): self._has=[];  self.ok=True
  def add(i,x): self._has  +=[x]; self.ok=False
  def has(i,x): 
    if not self.ok: self._has.sort(); 
    self.ok=True
    return self._has
#--------------------------------------------------------------------
class Eg:
  _all = locals() 
  def one(i): print(1)
  def _wo(i): print([k for k in Eg._all if k[0] != "_"])

Eg()._wo()

def ent(d):
  e,n = 0,0
  for k in d: n += d[k]
  for k in d: e -= d[k]/n * math.log( d[k]/n, 2)
  return e

def settings(s): 
  return box(**{m[1]:val(m[2]) for m in re.finditer(r"--(\w+)[^=]*=\s*(\S+)",s)})

def oo(x): print(o(x)); return x
def o(x) : return x.__class__.__name__ +"{"+ ( 
             ", ".join([f":{k} {v}" for k,v in x.items() if k[0]!="_"]))+"}" 

def cli(d: dict) -> dict:
  for k,v in d.items(): 
    v = str(v)
    for i,arg in enumerate(sys.argv):
      if arg in ["-h", "--help"]: sys.exit(print(__doc__))
      if arg in ["-"+k[0], "--"+k]: 
        v = "false" if v=="true" else ("true" if v=="false" else sys.argv[i+1])
        d[k] = val(v) 
  return d

def csv(file=None):
  with file_or_stdin(file) as src:
    for line in src:
      line = re.sub(r'([\n\t\r"\’ ]|#.*)', '', line)
      if line: yield [evil(s.strip()) for s in line.split(",")]

the = cli(settings(__doc__))

#---------------------------------------------------------------------------
print(the)