import os

program_folder = os.path.abspath('')
Env_dat = program_folder + '\\resources\default\\ugii_env_empty.dat' # Path to read desired tool Excel file
Generated_Env_dat = program_folder + '\\output\\ugii_env.dat'# Path to generated tool database
L1 = "UGII_CAM_LIBRARY_TOOL_ENGLISH_DIR = \"" + str(program_folder) + "\\resources\custom_tool_database\english\\\""
L2 = "UGII_CAM_LIBRARY_TOOL_GRAPHICS_PATH = \"" + str(program_folder) + "\\resources\custom_tool_database\graphics\\\""
L3 = "UGII_CAM_LIBRARY_TOOL_METRIC_DIR = \"" + str(program_folder) + "\\resources\custom_tool_database\metric\\\""
L4 = "UGII_CAM_MACHINING_KNOWLEDGE_DIR = \"" + str(program_folder) + "\\resources\custom_machine_knowledge\\\""

def read_def_bat():

    with open(Env_dat, 'r') as file:
        text = file.read().split('\n')
        #print(type(text))
    
    text.append(L1)
    text.append(L2)
    text.append(L3)
    text.append(L4)
    
    A = ''
    for i in range(len(text)):
        A += str(text[i]) + '\n'
        #print(str(text[i]) + '\n')
       
    with open(Generated_Env_dat,'w') as outfile:
        outfile.write(A)
    
    print("\n-------- Create Bat Done --------\n")

#read_def_bat() 