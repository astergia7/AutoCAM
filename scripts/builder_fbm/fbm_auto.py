# NX 1915
import math
import NXOpen
import NXOpen.UF
import NXOpen.Assemblies
import NXOpen.CAM
import NXOpen.SIM
import json
import os

def main() : 
    program_folder = os.path.abspath('')
    Json_Speed_and_feeds = program_folder + '/resources/json/tools_data.txt' # Path to Json file os speeds, feeds and depth
    Json_operations = program_folder + '/resources/json/operations_data.txt' # Path to Json file of list of features to search
    Output_path = program_folder + '/output' # Output path to save file
    assembly_comps = []
    part_var = []
    blank_var = []
    features_data = []
    operations_data = []
    bounding = False

    theSession = NXOpen.Session.GetSession()
    theSession.Parts.LoadOptions.UsePartialLoading = False
    displayPart = theSession.Parts.Display
    if displayPart is None:
        displayPart, loadStatus = theSession.Parts.OpenDisplay(r"-@file_path@-")
    workPart = theSession.Parts.Work
    camSession = theSession.CreateCamSession()
    theLw = theSession.ListingWindow
    theUfSession = NXOpen.UF.UFSession.GetUFSession()

    # read Json machine knowledge data
    with open(Json_operations) as json_file:
        data= json.load(json_file)
        for p in data['features']:
            features_data.append(p)
        for p in data['operations']:
            operations_data.append(p)

    # turn on manufacturing mode if needed
    try:
        #markId_start = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Visible, "Enter Manufacturing")
        #theSession.ApplicationSwitchImmediate("UG_APP_MANUFACTURING")
        CAM_Setup_Build = workPart.CreateCamSetup("mill_planar")
        result1 = theSession.IsCamSessionInitialized()
        #theSession.CAMSession.PathDisplay.SetAnimationSpeed(5)
        #theSession.CAMSession.PathDisplay.SetIpwResolution(NXOpen.CAM.PathDisplay.IpwResolutionType.Medium)
        kinematicConfigurator1 = workPart.CreateKinematicConfigurator()
        theSession.CleanUpFacetedFacesAndEdges()
    except: 
        pass 

    markId1 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Visible, "body feature group")
    theLw.Open()
    try:
        comps = displayPart.ComponentAssembly.RootComponent.GetChildren() # initialize list to hold components
 
        for x in comps:
            #theLw.WriteLine(x.DisplayName)
            assembly_comps.append(x.DisplayName)
        # _print(assembly_comps) # Uncomment to check assembly parts list
        theLw.Close()

        part_var = [s for s in assembly_comps if "_Part" or "_part" in s]
        blank_var = [s for s in assembly_comps if "_Blank" in s]

        if not part_var:
            part_var.append(str(displayPart.Leaf)) 
        if not blank_var:
            bounding = True
    except: 
        part_var.append(str(displayPart.Leaf)) 
        #_print(displayPart.Leaf)
    
    featureGeometry1 = workPart.CAMSetup.CAMGroupCollection.FindObject("WORKPIECE")
    theSession.CAMSession.PathDisplay.ShowToolPath(featureGeometry1)
    markId1 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Visible, "Edit WORKPIECE")
    markId2 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "Start")
    millGeomBuilder1 = workPart.CAMSetup.CAMGroupCollection.CreateMillGeomBuilder(featureGeometry1)
    theSession.SetUndoMarkName(markId2, "Workpiece Dialog")
    millGeomBuilder1.PartGeometry.InitializeData(False)
    markId3 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "Start")
    theSession.CAMSession.PathDisplay.HideToolPath(featureGeometry1)
    geometrySetList1 = millGeomBuilder1.PartGeometry.GeometryList
    theSession.SetUndoMarkName(markId3, "Part Geometry Dialog")
    taggedObject1 = geometrySetList1.FindItem(0)
    geometrySet1 = taggedObject1

    #millGeomBuilder1.SetMaterial("MAT0_00600") #set material
    material_part = millGeomBuilder1.GetMaterial() # get part material
    #_print(material_part)

    part1 = theSession.Parts.FindObject(str(part_var[0]))

    partLoadStatus1 = part1.LoadThisPartFully()
    
    partLoadStatus1.Dispose()
    partLoadStatus2 = part1.LoadThisPartFully()
    
    partLoadStatus2.Dispose()
    bodies1 = [NXOpen.Body.Null] * 1

    component1 = workPart.ComponentAssembly.RootComponent.FindObject("COMPONENT "+str(part_var[0])+" 1")

    body_part1=component1.Prototype.OwningPart
            
    for protBodyObject in body_part1.Bodies:
        protBodyObject
        body1 = component1.FindOccurrence(protBodyObject)
        if body1 is None or body1.Layer > 256:
            continue

    bodies1[0] = body1
    bodyDumbRule1 = workPart.ScRuleFactory.CreateRuleBodyDumb(bodies1, True)
    
    scCollector1 = geometrySet1.ScCollector
    rules1 = [None] * 1 
    rules1[0] = bodyDumbRule1
    scCollector1.ReplaceRules(rules1, False)
    markId4 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "Part Geometry")
    theSession.DeleteUndoMark(markId4, None)
    markId5 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "Part Geometry")
    theSession.DeleteUndoMark(markId5, None)
    theSession.SetUndoMarkName(markId3, "Part Geometry")
    theSession.DeleteUndoMark(markId3, None)
    markId6 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "Workpiece")
    theSession.DeleteUndoMark(markId6, None)
    markId7 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "Workpiece")
    nXObject1 = millGeomBuilder1.Commit()
    theSession.DeleteUndoMark(markId7, None)
    theSession.SetUndoMarkName(markId2, "Workpiece")
    millGeomBuilder1.Destroy()
    theSession.DeleteUndoMark(markId2, None)
    markId8 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "Start")
    featureGeometry2 = nXObject1
    millGeomBuilder2 = workPart.CAMSetup.CAMGroupCollection.CreateMillGeomBuilder(featureGeometry2)
    theSession.SetUndoMarkName(markId8, "Workpiece Dialog")
    millGeomBuilder2.BlankGeometry.InitializeData(False)
    markId9 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "Start")
    geometrySetList2 = millGeomBuilder2.BlankGeometry.GeometryList
    blankIpwSetList1 = millGeomBuilder2.BlankGeometry.BlankIpwMultipleSource.SetList
    theSession.SetUndoMarkName(markId9, "Blank Geometry Dialog")
    taggedObject2 = geometrySetList2.FindItem(0)
    geometrySet2 = taggedObject2
    taggedObject3 = blankIpwSetList1.FindItem(0)
    blankIpwSet1 = taggedObject3

    #   Dialog Begin Blank Geometry
    # ----------------------------------------------
    if bounding==True:
        millGeomBuilder2.BlankGeometry.BlankDefinitionType = NXOpen.CAM.GeometryGroup.BlankDefinitionTypes.AutoBlock
        millGeomBuilder2.BlankGeometry.AutoBlockOffsetPositiveZ = 4.0
        millGeomBuilder2.BlankGeometry.AutoBlockOffsetPositiveY = 4.0
        millGeomBuilder2.BlankGeometry.AutoBlockOffsetPositiveX = 4.0
        millGeomBuilder2.BlankGeometry.AutoBlockOffsetNegativeX = 4.0
        millGeomBuilder2.BlankGeometry.AutoBlockOffsetNegativeY = 4.0
        millGeomBuilder2.BlankGeometry.AutoBlockOffsetNegativeZ = 4.0
        nXObject2 = millGeomBuilder2.Commit()
    
        featureGeometry3 = nXObject2
        millGeomBuilder3 = workPart.CAMSetup.CAMGroupCollection.CreateMillGeomBuilder(featureGeometry3)
        nXObject3 = millGeomBuilder3.Commit()
        millGeomBuilder3.Destroy()
    else:
        part2 = theSession.Parts.FindObject(str(blank_var[0]))
        partLoadStatus3 = part2.LoadThisPartFully()
    
        partLoadStatus3.Dispose()
        partLoadStatus4 = part2.LoadThisPartFully()
    
        partLoadStatus4.Dispose()
        bodies2 = [NXOpen.Body.Null] * 1 
        component2 = workPart.ComponentAssembly.RootComponent.FindObject("COMPONENT "+str(blank_var[0])+" 1")
        body_part2=component2.Prototype.OwningPart
    
        for protBodyObject2 in body_part2.Bodies:
            protBodyObject2
            body2 = component2.FindOccurrence(protBodyObject2)
            if body2 is None or body2.Layer > 256:
                continue

        bodies2[0] = body2
        bodyDumbRule2 = workPart.ScRuleFactory.CreateRuleBodyDumb(bodies2, True)
        scCollector2 = geometrySet2.ScCollector
    
        rules2 = [None] * 1 
        rules2[0] = bodyDumbRule2
        scCollector2.ReplaceRules(rules2, False)
        markId10 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "Blank Geometry")
        theSession.DeleteUndoMark(markId10, None)
        markId11 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "Blank Geometry")
        theSession.DeleteUndoMark(markId11, None)
        theSession.SetUndoMarkName(markId9, "Blank Geometry")
        theSession.DeleteUndoMark(markId9, None)
        markId12 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "Workpiece")
        theSession.DeleteUndoMark(markId12, None)
        markId13 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "Workpiece")
        nXObject2 = millGeomBuilder2.Commit()
        theSession.DeleteUndoMark(markId13, None)
        theSession.SetUndoMarkName(markId8, "Workpiece")
        millGeomBuilder2.Destroy()
        theSession.DeleteUndoMark(markId8, None)
        markId14 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "Start")
        featureGeometry3 = nXObject2
        millGeomBuilder3 = workPart.CAMSetup.CAMGroupCollection.CreateMillGeomBuilder(featureGeometry3)
        theSession.SetUndoMarkName(markId14, "Workpiece Dialog")
        markId15 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "Workpiece")
        theSession.DeleteUndoMark(markId15, None)
        markId16 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "Workpiece")
        nXObject3 = millGeomBuilder3.Commit()
        theSession.DeleteUndoMark(markId16, None)
        theSession.SetUndoMarkName(markId14, "Workpiece")
        millGeomBuilder3.Destroy()
        theSession.DeleteUndoMark(markId14, None)

    CSadding(nXObject3, workPart, theSession) # adds 6 coordinate systems

    markId46 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Visible, "Start")
    featureRecognitionBuilder1 = workPart.CAMSetup.CreateFeatureRecognitionBuilder(NXOpen.CAM.CAMObject.Null)
    manualFeatureBuilder1 = featureRecognitionBuilder1.CreateManualFeatureBuilder()
    featureRecognitionBuilder1.AssignColor = False
    featureRecognitionBuilder1.AddCadFeatureAttributes = False
    featureRecognitionBuilder1.MapFeatures = False
    theSession.SetUndoMarkName(markId46, "Find Features Dialog")
    
    #   Dialog Begin Find Features
    # ----------------------------------------------
    featureRecognitionBuilder1.RecognitionType = NXOpen.CAM.FeatureRecognitionBuilder.RecognitionEnum.Parametric
    featureRecognitionBuilder1.UseFeatureNameAsType = True 
    featureRecognitionBuilder1.IgnoreWarnings = False
    vecdirections1 = []
    featureRecognitionBuilder1.SetMachiningAccessDirection(vecdirections1, 0.0)

    #features were here
    featureRecognitionBuilder1.SetFeatureTypes(features_data)
    
    featureRecognitionBuilder1.GeometrySearchType = NXOpen.CAM.FeatureRecognitionBuilder.GeometrySearch.Workpiece
    features1 = featureRecognitionBuilder1.FindFeatures()
    markId47 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "Find Features")
    theSession.DeleteUndoMark(markId47, None)
    markId48 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "Find Features")
    nXObject10 = featureRecognitionBuilder1.Commit()
    theSession.DeleteUndoMark(markId48, None)
    theSession.SetUndoMarkName(markId46, "Find Features")
    featureRecognitionBuilder1.Destroy()
    manualFeatureBuilder1.Destroy()
    markId49 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Visible, "Start")
    #featureProcessBuilder1 = workPart.CAMSetup.CreateFeatureProcessBuilder()
    #featureProcessBuilder1.FeatureGrouping = NXOpen.CAM.FeatureProcessBuilder.FeatureGroupingType.UseExisting
    #featureProcessBuilder1.FeatureGrouping = NXOpen.CAM.FeatureProcessBuilder.FeatureGroupingType.AlwaysCreateNew
    #theSession.SetUndoMarkName(markId49, "Create Feature Process Dialog")
    
    # ----------------------------------------------
    #   Dialog Begin Create Feature Process
    # ----------------------------------------------
    
    # ---- Create program group
    nCGroup1 = workPart.CAMSetup.CAMGroupCollection.FindObject("PROGRAM")
    objectsToBeMoved1 = [NXOpen.CAM.CAMObject.Null] * 1 
    objectsToBeMoved1[0] = nCGroup1
    nCGroup2 = workPart.CAMSetup.CAMGroupCollection.FindObject("NONE")
    workPart.CAMSetup.MoveObjects(NXOpen.CAM.CAMSetup.View.ProgramOrder, objectsToBeMoved1, nCGroup2, NXOpen.CAM.CAMSetup.Paste.Before)

    featureProcessBuilder1 = workPart.CAMSetup.CreateFeatureProcessBuilder()
    markId50 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "Create Feature Process")
    theSession.DeleteUndoMark(markId50, None)
    markId51 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "Create Feature Process")
    featureProcessBuilder1.Type = NXOpen.CAM.FeatureProcessBuilder.FeatureProcessType.RuleBased
    featureProcessBuilder1.SetGeometryLocation("")
    #featureProcessBuilder1.FeatureGrouping = NXOpen.CAM.FeatureProcessBuilder.FeatureGroupingType.AlwaysCreateNew
    featureProcessBuilder1.FeatureGrouping = NXOpen.CAM.FeatureProcessBuilder.FeatureGroupingType.UseExisting
    featureProcessBuilder1.SetRuleLibraries(operations_data) # set operations library check
    id1 = theSession.NewestVisibleUndoMark
    nErrs6 = theSession.UpdateManager.DoUpdate(id1)
    operations1, featureProcessBuilderStatus1 = featureProcessBuilder1.CreateFeatureProcesses(features1)
    result1 = featureProcessBuilderStatus1.GetResultStatus()
    featureProcessBuilderStatus1.Dispose()
    theSession.DeleteUndoMark(markId51, None)
    theSession.SetUndoMarkName(id1, "Create Feature Process")
    featureProcessBuilder1.Destroy()
    theSession.CleanUpFacetedFacesAndEdges()
    featureGeometry4 = nXObject3
    theSession.CAMSession.PathDisplay.ShowToolPath(featureGeometry4)
    markId52 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Visible, "Generate Tool Paths")
    objects1 = [NXOpen.CAM.CAMObject.Null] * 1 
    nCGroup1 = workPart.CAMSetup.CAMGroupCollection.FindObject("PROGRAM")
    objects1[0] = nCGroup1
    workPart.CAMSetup.GenerateToolPath(objects1)

    # Save file
    partSaveStatus1 = workPart.Save(NXOpen.BasePart.SaveComponents.TrueValue, NXOpen.BasePart.CloseAfterSave.FalseValue)
    #partSaveStatus1 = workPart.SaveAs(Output_path+"\\Computed_Assembly.prt")
    partSaveStatus1.Dispose()

def s_n_f():
    # Assign Feeds and Speeds
    with open(Json_Speed_and_feeds) as json_file:
        data= json.load(json_file)

    start_point = workPart.CAMSetup.CAMOperationCollection.FindObject("GEOMETRY")
    objects_at_start = NXOpen.CAM.NCGroup.GetMembers(start_point)
    millGeomBuilder1 = workPart.CAMSetup.CAMGroupCollection.CreateMillGeomBuilder(start_point)

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
        material=str(millGeomBuilder1.GetMaterial())
        a=selected_tool+','+material
        try:
            buff = data[a]
            speed = float(buff[0])
            feed = float(buff[1])                 
            depth = float(buff[2])

            K=builder_selector(x,Operation,workPart)
            K.FeedsBuilder.SurfaceSpeedBuilder.Value = speed
            K.FeedsBuilder.FeedPerToothBuilder.Value = feed
            K.DepthPerCut.Value = depth
            K.FeedsBuilder.RecalculateData(NXOpen.CAM.FeedsBuilder.RecalcuateBasedOn.SurfaceSpeed)
            K.Commit()
        except:
            pass

    nCGroup1 = workPart.CAMSetup.CAMGroupCollection.FindObject("PROGRAM")
    theSession.CAMSession.PathDisplay.ShowToolPath(nCGroup1)
    
    markId57 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Visible, "Generate Tool Paths")
    
    objects1 = [NXOpen.CAM.CAMObject.Null] * 1 
    objects1[0] = nCGroup1
    workPart.CAMSetup.GenerateToolPath(objects1)
      
    # Save file
    partSaveStatus1 = workPart.Save(NXOpen.BasePart.SaveComponents.TrueValue, NXOpen.BasePart.CloseAfterSave.FalseValue)
    #partSaveStatus1 = workPart.SaveAs(Output_path+"\\Computed_Assembly.prt")
    partSaveStatus1.Dispose()

def CSadding(nXObject3, workPart, theSession):
     
     # Delete Local coordinate system if it exists
    try:
        markId1_1 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Visible, "Delete")
        objects1_1 = [NXOpen.TaggedObject.Null] * 1 
        orientGeometry1_1 = workPart.CAMSetup.CAMGroupCollection.FindObject("MCS_LOCAL")
        objects1_1[0] = orientGeometry1_1
        nErrs1 = theSession.UpdateManager.AddObjectsToDeleteList(objects1_1)
        nErrs2 = theSession.UpdateManager.DoUpdate(markId1_1)
    except:
        pass

    # ----------------------------------------------
    #   Menu: Insert->Geometry...
    # ----------------------------------------------
    markId17 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Visible, "Create Geometry")
    
    featureGeometry4 = nXObject3
    nCGroup1 = workPart.CAMSetup.CAMGroupCollection.CreateGeometry(featureGeometry4, "mill_planar", "MCS", NXOpen.CAM.NCGroupCollection.UseDefaultName.FalseValue, "MCS_TOP")
    
    markId18 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "Start")
    
    orientGeometry1 = nCGroup1
    millOrientGeomBuilder1 = workPart.CAMSetup.CAMGroupCollection.CreateMillOrientGeomBuilder(orientGeometry1)
    csyspurposemode1 = millOrientGeomBuilder1.GetCsysPurposeMode()
    specialoutputmode1 = millOrientGeomBuilder1.GetSpecialOutputMode()
    toolaxismode1 = millOrientGeomBuilder1.GetToolAxisMode()
    
    origin1 = NXOpen.Point3d(0.0, 0.0, 0.0)
    normal1 = NXOpen.Vector3d(0.0, 0.0, 1.0)
    plane1 = workPart.Planes.CreatePlane(origin1, normal1, NXOpen.SmartObject.UpdateOption.AfterModeling)
    
    unit1 = workPart.UnitCollection.FindObject("MilliMeter")
    expression1 = workPart.Expressions.CreateSystemExpressionWithUnits("0", unit1)
    
    expression2 = workPart.Expressions.CreateSystemExpressionWithUnits("0", unit1)
    
    lowerlimitmode1 = millOrientGeomBuilder1.GetLowerLimitMode()
    
    origin2 = NXOpen.Point3d(0.0, 0.0, 0.0)
    normal2 = NXOpen.Vector3d(0.0, 0.0, 1.0)
    plane2 = workPart.Planes.CreatePlane(origin2, normal2, NXOpen.SmartObject.UpdateOption.AfterModeling)
    
    expression3 = workPart.Expressions.CreateSystemExpressionWithUnits("0", unit1)
    
    expression4 = workPart.Expressions.CreateSystemExpressionWithUnits("0", unit1)
    
    theSession.SetUndoMarkName(markId18, "MCS Dialog")
    
    # ----------------------------------------------
    #   Dialog Begin MCS
    # ----------------------------------------------
    toolaxismode2 = millOrientGeomBuilder1.GetToolAxisMode()
    
    millOrientGeomBuilder1.SetToolAxisMode(NXOpen.CAM.OrientGeomBuilder.ToolAxisModes.PositiveZOfMcs)
    
    markId19 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "MCS")
    
    theSession.DeleteUndoMark(markId19, None)
    
    markId20 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "MCS")
    
    nXObject4 = millOrientGeomBuilder1.Commit()
    
    theSession.DeleteUndoMark(markId20, None)
    
    theSession.SetUndoMarkName(markId18, "MCS")
    
    millOrientGeomBuilder1.Destroy()
    
    try:
        # Expression is still in use.
        workPart.Expressions.Delete(expression4)
    except NXOpen.NXException as ex:
        ex.AssertErrorCode(1050029)
        
    try:
        # Expression is still in use.
        workPart.Expressions.Delete(expression2)
    except NXOpen.NXException as ex:
        ex.AssertErrorCode(1050029)
        
    try:
        # Expression is still in use.
        workPart.Expressions.Delete(expression3)
    except NXOpen.NXException as ex:
        ex.AssertErrorCode(1050029)
        
    plane2.DestroyPlane()
    
    try:
        # Expression is still in use.
        workPart.Expressions.Delete(expression1)
    except NXOpen.NXException as ex:
        ex.AssertErrorCode(1050029)
        
    plane1.DestroyPlane()
    
    theSession.DeleteUndoMark(markId18, None)
    
    # ----------------------------------------------
    #   Menu: Insert->Geometry...
    # ----------------------------------------------
    markId21 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Visible, "Create Geometry")
    
    nCGroup2 = workPart.CAMSetup.CAMGroupCollection.CreateGeometry(featureGeometry4, "mill_planar", "MCS", NXOpen.CAM.NCGroupCollection.UseDefaultName.FalseValue, "MCS_DOWN")
    
    markId22 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "Start")
    
    orientGeometry2 = nCGroup2
    millOrientGeomBuilder2 = workPart.CAMSetup.CAMGroupCollection.CreateMillOrientGeomBuilder(orientGeometry2)
    
    csyspurposemode2 = millOrientGeomBuilder2.GetCsysPurposeMode()
    
    specialoutputmode2 = millOrientGeomBuilder2.GetSpecialOutputMode()
    
    toolaxismode3 = millOrientGeomBuilder2.GetToolAxisMode()
    
    origin3 = NXOpen.Point3d(0.0, 0.0, 0.0)
    normal3 = NXOpen.Vector3d(0.0, 0.0, 1.0)
    plane3 = workPart.Planes.CreatePlane(origin3, normal3, NXOpen.SmartObject.UpdateOption.AfterModeling)
    
    expression5 = workPart.Expressions.CreateSystemExpressionWithUnits("0", unit1)
    
    expression6 = workPart.Expressions.CreateSystemExpressionWithUnits("0", unit1)
    
    lowerlimitmode2 = millOrientGeomBuilder2.GetLowerLimitMode()
    
    origin4 = NXOpen.Point3d(0.0, 0.0, 0.0)
    normal4 = NXOpen.Vector3d(0.0, 0.0, 1.0)
    plane4 = workPart.Planes.CreatePlane(origin4, normal4, NXOpen.SmartObject.UpdateOption.AfterModeling)
    
    expression7 = workPart.Expressions.CreateSystemExpressionWithUnits("0", unit1)
    
    expression8 = workPart.Expressions.CreateSystemExpressionWithUnits("0", unit1)
    
    theSession.SetUndoMarkName(markId22, "MCS Dialog")
    
    # ----------------------------------------------
    #   Dialog Begin MCS
    # ----------------------------------------------
    toolaxismode4 = millOrientGeomBuilder2.GetToolAxisMode()
    
    millOrientGeomBuilder2.SetToolAxisMode(NXOpen.CAM.OrientGeomBuilder.ToolAxisModes.PositiveZOfMcs)
    
    origin5 = NXOpen.Point3d(0.0, 0.0, 0.0)
    xDirection1 = NXOpen.Vector3d(1.0, 0.0, 0.0)
    yDirection1 = NXOpen.Vector3d(0.0, 1.1714553645825241e-15, 1.0)
    xform1 = workPart.Xforms.CreateXform(origin5, xDirection1, yDirection1, NXOpen.SmartObject.UpdateOption.AfterModeling, 1.0)
    
    cartesianCoordinateSystem1 = workPart.CoordinateSystems.CreateCoordinateSystem(xform1, NXOpen.SmartObject.UpdateOption.AfterModeling)
    
    millOrientGeomBuilder2.Mcs = cartesianCoordinateSystem1
    
    origin6 = NXOpen.Point3d(0.0, 0.0, 0.0)
    xDirection2 = NXOpen.Vector3d(1.0, 0.0, 0.0)
    yDirection2 = NXOpen.Vector3d(0.0, -1.0, 2.3429107291650482e-15)
    xform2 = workPart.Xforms.CreateXform(origin6, xDirection2, yDirection2, NXOpen.SmartObject.UpdateOption.AfterModeling, 1.0)
    
    cartesianCoordinateSystem2 = workPart.CoordinateSystems.CreateCoordinateSystem(xform2, NXOpen.SmartObject.UpdateOption.AfterModeling)
    
    millOrientGeomBuilder2.Mcs = cartesianCoordinateSystem2
    
    markId23 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "MCS")
    
    theSession.DeleteUndoMark(markId23, None)
    
    markId24 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "MCS")
    
    nXObject5 = millOrientGeomBuilder2.Commit()
    
    theSession.DeleteUndoMark(markId24, None)
    
    theSession.SetUndoMarkName(markId22, "MCS")
    
    millOrientGeomBuilder2.Destroy()
    
    markId25 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "")
    
    nErrs1 = theSession.UpdateManager.DoUpdate(markId25)
    
    theSession.DeleteUndoMark(markId25, "")
    
    try:
        # Expression is still in use.
        workPart.Expressions.Delete(expression8)
    except NXOpen.NXException as ex:
        ex.AssertErrorCode(1050029)
        
    try:
        # Expression is still in use.
        workPart.Expressions.Delete(expression6)
    except NXOpen.NXException as ex:
        ex.AssertErrorCode(1050029)
        
    try:
        # Expression is still in use.
        workPart.Expressions.Delete(expression7)
    except NXOpen.NXException as ex:
        ex.AssertErrorCode(1050029)
        
    plane4.DestroyPlane()
    
    try:
        # Expression is still in use.
        workPart.Expressions.Delete(expression5)
    except NXOpen.NXException as ex:
        ex.AssertErrorCode(1050029)
        
    plane3.DestroyPlane()
    
    theSession.DeleteUndoMark(markId22, None)
    
    # ----------------------------------------------
    #   Menu: Insert->Geometry...
    # ----------------------------------------------
    markId26 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Visible, "Create Geometry")
    
    nCGroup3 = workPart.CAMSetup.CAMGroupCollection.CreateGeometry(featureGeometry4, "mill_planar", "MCS", NXOpen.CAM.NCGroupCollection.UseDefaultName.FalseValue, "MCS_FRONT")
    
    markId27 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "Start")
    
    orientGeometry3 = nCGroup3
    millOrientGeomBuilder3 = workPart.CAMSetup.CAMGroupCollection.CreateMillOrientGeomBuilder(orientGeometry3)
    
    csyspurposemode3 = millOrientGeomBuilder3.GetCsysPurposeMode()
    
    specialoutputmode3 = millOrientGeomBuilder3.GetSpecialOutputMode()
    
    toolaxismode5 = millOrientGeomBuilder3.GetToolAxisMode()
    
    origin7 = NXOpen.Point3d(0.0, 0.0, 0.0)
    normal5 = NXOpen.Vector3d(0.0, 0.0, 1.0)
    plane5 = workPart.Planes.CreatePlane(origin7, normal5, NXOpen.SmartObject.UpdateOption.AfterModeling)
    
    expression9 = workPart.Expressions.CreateSystemExpressionWithUnits("0", unit1)
    
    expression10 = workPart.Expressions.CreateSystemExpressionWithUnits("0", unit1)
    
    lowerlimitmode3 = millOrientGeomBuilder3.GetLowerLimitMode()
    
    origin8 = NXOpen.Point3d(0.0, 0.0, 0.0)
    normal6 = NXOpen.Vector3d(0.0, 0.0, 1.0)
    plane6 = workPart.Planes.CreatePlane(origin8, normal6, NXOpen.SmartObject.UpdateOption.AfterModeling)
    
    expression11 = workPart.Expressions.CreateSystemExpressionWithUnits("0", unit1)
    
    expression12 = workPart.Expressions.CreateSystemExpressionWithUnits("0", unit1)
    
    theSession.SetUndoMarkName(markId27, "MCS Dialog")
    
    # ----------------------------------------------
    #   Dialog Begin MCS
    # ----------------------------------------------
    toolaxismode6 = millOrientGeomBuilder3.GetToolAxisMode()
    
    millOrientGeomBuilder3.SetToolAxisMode(NXOpen.CAM.OrientGeomBuilder.ToolAxisModes.PositiveZOfMcs)
    
    origin9 = NXOpen.Point3d(0.0, 0.0, 0.0)
    xDirection3 = NXOpen.Vector3d(1.0, 0.0, 0.0)
    yDirection3 = NXOpen.Vector3d(0.0, 1.1714553645825241e-15, 1.0)
    xform3 = workPart.Xforms.CreateXform(origin9, xDirection3, yDirection3, NXOpen.SmartObject.UpdateOption.AfterModeling, 1.0)
    
    cartesianCoordinateSystem3 = workPart.CoordinateSystems.CreateCoordinateSystem(xform3, NXOpen.SmartObject.UpdateOption.AfterModeling)
    
    millOrientGeomBuilder3.Mcs = cartesianCoordinateSystem3
    
    markId28 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "MCS")
    
    theSession.DeleteUndoMark(markId28, None)
    
    markId29 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "MCS")
    
    nXObject6 = millOrientGeomBuilder3.Commit()
    
    theSession.DeleteUndoMark(markId29, None)
    
    theSession.SetUndoMarkName(markId27, "MCS")
    
    millOrientGeomBuilder3.Destroy()
    
    markId30 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "")
    
    nErrs2 = theSession.UpdateManager.DoUpdate(markId30)
    
    theSession.DeleteUndoMark(markId30, "")
    
    try:
        # Expression is still in use.
        workPart.Expressions.Delete(expression12)
    except NXOpen.NXException as ex:
        ex.AssertErrorCode(1050029)
        
    try:
        # Expression is still in use.
        workPart.Expressions.Delete(expression10)
    except NXOpen.NXException as ex:
        ex.AssertErrorCode(1050029)
        
    try:
        # Expression is still in use.
        workPart.Expressions.Delete(expression11)
    except NXOpen.NXException as ex:
        ex.AssertErrorCode(1050029)
        
    plane6.DestroyPlane()
    
    try:
        # Expression is still in use.
        workPart.Expressions.Delete(expression9)
    except NXOpen.NXException as ex:
        ex.AssertErrorCode(1050029)
        
    plane5.DestroyPlane()
    
    theSession.DeleteUndoMark(markId27, None)
    
    # ----------------------------------------------
    #   Menu: Insert->Geometry...
    # ----------------------------------------------
    markId31 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Visible, "Create Geometry")
    
    nCGroup4 = workPart.CAMSetup.CAMGroupCollection.CreateGeometry(featureGeometry4, "mill_planar", "MCS", NXOpen.CAM.NCGroupCollection.UseDefaultName.FalseValue, "MCS_BACK")
    
    markId32 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "Start")
    
    orientGeometry4 = nCGroup4
    millOrientGeomBuilder4 = workPart.CAMSetup.CAMGroupCollection.CreateMillOrientGeomBuilder(orientGeometry4)
    
    csyspurposemode4 = millOrientGeomBuilder4.GetCsysPurposeMode()
    
    specialoutputmode4 = millOrientGeomBuilder4.GetSpecialOutputMode()
    
    toolaxismode7 = millOrientGeomBuilder4.GetToolAxisMode()
    
    origin10 = NXOpen.Point3d(0.0, 0.0, 0.0)
    normal7 = NXOpen.Vector3d(0.0, 0.0, 1.0)
    plane7 = workPart.Planes.CreatePlane(origin10, normal7, NXOpen.SmartObject.UpdateOption.AfterModeling)
    
    expression13 = workPart.Expressions.CreateSystemExpressionWithUnits("0", unit1)
    
    expression14 = workPart.Expressions.CreateSystemExpressionWithUnits("0", unit1)
    
    lowerlimitmode4 = millOrientGeomBuilder4.GetLowerLimitMode()
    
    origin11 = NXOpen.Point3d(0.0, 0.0, 0.0)
    normal8 = NXOpen.Vector3d(0.0, 0.0, 1.0)
    plane8 = workPart.Planes.CreatePlane(origin11, normal8, NXOpen.SmartObject.UpdateOption.AfterModeling)
    
    expression15 = workPart.Expressions.CreateSystemExpressionWithUnits("0", unit1)
    
    expression16 = workPart.Expressions.CreateSystemExpressionWithUnits("0", unit1)
    
    theSession.SetUndoMarkName(markId32, "MCS Dialog")
    
    # ----------------------------------------------
    #   Dialog Begin MCS
    # ----------------------------------------------
    origin12 = NXOpen.Point3d(0.0, 0.0, 0.0)
    xDirection4 = NXOpen.Vector3d(1.0, 0.0, 0.0)
    yDirection4 = NXOpen.Vector3d(0.0, 1.1714553645825241e-15, -1.0)
    xform4 = workPart.Xforms.CreateXform(origin12, xDirection4, yDirection4, NXOpen.SmartObject.UpdateOption.AfterModeling, 1.0)
    
    cartesianCoordinateSystem4 = workPart.CoordinateSystems.CreateCoordinateSystem(xform4, NXOpen.SmartObject.UpdateOption.AfterModeling)
    
    millOrientGeomBuilder4.Mcs = cartesianCoordinateSystem4
    
    toolaxismode8 = millOrientGeomBuilder4.GetToolAxisMode()
    
    millOrientGeomBuilder4.SetToolAxisMode(NXOpen.CAM.OrientGeomBuilder.ToolAxisModes.PositiveZOfMcs)
    
    markId33 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "MCS")
    
    theSession.DeleteUndoMark(markId33, None)
    
    markId34 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "MCS")
    
    nXObject7 = millOrientGeomBuilder4.Commit()
    
    theSession.DeleteUndoMark(markId34, None)
    
    theSession.SetUndoMarkName(markId32, "MCS")
    
    millOrientGeomBuilder4.Destroy()
    
    markId35 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "")
    
    nErrs3 = theSession.UpdateManager.DoUpdate(markId35)
    
    theSession.DeleteUndoMark(markId35, "")
    
    try:
        # Expression is still in use.
        workPart.Expressions.Delete(expression16)
    except NXOpen.NXException as ex:
        ex.AssertErrorCode(1050029)
        
    try:
        # Expression is still in use.
        workPart.Expressions.Delete(expression14)
    except NXOpen.NXException as ex:
        ex.AssertErrorCode(1050029)
        
    try:
        # Expression is still in use.
        workPart.Expressions.Delete(expression15)
    except NXOpen.NXException as ex:
        ex.AssertErrorCode(1050029)
        
    plane8.DestroyPlane()
    
    try:
        # Expression is still in use.
        workPart.Expressions.Delete(expression13)
    except NXOpen.NXException as ex:
        ex.AssertErrorCode(1050029)
        
    plane7.DestroyPlane()
    
    theSession.DeleteUndoMark(markId32, None)
    
    # ----------------------------------------------
    #   Menu: Insert->Geometry...
    # ----------------------------------------------
    markId36 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Visible, "Create Geometry")
    
    nCGroup5 = workPart.CAMSetup.CAMGroupCollection.CreateGeometry(featureGeometry4, "mill_planar", "MCS", NXOpen.CAM.NCGroupCollection.UseDefaultName.FalseValue, "MCS_RIGHT")
    
    markId37 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "Start")
    
    orientGeometry5 = nCGroup5
    millOrientGeomBuilder5 = workPart.CAMSetup.CAMGroupCollection.CreateMillOrientGeomBuilder(orientGeometry5)
    
    csyspurposemode5 = millOrientGeomBuilder5.GetCsysPurposeMode()
    
    specialoutputmode5 = millOrientGeomBuilder5.GetSpecialOutputMode()
    
    toolaxismode9 = millOrientGeomBuilder5.GetToolAxisMode()
    
    origin13 = NXOpen.Point3d(0.0, 0.0, 0.0)
    normal9 = NXOpen.Vector3d(0.0, 0.0, 1.0)
    plane9 = workPart.Planes.CreatePlane(origin13, normal9, NXOpen.SmartObject.UpdateOption.AfterModeling)
    
    expression17 = workPart.Expressions.CreateSystemExpressionWithUnits("0", unit1)
    
    expression18 = workPart.Expressions.CreateSystemExpressionWithUnits("0", unit1)
    
    lowerlimitmode5 = millOrientGeomBuilder5.GetLowerLimitMode()
    
    origin14 = NXOpen.Point3d(0.0, 0.0, 0.0)
    normal10 = NXOpen.Vector3d(0.0, 0.0, 1.0)
    plane10 = workPart.Planes.CreatePlane(origin14, normal10, NXOpen.SmartObject.UpdateOption.AfterModeling)
    
    expression19 = workPart.Expressions.CreateSystemExpressionWithUnits("0", unit1)
    
    expression20 = workPart.Expressions.CreateSystemExpressionWithUnits("0", unit1)
    
    theSession.SetUndoMarkName(markId37, "MCS Dialog")
    
    # ----------------------------------------------
    #   Dialog Begin MCS
    # ----------------------------------------------
    origin15 = NXOpen.Point3d(0.0, 0.0, 0.0)
    xDirection5 = NXOpen.Vector3d(1.1714553645825241e-15, 0.0, -1.0)
    yDirection5 = NXOpen.Vector3d(0.0, 1.0, 0.0)
    xform5 = workPart.Xforms.CreateXform(origin15, xDirection5, yDirection5, NXOpen.SmartObject.UpdateOption.AfterModeling, 1.0)
    
    cartesianCoordinateSystem5 = workPart.CoordinateSystems.CreateCoordinateSystem(xform5, NXOpen.SmartObject.UpdateOption.AfterModeling)
    
    millOrientGeomBuilder5.Mcs = cartesianCoordinateSystem5
    
    toolaxismode10 = millOrientGeomBuilder5.GetToolAxisMode()
    
    millOrientGeomBuilder5.SetToolAxisMode(NXOpen.CAM.OrientGeomBuilder.ToolAxisModes.PositiveZOfMcs)
    
    markId38 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "MCS")
    
    theSession.DeleteUndoMark(markId38, None)
    
    markId39 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "MCS")
    
    nXObject8 = millOrientGeomBuilder5.Commit()
    
    theSession.DeleteUndoMark(markId39, None)
    
    theSession.SetUndoMarkName(markId37, "MCS")
    
    millOrientGeomBuilder5.Destroy()
    
    markId40 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "")
    
    nErrs4 = theSession.UpdateManager.DoUpdate(markId40)
    
    theSession.DeleteUndoMark(markId40, "")
    
    try:
        # Expression is still in use.
        workPart.Expressions.Delete(expression20)
    except NXOpen.NXException as ex:
        ex.AssertErrorCode(1050029)
        
    try:
        # Expression is still in use.
        workPart.Expressions.Delete(expression18)
    except NXOpen.NXException as ex:
        ex.AssertErrorCode(1050029)
        
    try:
        # Expression is still in use.
        workPart.Expressions.Delete(expression19)
    except NXOpen.NXException as ex:
        ex.AssertErrorCode(1050029)
        
    plane10.DestroyPlane()
    
    try:
        # Expression is still in use.
        workPart.Expressions.Delete(expression17)
    except NXOpen.NXException as ex:
        ex.AssertErrorCode(1050029)
        
    plane9.DestroyPlane()
    
    theSession.DeleteUndoMark(markId37, None)
    
    # ----------------------------------------------
    #   Menu: Insert->Geometry...
    # ----------------------------------------------
    markId41 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Visible, "Create Geometry")
    
    nCGroup6 = workPart.CAMSetup.CAMGroupCollection.CreateGeometry(featureGeometry4, "mill_planar", "MCS", NXOpen.CAM.NCGroupCollection.UseDefaultName.FalseValue, "MCS_LEFT")
    
    markId42 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "Start")
    
    orientGeometry6 = nCGroup6
    millOrientGeomBuilder6 = workPart.CAMSetup.CAMGroupCollection.CreateMillOrientGeomBuilder(orientGeometry6)
    
    csyspurposemode6 = millOrientGeomBuilder6.GetCsysPurposeMode()
    
    specialoutputmode6 = millOrientGeomBuilder6.GetSpecialOutputMode()
    
    toolaxismode11 = millOrientGeomBuilder6.GetToolAxisMode()
    
    origin16 = NXOpen.Point3d(0.0, 0.0, 0.0)
    normal11 = NXOpen.Vector3d(0.0, 0.0, 1.0)
    plane11 = workPart.Planes.CreatePlane(origin16, normal11, NXOpen.SmartObject.UpdateOption.AfterModeling)
    
    expression21 = workPart.Expressions.CreateSystemExpressionWithUnits("0", unit1)
    
    expression22 = workPart.Expressions.CreateSystemExpressionWithUnits("0", unit1)
    
    lowerlimitmode6 = millOrientGeomBuilder6.GetLowerLimitMode()
    
    origin17 = NXOpen.Point3d(0.0, 0.0, 0.0)
    normal12 = NXOpen.Vector3d(0.0, 0.0, 1.0)
    plane12 = workPart.Planes.CreatePlane(origin17, normal12, NXOpen.SmartObject.UpdateOption.AfterModeling)
    
    expression23 = workPart.Expressions.CreateSystemExpressionWithUnits("0", unit1)
    
    expression24 = workPart.Expressions.CreateSystemExpressionWithUnits("0", unit1)
    
    theSession.SetUndoMarkName(markId42, "MCS Dialog")
    
    # ----------------------------------------------
    #   Dialog Begin MCS
    # ----------------------------------------------
    origin18 = NXOpen.Point3d(0.0, 0.0, 0.0)
    xDirection6 = NXOpen.Vector3d(1.1714553645825241e-15, 0.0, 1.0)
    yDirection6 = NXOpen.Vector3d(0.0, 1.0, 0.0)
    xform6 = workPart.Xforms.CreateXform(origin18, xDirection6, yDirection6, NXOpen.SmartObject.UpdateOption.AfterModeling, 1.0)
    
    cartesianCoordinateSystem6 = workPart.CoordinateSystems.CreateCoordinateSystem(xform6, NXOpen.SmartObject.UpdateOption.AfterModeling)
    
    millOrientGeomBuilder6.Mcs = cartesianCoordinateSystem6
    
    toolaxismode12 = millOrientGeomBuilder6.GetToolAxisMode()
    
    millOrientGeomBuilder6.SetToolAxisMode(NXOpen.CAM.OrientGeomBuilder.ToolAxisModes.PositiveZOfMcs)
    
    markId43 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "MCS")
    
    theSession.DeleteUndoMark(markId43, None)
    
    markId44 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "MCS")
    
    nXObject9 = millOrientGeomBuilder6.Commit()
    
    theSession.DeleteUndoMark(markId44, None)
    
    theSession.SetUndoMarkName(markId42, "MCS")
    
    millOrientGeomBuilder6.Destroy()
    
    markId45 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "")
    
    nErrs5 = theSession.UpdateManager.DoUpdate(markId45)
    
    theSession.DeleteUndoMark(markId45, "")
    
    try:
        # Expression is still in use.
        workPart.Expressions.Delete(expression24)
    except NXOpen.NXException as ex:
        ex.AssertErrorCode(1050029)
        
    try:
        # Expression is still in use.
        workPart.Expressions.Delete(expression22)
    except NXOpen.NXException as ex:
        ex.AssertErrorCode(1050029)
        
    try:
        # Expression is still in use.
        workPart.Expressions.Delete(expression23)
    except NXOpen.NXException as ex:
        ex.AssertErrorCode(1050029)
        
    plane12.DestroyPlane()
    
    try:
        # Expression is still in use.
        workPart.Expressions.Delete(expression21)
    except NXOpen.NXException as ex:
        ex.AssertErrorCode(1050029)
        
    plane11.DestroyPlane()
    
    theSession.DeleteUndoMark(markId42, None)

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