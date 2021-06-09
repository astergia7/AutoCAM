from read_tables import Read_Tables
import sys
import os

# read_tables sripts are reading values from "features_operations.xlsx" and tool database excel file specified by user.
# From tool database script only grabs tool's library references, speed, feed and depth parameters
 
if __name__ == "__main__":
    try:
        excel_tool_list = sys.argv[1]
        program_folder = sys.argv[2]
    except:
        excel_tool_list = None
        program_folder = os.path.abspath("")

    if excel_tool_list:
        print("Selected Tool List: "+str(excel_tool_list))
    else:
        excel_tool_list = program_folder + '\spreadsheets\Tool_library.xlsx'# Path to read Excel file of speeds, feeds and depth
    Read_Tables(excel_tool_list)