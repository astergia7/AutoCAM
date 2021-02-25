import math
import NXOpen
import NXOpen.Features
import NXOpen.Assemblies
import NXOpen.MenuBar
import NXOpen.CAM
import json

def main():
    theSession = NXOpen.Session.GetSession()
    theSession.Parts.LoadOptions.UsePartialLoading = False
    displayPart = theSession.Parts.Display
    workPart = theSession.Parts.Work
    camSession = theSession.CreateCamSession()
    start_point = workPart.CAMSetup.CAMOperationCollection.FindObject("GEOMETRY")
    objects_at_start = NXOpen.CAM.NCGroup.GetMembers(start_point)
    group_list = []
    checked_list = []
    operation_list = []
    
    def _get_op_data(obj):
        op_data = {}
        op_data['Operation name'] = obj.Name
        cutting_tool = obj.GetParent(NXOpen.CAM.CAMSetup.View.MachineTool)
        op_data['Tool'] = cutting_tool.Name
        op_data['Stock value'] = str(obj.GetRealValue("Stock Part"))
        op_data['Spindle RPM'] = str(obj.GetRealValue("Spindle RPM"))
        #op_data['Depth'] = str(obj.GetRealValue("Depth Per Cut"))
        #op_data['Depth Per Cut'] = str(obj.GetRealValue("Depth Per Cut"))
        #_print(str(obj.GetRealValue("Depth Per Cut")))
        #_print(str(obj))
        feed_rate_tuple = obj.GetFeedRate("Feed Cut")
        if feed_rate_tuple[0] == NXOpen.CAM.CAMObject.FeedRateUnit.PerMinute:
            feed_rate_units = "mm/min"
        elif feed_rate_tuple[0] == NXOpen.CAM.CAMObject.FeedRateUnit.PerRevolution:
            feed_rate_units = "mm/rev"
        else:
            feed_rate_units = "None"
        op_data['Feedrate value'] = str(feed_rate_tuple[1])    
        op_data['Feedrate type'] = feed_rate_units
        op_data['Path time'] = str(obj.GetToolpathTime())
        op_data['Toolpath Cutting Length'] = str(obj.GetToolpathCuttingLength()) # Returns toolpath cutting length in Part units (mm or inch)
        parent_feature = obj.GetParent(NXOpen.CAM.CAMSetup.View.Geometry) # parent feature group
        orient = parent_feature.GetParent()
        op_data['MCS'] = str(orient.Name)
        return op_data

    op_data_list = []
    for each_object in objects_at_start:
        if workPart.CAMSetup.IsGroup(each_object) == True:
            group_list.append(each_object.Name)
        elif workPart.CAMSetup.IsOperation(each_object) == True:
            op_data = _get_op_data(each_object)
            op_data_list.append(op_data)

    while group_list != checked_list:
        for each_object in group_list:
            if each_object not in checked_list:
                temp_objects = get_group_objects(each_object,workPart)
                for sub_object in temp_objects:
                    if workPart.CAMSetup.IsGroup(sub_object) == True:
                        group_list.append(sub_object.Name)
                    elif workPart.CAMSetup.IsOperation(sub_object) == True:
                        op_data = _get_op_data(sub_object)
                        op_data_list.append(op_data)
                checked_list.append(each_object)
    #_print(str(op_data_list))
    # Create Json file
    with open(r"C:\Users\vyacheslav\Desktop\FBM\feature_recognition_machining-master\output\ordering_tests.txt", 'w') as result_file:
        json.dump(op_data_list, result_file)

def _print(message):
    ses_ui = NXOpen.UI.GetUI()
    ses_ui.NXMessageBox.Show("Title", NXOpen.NXMessageBoxDialogType.Information, message)

def get_group_objects(group_name,workPart):
    find_it = workPart.CAMSetup.CAMOperationCollection.FindObject(group_name)
    new_objects = NXOpen.CAM.NCGroup.GetMembers(find_it)
    return new_objects

main()