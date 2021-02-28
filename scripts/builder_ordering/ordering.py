# NX 1915
import math
import NXOpen
import NXOpen.UF
import NXOpen.Assemblies
import NXOpen.MenuBar
import NXOpen.CAM
import NXOpen.SIM
import NXOpen.Features
import json
import os

def main(): 

    theSession = NXOpen.Session.GetSession()
    displayPart = theSession.Parts.Display
    
    if displayPart is None:
        displayPart, loadStatus = theSession.Parts.OpenDisplay(r"-@file_path@-")
    
    workPart = theSession.Parts.Work
    theUfSession = NXOpen.UF.UFSession.GetUFSession()
    theLw = theSession.ListingWindow
    camSession = theSession.CreateCamSession()
    CAM_Setup_Build = workPart.CreateCamSetup("mill_planar")  
    start_point = workPart.CAMSetup.CAMOperationCollection.FindObject("GEOMETRY")
    objects_at_start = NXOpen.CAM.NCGroup.GetMembers(start_point)
    data = _operations_collector(objects_at_start, workPart)

    nTop = 0
    nDown = 0
    nFront = 0
    nBack = 0
    nLeft = 0
    nRight = 0

    lTop = []
    lDown = []
    lFront = []
    lBack = []
    lLeft = []
    lRight = []

    for x in range(len(data)):
        if data[x]['MCS'] == "MCS_TOP":
            nTop += 1
            lTop.append(data[x]['Operation name'])
        elif data[x]['MCS'] == "MCS_DOWN":
            nDown += 1
            lDown.append(data[x]['Operation name'])
        elif data[x]['MCS'] == "MCS_FRONT":
            nFront += 1
            lFront.append(data[x]['Operation name'])
        elif data[x]['MCS'] == "MCS_BACK":
            nBack += 1
            lBack.append(data[x]['Operation name'])
        elif data[x]['MCS'] == "MCS_LEFT":
            nLeft += 1
            lLeft.append(data[x]['Operation name'])
        elif data[x]['MCS'] == "MCS_RIGHT":
            nRight += 1
            lRight.append(data[x]['Operation name'])

    Group_names = [ lTop, lDown, lFront, lBack, lLeft, lRight]
    Num_of_setups = 0
    Counters = [nTop, nDown, nFront, nBack, nLeft, nRight]
    
    for i in range(len(Counters)):
        if Counters[i]>0:
            Num_of_setups += 1
            
            oProgram = workPart.CAMSetup.CAMGroupCollection.FindObject("PROGRAM")
            nCGroup = workPart.CAMSetup.CAMGroupCollection.CreateProgram(oProgram, "mill_planar", 
                    "PROGRAM", NXOpen.CAM.NCGroupCollection.UseDefaultName.FalseValue, 
                    "SETUP_"+str(Num_of_setups))
            programOrderGroupBuilder = workPart.CAMSetup.CAMGroupCollection.CreateProgramOrderGroupBuilder(nCGroup)
            programOrderGroupBuilder.Description = "Setup №" +str(Num_of_setups)
            Folder_Object = programOrderGroupBuilder.Commit()
            
            objectsToBeMoved = [NXOpen.CAM.CAMObject.Null] * Counters[i]
            for j in range(Counters[i]):
                objectsToBeMoved[j] = workPart.CAMSetup.CAMOperationCollection.FindObject(Group_names[i][j]) 
            workPart.CAMSetup.MoveObjects(NXOpen.CAM.CAMSetup.View.ProgramOrder, objectsToBeMoved, Folder_Object, NXOpen.CAM.CAMSetup.Paste.Inside) 

    # Generate Tool Path
    all_operations = [NXOpen.CAM.CAMObject.Null] * 1 
    all_operations[0] = workPart.CAMSetup.CAMGroupCollection.FindObject("PROGRAM")
    workPart.CAMSetup.GenerateToolPath(all_operations)
    
    # Save file
    partSave = workPart.Save(NXOpen.BasePart.SaveComponents.TrueValue, NXOpen.BasePart.CloseAfterSave.FalseValue)
    partSave.Dispose()

def _operations_collector(objects_at_start, workPart):
    
    group_list = []
    checked_list = []
    operation_list = []
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
    return(op_data_list)

def _get_op_data(obj):
    op_data = {}
    op_data['Operation name'] = obj.Name
    cutting_tool = obj.GetParent(NXOpen.CAM.CAMSetup.View.MachineTool)
    op_data['Tool'] = cutting_tool.Name
    op_data['Tool Description'] = str(cutting_tool.GetStringValue("Template Subtype"))
    op_data['Stock value'] = str(obj.GetRealValue("Stock Part"))
    op_data['Spindle RPM'] = str(obj.GetRealValue("Spindle RPM"))
    if "25DMilling"  in str(obj):
        op_data['Depth Per Cut'] = str(obj.GetRealValue("Depth Per Cut"))
    else:
        op_data['Depth Per Cut'] = str("-")
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
    op_data['Operation Description'] = str(obj.GetStringValue("Template Subtype"))
    return op_data

def _print(message):
   
  NXOpen.UI.GetUI().NXMessageBox.Show("Print Message",NXOpen.NXMessageBox.DialogType.Information,str(message))

def get_group_objects(group_name,workPart):
    find_it = workPart.CAMSetup.CAMOperationCollection.FindObject(group_name)
    new_objects = NXOpen.CAM.NCGroup.GetMembers(find_it)
    return new_objects

main()