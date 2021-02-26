import json
import math
import os
import pandas as pd


Order_data = r"C:\Users\vyacheslav\Desktop\FBM\feature_recognition_machining-master\output\ordering_tests.txt"

with open(Order_data) as json_file:
    data= json.load(json_file)

key_value ={} 

# Initializing the value  
key_value[1] = "MCS_TOP"      
key_value[2] = "MCS_DOWN"
key_value[3] = "MCS_FRONT"      
key_value[4] = "MCS_BACK" 
key_value[5] = "MCS_LEFT" 
key_value[6] = "MCS_RIGHT"

print(data[0])

#print(data)
#sorted(data, key="MCS_TOP")

#df_json = pd.read_json(Order_data)
#df_json.to_excel(r"C:\Users\vyacheslav\Desktop\FBM\feature_recognition_machining-master\output\ordering_tests.xlsx", sheet_name='Operations List', index=False)
