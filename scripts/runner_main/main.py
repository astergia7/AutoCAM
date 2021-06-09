# Main "run" file of the programme 
from pathlib import Path
from os import listdir
from os.path import isfile, join, splitext
import os
import shutil
import sys
import subprocess
import json

class scriptRunner():
    
    def __init__(self,local_pp, nx_path, nx_file_path, selected_tool_list):
        self._local_pp = local_pp
        self._nx_path = nx_path
        self._nx_file_path = nx_file_path
        self.selected_tool_list = selected_tool_list

    def run(self):
        try:
            self._start_workflow()
        except Exception as e:
            raise Exception(e)

    def _start_workflow(self):
        sub = subprocess.run(['python', "./scripts/read_tables/main.py", self.selected_tool_list, self._local_pp])
        if sub.returncode != 0:
            print('\n-- ERROR --')
            print('"read_tables" crashed')
            return

        sub = subprocess.run(['python', "./scripts/read_tools/main.py"])
        if sub.returncode != 0:
            print('\n-- ERROR --')
            print('"read_tools" crashed')
            return 
        
        sub = subprocess.run(['python', "./scripts/builder_clone/main.py", self._local_pp, self._nx_file_path, self._nx_path])
        if sub.returncode != 0:
            print('\n-- ERROR --')
            print('"builder_clone" crashed')
            return
        
        # Read Json for updated names
        with open(self._local_pp + '/resources/json/parts.txt') as json_file:
            data= json.load(json_file)
            self._nx_file_path = str(data[0]) + '\\' + str(data[1]) + '.prt'
            self._output_path = str(data[0])

        sub = subprocess.run(['python', "./scripts/builder_fbm/main.py", self._local_pp, self._nx_file_path, self._nx_path, self._output_path])
        if sub.returncode != 0:
            print('\n-- ERROR --')
            print('"builder_fbm" crashed')
            return

        A=1
        if A==1:    
            sub = subprocess.run(['python', "./scripts/builder_sfd/main.py", self._local_pp, self._nx_file_path, self._nx_path, self._output_path])
            if sub.returncode != 0:
                print('\n-- ERROR --')
                print('"builder_sfd" crashed')
                return

        sub = subprocess.run(['python', "./scripts/builder_generate/main.py", self._local_pp, self._nx_file_path, self._nx_path, self._output_path])
        if sub.returncode != 0:
            print('\n-- ERROR --')
            print('"builder_generate" crashed')
            return

        sub = subprocess.run(['python', "./scripts/builder_output_data/main.py", self._local_pp, self._nx_file_path, self._nx_path, self._output_path])
        if sub.returncode != 0:
            print('\n-- ERROR --')
            print('"builder_output_data" crashed')
            return
        
        output_line = str(self._output_path) 
        os.system('start explorer.exe "' + output_line + '"')

if __name__ == "__main__":
    
    local_pp = os.path.abspath("") # Path to this software directory
    output_Path = local_pp + "/output" # Path where calculated files will be generated
    print("\n-------- AutoCAM Workflow Start --------\n")
    try: # grabs data from GUI input
        nx_file_path = sys.argv[1]
        selected_tool_list = sys.argv[2]
        nx_path = sys.argv[3]

    except: # works if you launch this main.py file
        print("\n ! Only Default Script's Path! \n")
        selected_tool_list = ""
        nx_path = "C:/Program Files/Siemens/NX1953/" # Path to NX installation (for example 'C:/Siemens/NX12/')
        Input_path = local_pp + "/output"             # Path from where files will be taken
        Directory_files = []

        for file in os.listdir(Input_path): # Scan directory for assembly files
            #if file.endswith("_Assembly.prt"):
            if file.endswith("Part.prt"):
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
        nx_file_path = Input_path+ '/' + nx_file_name
    
    print(nx_path)

    sc = scriptRunner(local_pp, nx_path, nx_file_path, selected_tool_list)
    sc.run()
    print("\n-------- AutoCAM Workflow finished --------\n")