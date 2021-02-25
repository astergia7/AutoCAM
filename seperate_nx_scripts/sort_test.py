import json
import math
import os
import pandas as pd


Order_data = r"C:\Users\vyacheslav\Desktop\FBM\feature_recognition_machining-master\output\ordering_tests.txt"

with open(Order_data) as json_file:
    data= json.load(json_file)


#print(data)
#sorted(data, key="MCS_TOP")

df_json = pd.read_json(Order_data)
df_json.to_excel(r"C:\Users\vyacheslav\Desktop\FBM\feature_recognition_machining-master\output\ordering_tests.xlsx", sheet_name='Operations List', index=False)
