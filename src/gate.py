from typing import List
from ast import literal_eval() as make
import dataclasses

data = dataclasses.dataclass
def l() : return dataclasses.field(default_factory=list)

@data
class Premium:
  amount: int = 23
  users: List[str] = l()

p1=Premium()
p1.users += [23]

p2=Premium()
print(p2.users,p2.amount)
print(p2)
print(p2.__dict__)

