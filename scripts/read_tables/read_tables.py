from itertools import takewhile
import pandas as pd
import sys
import xlrd
import json
import os

program_folder = os.path.abspath('')
Operations_table = program_folder + '/spreadsheets/features_operations.xlsx' # Path to read Excel file of list of Features and Operations to use
Json_operations = program_folder + '/resources/json/operations_data.txt' # Path to save Json file of list of Features and Operations
Json_Speed_and_feeds = program_folder + '/resources/json/tools_data.txt'# Path to save Json file of speeds, feeds and depth

def column_len(sheet, index):
    col_values = sheet.col_values(index)
    col_len = len(col_values)
    for _ in takewhile(lambda x: not x, reversed(col_values)):
        col_len -= 1
    return col_len

def row_len(sheet, index):
    row_values = sheet.row_values(index)
    r_len = len(row_values)
    for _ in takewhile(lambda x: not x, reversed(row_values)):
        r_len -= 1
    return r_len   

def Read_Tables(excel_tool_list):
    workbook = xlrd.open_workbook(Operations_table, on_demand = True)
    sheet_features = workbook.sheet_by_index(0)
    sheet_operations = workbook.sheet_by_index(1)
    featureTypes1=[]
    operationTypes=[]
    data={}
    data['features']=[]
    data['operations']=[]

    for x in range (1, int(column_len(sheet_features, 0))):
        if not str(sheet_features.cell(x, 0).value):
            pass
        else:
            if str(sheet_features.cell(x, 0).value) == '1.0': # Check state of the Feature in the Excel file: 0 - skip, 1 - write to list
                data['features'].append(str(sheet_features.cell(x, 1).value))
            else:
                pass

    for x in range (1, int(column_len(sheet_operations, 0))):
        if not str(sheet_operations.cell(x, 0).value):
            pass
        else:
            if str(sheet_operations.cell(x, 0).value) == '1.0': # Check state of the Operation in the Excel file: 0 - skip, 1 - write to list
                data['operations'].append(str(sheet_operations.cell(x, 1).value))
            else:
                pass

    workbook.release_resources()
    del workbook
    
    with open(Json_operations,'w') as outfile:
        json.dump(data, outfile)

    print("\n-------- Features and Operations Selection Database Created --------\n")

    # Start processing of speeds feeds and depth
    pdTool_DF = pd.read_excel(excel_tool_list)
    pdTool_DF = pdTool_DF.fillna('')

    snf_data={}
    Tool_names = []
    speed_list = []
    feed_list = []
    depth_list = []
    t_list = []
    st_list = []
    flen_list = []
    dia_list = []
    Tnames = pdTool_DF.loc[:,["LIBRF","Speed","Feed","Depth","T","ST","HEI","DIA"]]
    for x in range (len(Tnames.index)):
        Tool_names.append(str(Tnames.loc[x,"LIBRF"]))
        speed_list.append(str(Tnames.loc[x,"Speed"]))
        feed_list.append(str(Tnames.loc[x,"Feed"]))
        depth_list.append(str(Tnames.loc[x,"Depth"]))
        
        t_list.append(str(Tnames.loc[x,"T"]))
        st_list.append(str(Tnames.loc[x,"ST"]))
        flen_list.append(str(Tnames.loc[x,"HEI"]))
        dia_list.append(str(Tnames.loc[x,"DIA"]))
    
    s_n_f = []
    for x in range (len(Tool_names)):
        temp_ab=[]
        temp_ab.append(speed_list[x])
        temp_ab.append(feed_list[x])
        temp_ab.append(depth_list[x])

        temp_ab.append(t_list[x])
        temp_ab.append(st_list[x])
        temp_ab.append(flen_list[x])
        temp_ab.append(dia_list[x])

        s_n_f.append(temp_ab)

    n = 0
    for x in range (len(Tool_names)):
        snf_data['{}'.format(Tool_names[x])] = s_n_f[n]
        n += 1

    with open(Json_Speed_and_feeds,'w') as outfile:
        json.dump(snf_data, outfile)

    print("\n-------- Speeds-Feeds Database Created --------\n")
