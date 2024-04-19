import os
import subprocess

# Define the directory path
orig_data_path = '/Users/ymdatta/College/Spring24/CSC591/lo/proj/stats'
res_path = '/Users/ymdatta/College/Spring24/CSC591/lo/proj/stats_res'
script_path = '/Users/ymdatta/College/Spring24/CSC591/lo/src/stats_2.py'

# Get the list of file names in the directory
file_names = os.listdir(orig_data_path)

# Iterate through each file name

for file_name in file_names:
    # Construct the full file path
        file_path = os.path.join(orig_data_path, file_name)

        o_filename = f'{file_name}_res.txt'
        o_file_path = os.path.join(res_path, o_filename)

        command = f'python3 {script_path} {file_path} >> {o_file_path}'
        print(command)
        subprocess.run(command, shell=True)