import json
from pathlib import Path
import subprocess
import os

class NxCloneBuilder:

    def __init__(self):
        pass

    def run(self, project_path,nx_file_name,nx_path):
        #model_full_path = project_path +'/output/'+ nx_file_name
        model_full_path = nx_file_name
        #nx_file_name = os.path.basename(nx_file_name)
        result_file_path = project_path + '/output'
        Path(result_file_path).mkdir(parents=True, exist_ok=True)
        macro_name, macro_code = self._build_macro(model_full_path, result_file_path, project_path)
        path_to_macro = project_path + '/output/' + macro_name # Path where builed macro file will be generated 
        self._write_macro(macro_code, path_to_macro)
        self._run(path_to_macro, nx_path)
        print('\n------ Done Cloning ------\n')

    def _build_macro(self, model_full_path,result_file_path,project_path):
        macro_name = "nx_clone_temp.py"
        abs_path = project_path + '/scripts/builder_clone/clone_files.py'
        with open(abs_path, "r") as code_template:
            code_list = code_template.readlines()
        py_code = ''.join(code_list)
        py_code = py_code.replace('-@file_path@-', model_full_path)
        py_code = py_code.replace('-@result_file_path@-', result_file_path)
        return macro_name, py_code

    def _write_macro(self, macro_code, path_to_macro):
        Path(path_to_macro).touch(exist_ok=True)
        f = open(path_to_macro, "w")
        f.write(macro_code)
        f.close()

    def _run(self, macro_path, nx_path):
        prepare_env = '"' + nx_path + \
                      'UGII/ugiicmd.bat" "' + nx_path + '"' + ' & '
        cmd = prepare_env + 'run_journal "' + macro_path + '"'
        subprocess.run(cmd)
