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
    program_folder = os.path.abspath('')
    Json_Speed_and_feeds = program_folder + '/resources/json/tools_data.txt' # Path to Json file os speeds, feeds and depth

    theSession = NXOpen.Session.GetSession()
    theSession.Parts.LoadOptions.UsePartialLoading = False
    displayPart = theSession.Parts.Display
    if displayPart is None:
        displayPart, loadStatus = theSession.Parts.OpenDisplay(r"-@file_path@-")
    workPart = theSession.Parts.Work
    theUfSession = NXOpen.UF.UFSession.GetUFSession()
    theLw = theSession.ListingWindow
    camSession = theSession.CreateCamSession()
    CAM_Setup_Build = workPart.CreateCamSetup("mill_planar")  

    # Open tools_data.txt file to read feeds/speeds/depth parameters
    with open(Json_Speed_and_feeds) as json_file:
        data= json.load(json_file)
    
    start_point = workPart.CAMSetup.CAMOperationCollection.FindObject("WORKPIECE")
    objects_at_start = NXOpen.CAM.NCGroup.GetMembers(start_point)
    millGeomBuilder1 = workPart.CAMSetup.CAMGroupCollection.CreateMillGeomBuilder(start_point)
    material=millGeomBuilder1.GetMaterial() # get part material

    group_list = []
    checked_list = []
    operation_list = []
    cutting_tool_list = []

    for each_object in objects_at_start:
        if workPart.CAMSetup.IsGroup(each_object) == True:
            group_list.append(each_object.Name)
        elif workPart.CAMSetup.IsOperation(each_object) == True:
            operation_list.append(each_object.Name)
            cutting_tool = each_object.GetParent(NXOpen.CAM.CAMSetupView.MachineTool)
            cutting_tool_list.append(cutting_tool.Name)

    while group_list != checked_list:
        for each_object in group_list:
            if each_object not in checked_list:
                temp_objects = get_group_objects(each_object,workPart)
                for sub_object in temp_objects:
                    if workPart.CAMSetup.IsGroup(sub_object) == True:
                        group_list.append(sub_object.Name)
                    elif workPart.CAMSetup.IsOperation(sub_object) == True:
                        operation_list.append(sub_object.Name)
                checked_list.append(each_object)
    
    for each_operation in operation_list:
        Operation = workPart.CAMSetup.CAMOperationCollection.FindObject(str(each_operation))
        x=str(Operation)
        cutting_tool = Operation.GetParent(NXOpen.CAM.CAMSetup.View.MachineTool)
        x=x.split(" ",1)
        x=x[0].split("<NXOpen.CAM.",1)
        x=x[1]
        x="Create"+x+"Builder"
        selected_tool=str(cutting_tool.Name)
        selected_Builder=builder_selector(x,Operation,workPart)
        
        try: # Compare selected tool with database
            buff = data[selected_tool]
        except: # Upper/lover case difference
            buff = data[selected_tool.lower()]
        
        if buff[0] != '':
            speed = float(buff[0]) # extract speed value
            selected_Builder.FeedsBuilder.SurfaceSpeedBuilder.Value = speed # assign speed value
            selected_Builder.FeedsBuilder.RecalculateData(NXOpen.CAM.FeedsBuilder.RecalcuateBasedOn.SurfaceSpeed)
        if buff[1] != '':
            feed = float(buff[1]) # extract feed value
            selected_Builder.FeedsBuilder.FeedPerToothBuilder.Value = feed  # assign feed value
            selected_Builder.FeedsBuilder.RecalculateData(NXOpen.CAM.FeedsBuilder.RecalcuateBasedOn.FeedPerTooth)
            if selected_Builder.FeedsBuilder.SpindleRpmBuilder.Value > 16000.0:
                selected_Builder.FeedsBuilder.SpindleRpmBuilder.Value = 16000.0
                selected_Builder.FeedsBuilder.FeedPerToothBuilder.Value = feed  # assign feed value
                selected_Builder.FeedsBuilder.RecalculateData(NXOpen.CAM.FeedsBuilder.RecalcuateBasedOn.FeedPerTooth)
        if buff[2] != '':
            depth = float(buff[2]) # extract depth value
            if x == "CreateCavityMillingBuilder":
                if '_ROUGH' in str(each_operation):    
                    selected_Builder.CutLevel.GlobalDepthPerCut.DistanceBuilder.Value = depth + 0.5 # assign depth value to cavity mill operation
                else:
                    selected_Builder.CutLevel.GlobalDepthPerCut.DistanceBuilder.Value = depth 
            elif x == "CreateHoleDrillingBuilder" or x == "CreateChamferMillingBuilder" or x == "CreateCylinderMillingBuilder":
                pass
            else:
                selected_Builder.DepthPerCut.Value = depth # assign depth value to other type of operations, drill will be ignored automatically by NX
        
        selected_Builder.FeedsBuilder.RecalculateData(NXOpen.CAM.FeedsBuilder.RecalcuateBasedOn.SurfaceSpeed)
        selected_Builder.Commit() # Appy changes
    
    # Save file
    partSaveStatus1 = workPart.Save(NXOpen.BasePart.SaveComponents.TrueValue, NXOpen.BasePart.CloseAfterSave.FalseValue)
    partSaveStatus1.Dispose()

def _print(message):
   
  NXOpen.UI.GetUI().NXMessageBox.Show("Print Message",NXOpen.NXMessageBox.DialogType.Information,str(message))

def get_group_objects(group_name,workPart):
    find_it = workPart.CAMSetup.CAMOperationCollection.FindObject(group_name)
    new_objects = NXOpen.CAM.NCGroup.GetMembers(find_it)
    return new_objects

def builder_selector(name_string, operation_name, workPart):
    if name_string == "CreateCavityMillingBuilder":
        Builder=workPart.CAMSetup.CAMOperationCollection.CreateCavityMillingBuilder(operation_name)
        return Builder

    elif name_string == "CreateCenterlineDrillTurningBuilder":
        Builder=workPart.CAMSetup.CAMOperationCollection.CreateCenterlineDrillTurningBuilder(operation_name)
        return Builder

    elif name_string == "CreateChamferMillingBuilder":
        Builder=workPart.CAMSetup.CAMOperationCollection.CreateChamferMillingBuilder(operation_name)
        return Builder

    elif name_string == "CreateCylinderMillingBuilder":
        Builder=workPart.CAMSetup.CAMOperationCollection.CreateCylinderMillingBuilder(operation_name)
        return Builder

    elif name_string == "CreateDpmitpBuilder":
        Builder=workPart.CAMSetup.CAMOperationCollection.CreateDpmitpBuilder(operation_name)
        return Builder
    
    elif name_string == "CreateEngravingBuilder":
        Builder=workPart.CAMSetup.CAMOperationCollection.CreateEngravingBuilder(operation_name)
        return Builder

    elif name_string == "CreateFaceMillingBuilder":
        Builder=workPart.CAMSetup.CAMOperationCollection.CreateFaceMillingBuilder(operation_name)
        return Builder

    elif name_string == "CreateFeatureMillingBuilder":
        Builder=workPart.CAMSetup.CAMOperationCollection.CreateFeatureMillingBuilder(operation_name)
        return Builder

    elif name_string == "CreateFinishTurningBuilder":
        Builder=workPart.CAMSetup.CAMOperationCollection.CreateFinishTurningBuilder(operation_name)
        return Builder

    elif name_string == "CreateGmcopBuilder":
        Builder=workPart.CAMSetup.CAMOperationCollection.CreateGmcopBuilder(operation_name)
        return Builder
    
    elif name_string == "CreateGrooveMillingBuilder":
        Builder=workPart.CAMSetup.CAMOperationCollection.CreateGrooveMillingBuilder(operation_name)
        return Builder

    elif name_string == "CreateHoleDrillingBuilder":
        Builder=workPart.CAMSetup.CAMOperationCollection.CreateHoleDrillingBuilder(operation_name)
        return Builder

    elif name_string == "CreateHoleMakingBuilder":
        Builder=workPart.CAMSetup.CAMOperationCollection.CreateHoleMakingBuilder(operation_name)
        return Builder

    elif name_string == "CreateLaserTeachMode":
        Builder=workPart.CAMSetup.CAMOperationCollection.CreateLaserTeachMode(operation_name)
        return Builder

    elif name_string == "CreateLatheMachineControlBuilder":
        Builder=workPart.CAMSetup.CAMOperationCollection.CreateLatheMachineControlBuilder(operation_name)
        return Builder

    elif name_string == "CreateLatheUserDefinedBuilder":
        Builder=workPart.CAMSetup.CAMOperationCollection.CreateLatheUserDefinedBuilder(operation_name)
        return Builder

    elif name_string == "CreateMillMachineControlBuilder":
        Builder=workPart.CAMSetup.CAMOperationCollection.CreateMillMachineControlBuilder(operation_name)
        return Builder

    elif name_string == "CreateMillToolProbingBuilder":
        Builder=workPart.CAMSetup.CAMOperationCollection.CreateMillToolProbingBuilder(operation_name)
        return Builder

    elif name_string == "CreateMillUserDefinedBuilder":
        Builder=workPart.CAMSetup.CAMOperationCollection.CreateMillUserDefinedBuilder(operation_name)
        return Builder

    elif name_string == "CreatePlanarMillingBuilder":
        uilder=workPart.CAMSetup.CAMOperationCollection.CreatePlanarMillingBuilder(operation_name)
        return Builder

    elif name_string == "CreatePlungeMillingBuilder":
        Builder=workPart.CAMSetup.CAMOperationCollection.CreatePlungeMillingBuilder(operation_name)
        return Builder

    elif name_string == "CreatePointToPointBuilder":
        Builder=workPart.CAMSetup.CAMOperationCollection.CreatePointToPointBuilder(operation_name)
        return Builder

    elif name_string == "CreateRoughTurningBuilder":
        Builder=workPart.CAMSetup.CAMOperationCollection.CreateRoughTurningBuilder(operation_name)
        return Builder

    elif name_string == "CreateSurfaceContourBuilder":
        Builder=workPart.CAMSetup.CAMOperationCollection.CreateSurfaceContourBuilder(operation_name)
        return Builder

    elif name_string == "CreateTeachmodeTurningBuilder":
        Builder=workPart.CAMSetup.CAMOperationCollection.CreateTeachmodeTurningBuilder(operation_name)
        return Builder


    elif name_string == "CreateThreadMillingBuilder":
        Builder=workPart.CAMSetup.CAMOperationCollection.CreateThreadMillingBuilder(operation_name)
        return Builder

    elif name_string == "CreateThreadTurningBuilder":
        Builder=workPart.CAMSetup.CAMOperationCollection.CreateThreadTurningBuilder(operation_name)
        return Builder

    elif name_string == "CreateTurnPartProbingBuilder":
        Builder=workPart.CAMSetup.CAMOperationCollection.CreateTurnPartProbingBuilder(operation_name)
        return Builder

    elif name_string == "CreateTurnToolProbingBuilder":
        Builder=workPart.CAMSetup.CAMOperationCollection.CreateTurnToolProbingBuilder(operation_name)
        return Builder

    elif name_string == "CreateVazlMillingBuilder":
        Builder=workPart.CAMSetup.CAMOperationCollection.CreateVazlMillingBuilder(operation_name)
        return Builder

    elif name_string == "CreateVolumeBased25DMillingOperationBuilder":
        Builder=workPart.CAMSetup.CAMOperationCollection.CreateVolumeBased25dMillingOperationBuilder(operation_name)
        return Builder

    elif name_string == "CreateWedmMachineControlBuilder":
        Builder=workPart.CAMSetup.CAMOperationCollection.CreateWedmMachineControlBuilder(operation_name)
        return Builder

    elif name_string == "CreateWedmOperationBuilder":
        Builder=workPart.CAMSetup.CAMOperationCollection.CreateWedmOperationBuilder(operation_name)
        return Builder

    elif name_string == "CreateWedmUserDefinedBuilder":
        uilder=workPart.CAMSetup.CAMOperationCollection.CreateWedmUserDefinedBuilder(operation_name)
        return Builder

    elif name_string == "CreateZlevelMillingBuilder":
        Builder=workPart.CAMSetup.CAMOperationCollection.CreateZlevelMillingBuilder(operation_name)
        return Builder

    else:
        _print('No Match')
        Builder=0
        return Builder

main()

#if __name__ == '__main__':
#    main()