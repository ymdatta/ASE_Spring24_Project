import pandas as pd
import numpy as np

df = pd.read_csv('SS-N-corrected-100.csv')

vals = df.iloc[:, 0].tolist()
values = []
for x in vals:
    if np.isnan(x):
        continue
    values.append(x)
row_values = ' '.join(map(str, values))

print(row_values)