#!/usr/bin/env python

import os
import subprocess

# Define the directory path
orig_data_path = '/Users/ymdatta/College/Spring24/CSC591/lo/proj/data'
lua_path = '/Users/ymdatta/College/Spring24/CSC591/lo/src/mylo.lua'
res_path = '/Users/ymdatta/College/Spring24/CSC591/lo/res_v1/2dfastmap'

# Get the list of file names in the directory
file_names = os.listdir(orig_data_path)

# Iterate through each file name

for file_name in file_names:
    # Construct the full file path
        file_path = os.path.join(orig_data_path, file_name)

        o_filename = f'{file_name}_full.txt'
        o_file_path = os.path.join(res_path, o_filename)

        command = f'lua {lua_path} -t tree_new --file {file_path} >> {o_file_path}'
        print(command)
        subprocess.run(command, shell=True)