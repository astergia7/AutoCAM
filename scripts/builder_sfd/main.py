from nx_assign_data_builder import NxAssignBuilder
import sys

if __name__ == "__main__":
    project_path = sys.argv[1]
    nx_file_name = sys.argv[2]
    nx_path = sys.argv[3]
    output_path = sys.argv[4]

    #project_path = 'C:/Users/vyacheslav/Desktop/FBM/feature_recognition_machining-master'
    #nx_file_name = 'Another_Assembly.prt'
    #nx_path = 'C:/Program Files/Siemens/NX1899/'
    
    NAB=NxAssignBuilder()
    NAB.run(project_path, nx_file_name, nx_path, output_path)