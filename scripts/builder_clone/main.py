from nx_clone_builder import NxCloneBuilder
import sys
import os

if __name__ == "__main__":
    
    try:
        project_path = sys.argv[1]
        nx_file_name = sys.argv[2]
        nx_path = sys.argv[3]
    
    except:
        project_path = 'C:\\Users\\vyacheslav\\Desktop\\FBM\\feature_recognition_machining-master'
        nx_file_name = project_path+'\\output\\Flange_Part.prt'
        nx_path = 'C:\\Program Files\\Siemens\\NX1953\\'
    
    NCB=NxCloneBuilder()
    NCB.run(project_path, nx_file_name, nx_path)

    remove_file = str(project_path)+'\\output\\nx_clone_temp.py'
    if os.path.exists(remove_file):
        os.remove(remove_file)
    else:
        print("The file does not exist")  