import sys
from nx_fbm_builder import NxFBMBuilder

if __name__ == "__main__":
    project_path = sys.argv[1]
    nx_file_path = sys.argv[2]
    nx_path = sys.argv[3]
    output_path = sys.argv[4]
    
    #project_path = 'C:/Users/vyacheslav/Desktop/FBM/feature_recognition_machining-master'
    #nx_file_name = 'Flange_Assembly.prt'
    #nx_path = 'C:/Program Files/Siemens/NX1953/'
    
    nsb = NxFBMBuilder()
    nsb.run(project_path, nx_file_path, nx_path, output_path)