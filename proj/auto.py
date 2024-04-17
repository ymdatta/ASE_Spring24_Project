#!/usr/bin/env python

import os
import subprocess

# Define the directory path
directory_path = '/Users/ymdatta/College/Spring24/CSC591/lo/proj/data'

# Get the list of file names in the directory
file_names = os.listdir(directory_path)

# Iterate through each file name
for file_name in file_names:
    # Construct the full file path
    file_path = os.path.join(directory_path, file_name)
    
    with open('/Users/ymdatta/College/Spring24/CSC591/lo/proj/seeds.txt') as file:
        for line in file:
            seed = line.strip()
            command = f'python3 datagen.py {file_path} 10 {seed} gendata/{file_name}_10'
            print(command)
            command2 = f'python3 datagen.py {file_path} 50 {seed} gendata/{file_name}_50'
            print(command2)
            command3 = f'python3 datagen.py {file_path} 100 {seed} gendata/{file_name}_100'
            print(command3)
            subprocess.run(command, shell=True)
            subprocess.run(command2, shell=True)
            subprocess.run(command3, shell=True)
