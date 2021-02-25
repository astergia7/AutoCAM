# Main "run" file of the programme 
import subprocess
from pathlib import Path
from os import listdir
from os.path import isfile, join, splitext
from pathes import Project_folder, Input_path, Output_path, nx_path
import os,shutil
import sys
sys.path.insert(1, r'..\feature_recognition_machining-master\scripts\\')
from fbm_builder.nx_fbm_builder import NxFBMBuilder
from data_builder.nx_assign_data_builder import NxAssignBuilder
from read_tables import read_speeds_feeds_depth

updateValues = False

def run(project_path,nx_file_name,nx_path):
    nsb = NxFBMBuilder() 
    nsb.run(project_path,nx_file_name,nx_path)
    if updateValues == True
        nsb2 = NxAssignBuilder()
        nsb2.run(project_path,nx_file_name,nx_path)

def copy_test_files(project_path):
    abs_path = Input_path
    Path(project_path).mkdir(parents=True, exist_ok=True)
    copytree(abs_path,project_path)

def copytree(src, dst, symlinks=False, ignore=None):
    if not os.path.exists(dst):
        os.makedirs(dst)
    for item in os.listdir(src):
        s = os.path.join(src, item)
        d = os.path.join(dst, item)
        if os.path.isdir(s):
            copytree(s, d, symlinks, ignore)
        else:
            if os.path.exists(d):
                os.remove(d)
            if not os.path.exists(d) or os.stat(s).st_mtime - os.stat(d).st_mtime > 1:
                shutil.copy2(s, d)

if __name__ == "__main__":

    Directory_files = []
    copy_test_files(Output_path)                # Copies all files to desired folder
    read_speeds_feeds_depth.Read_Tables()       # Generate Json files of excel sheets
    
    for file in os.listdir(Output_path):        # Scan directory for assembly files
        if file.endswith("_Assembly.prt"):
            Directory_files.append(file)

    for selected_file in Directory_files:
        nx_file_name = selected_file            # Name of NX file
        run(Output_path,selected_file,nx_path)
        os.rename(Output_path+'\\'+selected_file, Output_path+'\\'+selected_file[:-4]+'_Calculated.prt')
        print('File '+selected_file+' saved')
    print('Program Finished')
