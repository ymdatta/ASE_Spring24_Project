import sys, random, argparse

def of(s):
    try: return float(s)
    except ValueError: return s

def slurp(file):
  nums,lst,last= [],[],None
  with open(file) as fp: 
    for word in [of(x) for s in fp.readlines() for x in s.split()]:
      if isinstance(word,float):
        lst += [word]
      else:
        if len(lst)>0: nums += [NUM(lst,last)]
        lst,last =[],word
  if len(lst)>0: nums += [NUM(lst,last)]
  return nums

class NUM:
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

  def mid(self): return self.has[len(self.has)//2]

  def bar(self, num, fmt="%8.3f", word="%10s", width=50):
    out  = [' '] * width
    pos = lambda x: int(width * (x - self.has[0]) / (self.has[-1] - self.has[0] + 1E-30))
    [a, b, c, d, e]  = [num.has[int(len(num.has)*x)] for x in [0.1,0.3,0.5,0.7,0.9]]
    [na,nb,nc,nd,ne] = [pos(x) for x in [a,b,c,d,e]]
    for i in range(na,nb): out[i] = "-"
    for i in range(nd,ne): out[i] = "-"
    out[width//2] = "|"
    if nc < len(out):
      out[nc] = "*"
    return ', '.join(["%2d" % num.rank, word % num.txt, fmt%c, fmt%(d-b),
                      ''.join(out), ', '.join([(fmt % x) for x in [a,b,c,d,e]])])

def different(x,y):
  "non-parametric effect size and significance test"
  return _cliffsDelta(x,y) and _bootstrap(x,y)

def _cliffsDelta(x, y, effectSize=0.2):
  """non-parametric effect size. threshold is border between small=.11 and medium=.28 
     from Table1 of  https://doi.org/10.3102/10769986025002101"""
  #if len(x) > 10*len(y) : return cliffsDelta(random.choices(x,10*len(y)),y)
  #if len(y) > 10*len(x) : return cliffsDelta(x, random.choices(y,10*len(x)))
  n,lt,gt = 0,0,0
  for x1 in x:
    for y1 in y:
      n += 1
      if x1 > y1: gt += 1
      if x1 < y1: lt += 1
  return abs(lt - gt)/n  > effectSize # true if different

def _bootstrap(y0,z0,confidence=.05,Experiments=512,):
  """non-parametric significance test From Introduction to Bootstrap, 
     Efron and Tibshirani, 1993, chapter 20. https://doi.org/10.1201/9780429246593"""
  obs = lambda x,y: abs(x.mu-y.mu) / ((x.sd**2/x.n + y.sd**2/y.n)**.5 + 1E-30)
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

def sk(nums):
  "sort nums on median. give adjacent nums the same rank if they are statistically the same"
  def sk1(nums, rank,lvl=1):
    all = lambda lst:  [x for num in lst for x in num.has]
    b4, cut = NUM(all(nums)) ,None
    max =  -1
    for i in range(1,len(nums)):  
      lhs = NUM(all(nums[:i])); 
      rhs = NUM(all(nums[i:])); 
      tmp = (lhs.n*abs(lhs.mid() - b4.mid()) + rhs.n*abs(rhs.mid() - b4.mid()))/b4.n 
      if tmp > max:
         max,cut = tmp,i 
    if cut and different( all(nums[:cut]), all(nums[cut:])): 
      rank = sk1(nums[:cut], rank, lvl+1) + 1
      rank = sk1(nums[cut:], rank, lvl+1)
    else:
      for num in nums: num.rank = rank
    return rank
  #------------ 
  nums = sorted(nums, key=lambda num:num.mid())
  sk1(nums,0)
  return nums

def egSlurp(stats_file):
  eg0(slurp(stats_file))

def eg0(nums):
  all = NUM([x for num in nums for x in num.has])
  [print(all.bar(num,width=40,word="%12s", fmt="%5.2f")) for num in sk(nums)] 
    
def eg1():
  x=1
  print("inc","\tcd","\tboot","\tc+b", "\tsd/3")
  while x<1.5:
    a1 = [random.gauss(10,3) for x in range(20)]
    a2 = [y*x for y in a1]
    n1=NUM(a1)
    n2=NUM(a2)
    n12=NUM(a1+a2)
    t1=_cliffsDelta(a1,a2)
    t2= _bootstrap(a1,a2)
    t3= abs(n1.mu-n2.mu) > n12.sd/3
    print(round(x,3),t1, t2,t1 and t2, t3, sep="\t")
    x *= 1.02
  
def eg2(n=5):
  eg0([NUM([0.34, 0.49 ,0.51, 0.6]*n,   "x1"),
        NUM([0.6  ,0.7 , 0.8 , 0.89]*n,  "x2"),
        NUM([0.13 ,0.23, 0.38 , 0.38]*n, "x3"),
        NUM([0.6  ,0.7,  0.8 , 0.9]*n,   "x4"),
        NUM([0.1  ,0.2,  0.3 , 0.4]*n,   "x5")])
  
def eg3():
  eg0([NUM([0.32,  0.45,  0.50,  0.5,  0.55],"one"),
        NUM([ 0.76,  0.90,  0.95,  0.99,  0.995],"two")])

def eg4(n=5):
  eg0([
        NUM([0.34, 0.49 ,0.51, 0.6]*n,   "x1"),
        NUM([0.35, 0.52 ,0.63, 0.8]*n,   "x2"),
        NUM([0.13 ,0.23, 0.38 , 0.38]*n, "x4"),
        ])
 

if __name__ == "__main__":
  parser = argparse.ArgumentParser(description="Generate stats from file.")
  parser.add_argument("stats_file", help="path to stats file")
  args = parser.parse_args()

  stats_file = args.stats_file
  random.seed(1)
  egSlurp(stats_file)
  #[print("\n",f()) for f in [eg1,eg2,eg3,eg4]]
