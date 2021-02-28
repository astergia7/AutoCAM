import sys
from builder_ordering import NxOrderingBuilder

if __name__ == "__main__":
    project_path = sys.argv[1]
    nx_file_name = sys.argv[2]
    nx_path = sys.argv[3]
    
    nob = NxOrderingBuilder()
    nob.run(project_path, nx_file_name, nx_path)