# Main "run" file of the programme 
from pathlib import Path
from os import listdir
from os.path import isfile, join, splitext
import os
import shutil
import sys
import subprocess

class scriptRunner():
    
    def __init__(self,local_pp, nx_path, nx_file_name):
        self._local_pp = local_pp
        self._nx_path = nx_path
        self._nx_file_name = nx_file_name

    def run(self):
        print("\n-------- Starting workflow... --------\n")
        try:
            self._start_workflow()
        except Exception as e:
            raise Exception(e)
        print("\n-------- Workflow finished --------\n")

    def _start_workflow(self):
        sub = subprocess.run(['python', "./scripts/read_tables/main.py"])
        if sub.returncode != 0:
            print('\n-- ERROR --')
            print('"read_tables" crashed')
            return

        sub = subprocess.run(['python', "./scripts/read_tools/main.py"])
        if sub.returncode != 0:
            print('\n-- ERROR --')
            print('"read_tools" crashed')
            return
        
        sub = subprocess.run(['python', "./scripts/create_dat/main.py"])
        if sub.returncode != 0:
            print('\n-- ERROR --')
            print('"create_dat" crashed')
            return    
        
        sub = subprocess.run(['python', "./scripts/builder_fbm/main.py", self._local_pp, self._nx_file_name, self._nx_path,])
        if sub.returncode != 0:
            print('\n-- ERROR --')
            print('"builder_fbm" crashed')
            return

        sub = subprocess.run(['python', "./scripts/builder_ordering/main.py", self._local_pp, self._nx_file_name, self._nx_path,])
        if sub.returncode != 0:
            print('\n-- ERROR --')
            print('"builder_ordering" crashed')
            return

        A=1
        if A==0:    
            sub = subprocess.run(['python', "./scripts/builder_sfd/main.py", self._local_pp, self._nx_file_name, self._nx_path,])
            if sub.returncode != 0:
                print('\n-- ERROR --')
                print('"builder_sfd" crashed')
                return

        sub = subprocess.run(['python', "./scripts/builder_output_data/main.py", self._local_pp, self._nx_file_name, self._nx_path,])
        if sub.returncode != 0:
            print('\n-- ERROR --')
            print('"builder_output_data" crashed')
            return

if __name__ == "__main__":

    local_pp = os.path.abspath("")               # Path to this software directory
    nx_path = "C:/Program Files/Siemens/NX1899/" # Path to NX installation (for example 'C:/Siemens/NX12/')
    Output_path = local_pp+"/output"             # Path where calculated files will be generated
    Directory_files = []

    for file in os.listdir(Output_path):         # Scan directory for assembly files
        if file.endswith("_Assembly.prt"):
            Directory_files.append(file)
    
    if len(Directory_files)>1:
        print('\n-- ERROR --')
        print('More than one assembly file detected. Remove unnecessary files.')
        sys.exit()
        
    elif len(Directory_files)==0:
        print('\n-- ERROR --')
        print('No assembly file found')
        sys.exit()

    nx_file_name = Directory_files[0]      
    sc = scriptRunner(local_pp, nx_path, nx_file_name)
    sc.run()