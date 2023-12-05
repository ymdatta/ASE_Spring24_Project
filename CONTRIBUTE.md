## Data Files
This code reads data files which names columns on line1:

- Upper case names indicate numerics (and all else are symbols).
- Names ending the `!` are klass columns (there should be only one)
- Names ending with `+` or `-` are goals to be maximized, mimizied
  (there can be many)
- Klass and goal columns are the dependent `y` columns.
- Everything else are the dependent `x` columns.
   
e.g. for  `Age,job,Salary+`:
    
   - `Age` and `Salary` are numeric
   - `Salary` is a goal to be maximized 
   - `Age` and `job` are the `x` independent variables.
       
## Classes
`function ZZZ()` is a constructor (since it has an upper case name).   
`function zzz(zz1,...)` updates `zzz1` of type `ZZZ`. 
  
##  Type hints
For function args (not for locals)
    
- `zzz1` = instance of class `ZZZ`.
- `x` is anything
- `n` = number
- `s` = string
- `xs` = list of many `x`
- `t` = table.
- `a` = array (index 1,2,3..)
- `h` = hash (indexed by keys)
- `fun` = function

  
  
## Function Args
In function args:
  
- two spaces denotes "start of optionals"
- four spaces denotes "start of locals"