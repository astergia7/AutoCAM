from itertools import takewhile
import sys
import xlrd
import json
import os

program_folder = os.path.abspath('')
Operations_table = program_folder + '\spreadsheets\Features_and_operations.xlsx' # Path to read Excel file of list of features to search
Speeds_and_feeds_table = program_folder + '\spreadsheets\Speeds_feeds_depth.xlsx'# Path to read Excel file of speeds, feeds and depth
Json_operations = program_folder + '\\resources\json\operations_data.txt' # Path to save Json file of list of features to search
Json_Speed_and_feeds = program_folder + '\\resources\json\\tools_data.txt'# Path to save Json file of speeds, feeds and depth

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

def Read_Tables():
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
            featureTypes1.append(str(sheet_features.cell(x, 0).value))
            data['features'].append(str(sheet_features.cell(x, 0).value))

    for x in range (1, int(column_len(sheet_operations, 0))):
        if not str(sheet_operations.cell(x, 0).value):
            pass
        else:
            operationTypes.append(str(sheet_operations.cell(x, 0).value))
            data['operations'].append(str(sheet_operations.cell(x, 0).value))

    workbook.release_resources()
    del workbook

    # Start processing of speeds feeds and depth
    workbook2 = xlrd.open_workbook(Speeds_and_feeds_table, on_demand = True)
    sheet_tools = workbook2.sheet_by_index(0)

    tool_list=[]
    material_list=[]
    value_temp=[]
    Speeds_and_feeds_data={}

    for x in range (2, int(column_len(sheet_tools, 0))):
        if not str(sheet_tools.cell(x, 0).value):
            pass
        else:
            tool_list.append(str(sheet_tools.cell(x, 0).value))

    for y in range (1, int(row_len(sheet_tools, 0))):
        if not str(sheet_tools.cell(0, y).value):
            pass
        else:
            buff = str(sheet_tools.cell(0, y).value).split('(')
            material_list.append(buff[1].replace(')',''))

    for x in range (len(tool_list)):
        for y in range (int(row_len(sheet_tools, 3)-1)):
                value_temp.append(str(sheet_tools.cell(x+2, y+1).value))

    value_a=value_temp[0::3]
    value_b=value_temp[1::3]
    value_c=value_temp[2::3]
    #print(value_c)

    s_and_f=[]
    for x in range (len(value_a)):
        temp_ab=[]
        temp_ab.append(value_a[x])
        temp_ab.append(value_b[x])
        temp_ab.append(value_c[x])
        s_and_f.append(temp_ab)

    n = 0

    for x in range (len(tool_list)):
        for y in range (len(material_list)):
            Speeds_and_feeds_data['{},{}'.format(tool_list[x],material_list[y])] = s_and_f[n]
            n += 1

    #print(Speeds_and_feeds_data)

    workbook2.release_resources()
    del workbook2

    with open(Json_operations,'w') as outfile:
        json.dump(data, outfile)

    with open(Json_Speed_and_feeds,'w') as outfile:
        json.dump(Speeds_and_feeds_data, outfile)

    ("\n-------- Speeds-Feeds Database Created --------\n")