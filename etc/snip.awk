BEGIN { A="```lua"; Z0="```" }
      { a[NR]=$0 }
END   { for(i in a) {
          if ((a[i] !~ /^$/) && (a[i+1] ~ /^--- /)) {
            print(Z); slurp(a[i+1]); print(A); Z=Z0
          } else { 
            print(a[i+1]) }}}
 
function slurp(file,    s,f) {
  sub(/^--- /,"",file)
  f= "txt/" tolower(file) ".md"
  while((getline s <f)>0) print s }
