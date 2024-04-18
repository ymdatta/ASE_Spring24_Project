#!/usr/bin/env python

import os
import subprocess

# Define the directory path
orig_data_path = '/Users/ymdatta/College/Spring24/CSC591/lo/proj/data'
directory_path = '/Users/ymdatta/College/Spring24/CSC591/lo/proj/gendata'
lua_path = '/Users/ymdatta/College/Spring24/CSC591/lo/src/mylo.lua'
res_path = '/Users/ymdatta/College/Spring24/CSC591/lo/res_v1/2dfastmap'

# Get the list of file names in the directory
file_names = os.listdir(orig_data_path)

# Iterate through each file name

for factor in [10, 50, 100]:
    for file_name in file_names:
        # Construct the full file path
        
        with open('/Users/ymdatta/College/Spring24/CSC591/lo/proj/seeds.txt') as file:
            for line in file:
                seed = line.strip()
                file_name2 = f'{file_name}_{factor}_{seed}.csv'
                print("Checking file: ", file_name2)
                file_path = os.path.join(directory_path, file_name2)

                o_filename = f'{file_name}_{factor}.txt'
                o_file_path = os.path.join(res_path, o_filename)

                command = f'lua {lua_path} -t tree_new --file {file_path} >> {o_file_path}'
                print(command)
                subprocess.run(command, shell=True)