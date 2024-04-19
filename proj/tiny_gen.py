import os
import subprocess

# Define the directory path
orig_data_path = '/Users/ymdatta/College/Spring24/CSC591/lo/proj/data'
res_path = '/Users/ymdatta/College/Spring24/CSC591/lo/proj/tiny_res'
script_path = '/Users/ymdatta/College/Spring24/CSC591/lo/proj/stddev.py'
lua_path = '/Users/ymdatta/College/Spring24/CSC591/lo/src/mylo.lua'

# Get the list of file names in the directory
file_names = os.listdir(orig_data_path)

# Iterate through each file name

for file_name in file_names:
    # Construct the full file path
        file_path = os.path.join(orig_data_path, file_name)

        o_filename = f'{file_name}_tiny.txt'
        o_file_path = os.path.join(res_path, o_filename)

        command1 = f'lua {lua_path} -t d2h_d --file {file_path} > /tmp/x'
        command = f'python3 {script_path} /tmp/x > {o_file_path}'
        print(command1)
        subprocess.run(command1, shell=True)
        print(command)
        subprocess.run(command, shell=True)