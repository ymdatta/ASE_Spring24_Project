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
from fileinput import FileInput as file_or_stdin

def o(d,s=""): 
 return s+"{"+ (", ".join([f":{k} {v}" for k,v in d.items() if k[0]!="_"]))+"}" 

class Pretty:
  def __repr__(self):  return o(self.__dict__, self.__class__.__name__)

class The(Pretty): 
  def __init__(self):
    d = {m[1]:coerce(m[2]) for m in re.finditer(r"--(\w+)[^=]*=\s*(\S+)",__doc__)}
    return self.__dict__.update(**d)
  def update(self):
    d = self.__dict__
    for k,v in d.items(): 
      v = str(v)
      for i,arg in enumerate(sys.argv):
        if arg in ["-h", "--help"]: sys.exit(print(__doc__))
        after = "" if i >= len(sys.argv) - 1 else sys.argv[i+1]
        if arg in ["-"+k[0], "--"+k]: 
          v = "false" if v=="true" else ("true" if v=="false" else after)
          d[k] = coerce(v) 
    return self

def coerce(s):
  try: return ast.literal_eval(s)
  except Exception: return s

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

def main():
  rows = [row for row in csv(the.file)]
  head = rows[0]
  body = rows[1:]
  print(head)
  _ys  = ys(head)
  a    = [[row[y] for y in _ys] for row in body]
  cols = [list(x) for x in zip(*a)]
  for i,col in enumerate(cols):
    col.sort()
    print(i, col[0], col[-1])

def ys(row):
  return [at for at,s in enumerate(row) if s[-1] in "+-!"]
#-----------------------------------------------------------------------------------------
class Eg:
  _all = locals() 
  def _egs(): return {k:v for k,v in Eg._all.items() if k[0] != "_"}

  def the():  print(the)

#---------------------------------------------------------------------------
the = The().update()
main()
