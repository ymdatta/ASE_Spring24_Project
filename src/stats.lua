local cliffsDelta,mwu,critical,ranks,rank,eg

function cliffsDelta(ns1,ns2, dull) --> bool; true if different by a trivial amount
  local n,gt,lt = 0,0,0
  for _,x in pairs(ns1) do
    for _,y in pairs(ns2) do
      n = n + 1
      if x > y then gt = gt + 1 end
      if x < y then lt = lt + 1 end end end
  return math.abs(lt - gt)/n >= (dull or 0.147) end
---------------------------------------------------------------------------------------------------
function mwu(ns1,ns2,nConf) -->bool; True if ranks of `ns1,ns2` are different at confidence `nConf`
  local t,r1,r2,u1,u2,c = ranks(ns1,ns2)
  local n1,n2= #ns1, #ns2
  assert(n1>=3,"must be 3 or more")
  assert(n2>=3,"must be 3 or more")
  c  = critical(nConf or 95,n1,n2)
  r1=0; for _,x in pairs(ns1) do r1=r1+ rank(t[x]) end
  r2=0; for _,x in pairs(ns2) do r2=r2+ rank(t[x]) end
  u1 = n1*n2 + n1*(n1+1)/2 - r1
  u2 = n1*n2 + n2*(n2+1)/2 - r2
  local word = math.min(u1,u2)<=c
  return math.min(u1,u2)<=c  end  -- not evidence evidence to say they are the same

function rank(rx) return rx.ranks/rx.n end --> n; returns average range in a treatment

function critical(c,n1,n2)
  local t={
    [99]={{0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 2, 2,  2,  2,  3,  3},
          {0, 0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 5, 5,  6,  6,  7,  8},
          {0, 0, 0, 1, 1, 2, 3, 4, 5, 6, 7, 7, 8, 9, 10, 11, 12, 13},
          {0, 0, 1, 2, 3, 4, 5, 6, 7, 9,10,11,12,13, 15, 16, 17, 18},
          {0, 0, 1, 3, 4, 6, 7, 9,10,12,13,15,16,18, 19, 21, 22, 24},
          {0, 1, 2, 4, 6, 7, 9,11,13,15,17,18,20,22, 24, 26, 28, 30},
          {0, 1, 3, 5, 7, 9,11,13,16,18,20,22,24,27, 29, 31, 33, 36},
          {0, 2, 4, 6, 9,11,13,16,18,21,24,26,29,31, 34, 37, 39, 42},
          {0, 2, 5, 7,10,13,16,18,21,24,27,30,33,36, 39, 42, 45, 48},
          {1, 3, 6, 9,12,15,18,21,24,27,31,34,37,41, 44, 47, 51, 54},
          {1, 3, 7,10,13,17,20,24,27,31,34,38,42,45, 49, 53, 56, 60},
          {1, 4, 7,11,15,18,22,26,30,34,38,42,46,50, 54, 58, 63, 67},
          {2, 5, 8,12,16,20,24,29,33,37,42,46,51,55, 60, 64, 69, 73},
          {2, 5, 9,13,18,22,27,31,36,41,45,50,55,60, 65, 70, 74, 79},
          {2, 6,10,15,19,24,29,34,39,44,49,54,60,65, 70, 75, 81, 86},
          {2, 6,11,16,21,26,31,37,42,47,53,58,64,70, 75, 81, 87, 92},
          {3, 7,12,17,22,28,33,39,45,51,56,63,69,74, 81, 87, 93, 99},
          {3, 8,13,18,24,30,36,42,48,54,60,67,73,79, 86, 92, 99,105}},
    [95]={{0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6,  6,  7,  7,  8},
          {0, 0, 1, 2, 3, 4, 4, 5, 6, 7, 8, 9,10,11, 11, 12, 13, 14},
          {0, 1, 2, 3, 5, 6, 7, 8, 9,11,12,13,14,15, 17, 18, 19, 20},
          {1, 2, 3, 5, 6, 8,10,11,13,14,16,17,19,21, 22, 24, 25, 27},
          {1, 3, 5, 6, 8,10,12,14,16,18,20,22,24,26, 28, 30, 32, 34},
          {2, 4, 6, 8,10,13,15,17,19,22,24,26,29,31, 34, 36, 38, 41},
          {2, 4, 7,10,12,15,17,20,23,26,28,31,34,37, 39, 42, 45, 48},
          {3, 5, 8,11,14,17,20,23,26,29,33,36,39,42, 45, 48, 52, 55},
          {3, 6, 9,13,16,19,23,26,30,33,37,40,44,47, 51, 55, 58, 62},
          {4, 7,11,14,18,22,26,29,33,37,41,45,49,53, 57, 61, 65, 69},
          {4, 8,12,16,20,24,28,33,37,41,45,50,54,59, 63, 67, 72, 76},
          {5, 9,13,17,22,26,31,36,40,45,50,55,59,64, 67, 74, 78, 83},
          {5,10,14,19,24,29,34,39,44,49,54,59,64,70, 75, 80, 85, 90},
          {6,11,15,21,26,31,37,42,47,53,59,64,70,75, 81, 86, 92, 98},
          {6,11,17,22,28,34,39,45,51,57,63,67,75,81, 87, 93, 99,105},
          {7,12,18,24,30,36,42,48,55,61,67,74,80,86, 93, 99,106,112},
          {7,13,19,25,32,38,45,52,58,65,72,78,85,92, 99,106,113,119},
          {8,14,20,27,34,41,48,55,62,69,76,83,90,98,105,112,119,127}}}
    n1,n2 = n1-2,n2-2
    local u=t[c]
    assert(u,"confidence level unknown")
    local n1 = math.min(n1,#u[1])
    local n2 = math.min(n2,#u)
    return u[n2][n1] end


function ranks(ns1,ns2) -->t; numbers of both populations are jointly ranked
  local x,t,u = 0,{},{}
  for _,ns in pairs{ns1,ns2} do
    for _,x in pairs(ns) do t[1+#t] = x end end
  table.sort(t)
  x = t[1]
  u[x] = {x=x,n=1,ranks=1}
  for i=2,#t do
    if t[i-1] ~= t[i] then x=t[i]; u[x] = {x=x, n=0,ranks=0}  end
    u[x].x     = t[i]
    u[x].ranks = u[x].ranks + i -- for repeated numbers, they share the rank of all the repeats
    u[x].n     = u[x].n + 1 end
  return u end


function stats(t)
   local n,sd,sum=0,0,0
   for _,v in pairs(t) do n=n+1; sum=sum+v end
   for _,v in pairs(t) do sd = sd + (v-sum/n)^2 end
   sd = (sd/(n-1))^.5 
   return n,sum/n, sd end


function cohensd(t1,t2,cohen)
  local n1,mu1,sd1 = stats(t1)
  local n2,mu2,sd2 = stats(t2)
  local pooled =  (((n1-1)*sd1^2 + (n2-1)*sd2^2)/ (n1+n2-2))^.5
  return math.abs(mu1 - mu2) / pooled >= (cohen or .35) end 

eg={}
function eg.one()
  print("false",mwu( {8,7,6,2,5,8,7,3},{8,7,6,2,5,8,7,3}))
  print("true",mwu( {8,7,6,2,5,8,7,3}, {9,9,7,8,10,9,6})) end

function eg.f(s,f)
  print""
  print(s,"true",f({0.34,0.49,0.51,0.6,.34,.49,.51,.6},{0.6,0.7,0.8,0.9,.6,.7,.8,.9}))
  print(s,"true",f({0.15,0.25,0.4,0.35,0.15,0.25,0.4,0.35},{0.6,0.7,0.8,0.9,0.6,0.7,0.8,0.9}))
  print(s,"false",f({0.6,0.7,0.8,0.9,.6,.7,.8,.9},{0.6,0.7,0.8,0.9,0.6,0.7,0.8,0.9}))
  print(s,"true",f({0.34,0.49,0.51,0.6},{0.6,0.7,0.8,0.9}))
  print(s,"true",f({0.15,0.25,0.4,0.35},{0.6,0.7,0.8,0.9}))
  print(s,"false",f({0.6,0.7,0.8,0.9},{0.6,0.7,0.8,0.9})) end

function eg.two() eg.f("mwu",mwu) end
function eg.three() eg.f("cohen",cohensd) end
function eg.four() eg.f("cliffs",cliffsDelta) end

local function gauss(mu,sd,    R)
  R=math.random
  return (mu or 0) + (sd or 1) * math.sqrt(-2 * math.log(R()))
                               * math.cos(2 * math.pi * R()) end

function eg.ten()
  for i=1,1 do
    print""
    local j=0
    while j < 1 do
      local t={}; for _=1,256 do t[1+#t] = gauss(10,1)^.5 end
      local u={}; for k,v in pairs(t) do u[k]= t[k] + j  end
      print(i,j, mwu(t,u),cliffsDelta(t,u), cohensd(t,u,.35))
      j=j+.1 end end end 

if   pcall(debug.getlocal,4,1) 
then return {mwu=mwu, cliffsDelta=cliffsDelta, cohensd=cohensd}
else eg.two()
     eg.three()
     eg.four()
     eg.ten()
end

