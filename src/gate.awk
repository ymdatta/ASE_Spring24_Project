BEGIN { FS = ","
        COHEN = .35
        K = 1
        M = 2
        SEED = 31210 }
NR==1 { head() }
NR>1  { body(NR-1) }
END   { rogues() }

function rogues(    i) {
  for(i in SYMTAB) 
    if(i ~ /^[a-z]/) print("E> ",i,typeof(SYMTAB[i])) }

function head(    c) {
  for(c=1;c<=NF;c++) {
    Name[c] = $c
    if ($c ~/[!+-]$/) Goal[c]
    if ($c ~ /^[A=Z]/) {
      Lo[c] = 1E30; Hi[c] = -1E30; Heaven[c] = $c ~ /-$/ ? 0 : 1}}} 

function body(r,     c) {
  for(c=1;c<=NF;c++) {
    if ($c != "?") {
      if ($c in Hi)  {
        $c += 0;
        Hi[c] = max($c, Hi[c])
        Lo[c] = min($c, Lo[c]) }
    D[r][c] = $c }}
  add(0,r) }

function add(g,r,   c,x) {
  ROW[g][r]
  for(c in D[r]) {
    x = D[r][c]
    if (x != "?") 
      (c in Lo) ? addNum(g,c,x) : addSym(g,c,x) }}
      
function addNum(g,c,x,    n,d) {
  n = ++N[g][c]
  d = x - Mu[g][c]
  Mu[g][c] += d / n
  M2[g][c] += d *(x - Mu[g][c])
  Sd[g][c]  = N[g][c] < 2 ? 0 : (M2[g][c]/(n - 1))**.5  }

function addSym(g,c,x,     n) {
  n = ++Has[g][c][x]
  if (n > Most[g][c]) {
    Most[g][c] = n
    Mode[g][c] = x }}
  
function mid(g,c) { return c in Lo ? Mu[g][c] : Mode[g][c] }
function div(g,c) { return c in Lo ? Sd[g][c] : entropy(Has[g][c]) }

function statsy(g,a,  fun,    c) {
  a[n] = length(ROW[g])
  fun  = fun ? fun : "mid"  
  for(c in Goal) a[Name[c]] = @fun(g,c) }

function entropy(a,    k,e,n) {
  for(k in a) n += a[k]
  for(k in a) e -= a[k]/n * log(a[k]/n, 2)
  return e }

function max(n1,n2) {return n1>n2 ? n1 : n2}
function min(n1,n2) {return n1<n2 ? n1 : n2}

function o(a,pre,    i,s,sep,nump) {
  if (typeof(a) == "number") return sprintf("%g",a) 
  if (typeof(a) != "array")  return sprintf("%s",a)
  for(i in a) {nump = i==1; break}
  for(i in a) {
    s = s sep (nump? sprintf("%s",o(a[i])) : sprintf(":%s %s",i,o(a[i])))
    sep = " "}
  return pre "{" s "}" }