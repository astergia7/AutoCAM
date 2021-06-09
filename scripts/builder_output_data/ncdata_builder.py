import json
from pathlib import Path
import subprocess
import os

class NxNCDataBuilder:

    def __init__(self):
        pass

    def run(self, project_path,nx_file_path,nx_path,output_path):
        #model_full_path = project_path +'/output/'+ nx_file_name
        model_full_path = nx_file_path
        result_file_path = output_path + '/output_data.txt'
        macro_name, macro_code = self._build_macro(model_full_path,result_file_path,project_path)
        path_to_macro = output_path + '/'+ macro_name
        self._write_macro(macro_code, path_to_macro)
        self._run(path_to_macro, nx_path)
        print('\n------ Done generating output data ------\n')

    def _build_macro(self, model_full_path,result_file_path,project_path):
        macro_name = "nx_nc_data_temp.py"
        script_dir = project_path + "/scripts"
        rel_path = '/builder_output_data/nx_nc_data.py'
        abs_path = script_dir+rel_path
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
