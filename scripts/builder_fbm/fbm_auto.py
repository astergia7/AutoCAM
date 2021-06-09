import NXOpen
import NXOpen.UF
import NXOpen.CAM
import NXOpen.Assemblies
import json
import os
import math
import operator

# Workflow NX script with FBM Auto functionality
# Can be used only as part of "main runner"

def main():
    theSession = NXOpen.Session.GetSession()
    theSession.Parts.LoadOptions.UsePartialLoading = False
    displayPart = theSession.Parts.Display
    if displayPart is None:
        displayPart, loadStatus = theSession.Parts.OpenDisplay(r"-@file_path@-")
    workPart = theSession.Parts.Work
    camSession = theSession.CreateCamSession()
    theLw = theSession.ListingWindow
    theUfSession = NXOpen.UF.UFSession.GetUFSession()
    id1 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Visible, "FBM AUTO SCRIPT")
    
    program_folder = os.path.abspath('')
    Json_Speed_and_feeds = program_folder + '/resources/json/tools_data.txt' # Path to Json file os speeds, feeds and depth
    Json_operations = program_folder + '/resources/json/operations_data.txt' # Path to Json file of list of features to search
    
    assembly_components = []
    part_var = []
    blank_var = []
    bounding = False
    single_part = False
    features_data = []
    operations_data = []

    # Read Json machine knowledge data
    with open(Json_operations) as json_file:
        data= json.load(json_file)
        for p in data['features']:
            features_data.append(p)
        for p in data['operations']:
            operations_data.append(p)
    
    # Read Json of tools data
    with open(Json_Speed_and_feeds) as json_file:
        tools_data = json.load(json_file)

    # Initialize CAM setup and session
    try:
        theSession.ApplicationSwitchImmediate("UG_APP_MANUFACTURING")
        CAM_Setup_Build = workPart.CreateCamSetup("mill_planar") # initialize cam_setup
        theSession.CAMSession.SpecifyConfiguration("${UGII_CAM_CONFIG_DIR}cam_general")
        kinematicConfigurator1 = workPart.CreateKinematicConfigurator()
    except: 
        pass 
    
    # Check assebmly or single file
    theLw.Open()
    try:
        comps = displayPart.ComponentAssembly.RootComponent.GetChildren() # initialize list to hold components
        for x in comps:
            #theLw.WriteLine(x.DisplayName)
            assembly_components.append(x.DisplayName)
        # _print(assembly_components) # Uncomment to check assembly parts list

        part_var = [s for s in assembly_components if "_Part" in s or "_part" in s]
        blank_var = [s for s in assembly_components if "_Blank" in s or "_blank" in s]

        if not part_var:
            part_var.append(str(displayPart.Name)) 
        if not blank_var:
            #_print("No Blank Part. Bounding body will be produced.")
            bounding = True
    except:
        part_var.append(str(displayPart.Name))
        bounding = True
        single_part = True
    theLw.Close()

    featureGeometry1 = workPart.CAMSetup.CAMGroupCollection.FindObject("WORKPIECE")
    millGeomBuilder1 = workPart.CAMSetup.CAMGroupCollection.CreateMillGeomBuilder(featureGeometry1)
    millGeomBuilder1.PartGeometry.InitializeData(False)
    geometrySetList1 = millGeomBuilder1.PartGeometry.GeometryList
    geometrySet1 = geometrySetList1.FindItem(0)

    part1 = theSession.Parts.FindObject(str(part_var[0]))
    partLoadStatus1 = part1.LoadThisPartFully()
    partLoadStatus1.Dispose()
    partLoadStatus2 = part1.LoadThisPartFully()
    partLoadStatus2.Dispose()
    bodies1 = [NXOpen.Body.Null] * 1
    if single_part == True:  
        for BodyObject in workPart.Bodies:
            body1 = BodyObject
            if body1 is None or body1.Layer > 256:
                continue
    else:
        component1 = workPart.ComponentAssembly.RootComponent.FindObject("COMPONENT "+str(part_var[0])+" 1")
        body_part1=component1.Prototype.OwningPart       
        for protBodyObject in body_part1.Bodies:
            body1 = component1.FindOccurrence(protBodyObject)
            if body1 is None or body1.Layer > 256:
                continue

    bodies1[0] = body1
    bodyDumbRule1 = workPart.ScRuleFactory.CreateRuleBodyDumb(bodies1, True)
    scCollector1 = geometrySet1.ScCollector
    rules1 = [None] * 1 
    rules1[0] = bodyDumbRule1
    scCollector1.ReplaceRules(rules1, False)
    nXObject1 = millGeomBuilder1.Commit()
    millGeomBuilder1.Destroy()
    
    featureGeometry2 = nXObject1
    millGeomBuilder2 = workPart.CAMSetup.CAMGroupCollection.CreateMillGeomBuilder(featureGeometry2)
    millGeomBuilder2.BlankGeometry.InitializeData(False)
    geometrySetList2 = millGeomBuilder2.BlankGeometry.GeometryList
    #blankIpwSetList1 = millGeomBuilder2.BlankGeometry.BlankIpwMultipleSource.SetList #
    taggedObject2 = geometrySetList2.FindItem(0)
    geometrySet2 = taggedObject2
    #taggedObject3 = blankIpwSetList1.FindItem(0) #
    #blankIpwSet1 = taggedObject3 #

    # Set Blank Geometry
    if bounding==True:
        millGeomBuilder2.BlankGeometry.BlankDefinitionType = NXOpen.CAM.GeometryGroup.BlankDefinitionTypes.AutoBlock
        millGeomBuilder2.BlankGeometry.AutoBlockOffsetPositiveZ = 4.0
        millGeomBuilder2.BlankGeometry.AutoBlockOffsetPositiveY = 5.0
        millGeomBuilder2.BlankGeometry.AutoBlockOffsetPositiveX = 5.0
        millGeomBuilder2.BlankGeometry.AutoBlockOffsetNegativeX = 5.0
        millGeomBuilder2.BlankGeometry.AutoBlockOffsetNegativeY = 5.0
        millGeomBuilder2.BlankGeometry.AutoBlockOffsetNegativeZ = 6.0
        nXObject2 = millGeomBuilder2.Commit()
    
        featureGeometry3 = nXObject2
        millGeomBuilder3 = workPart.CAMSetup.CAMGroupCollection.CreateMillGeomBuilder(featureGeometry3)
        #millGeomBuilder3.BlankGeometry.BlankToggleValue = False # Hide Blank Bounding Box - uncomment for newer NX versions
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
        nXObject2 = millGeomBuilder2.Commit()
        millGeomBuilder2.Destroy()
    
        featureGeometry3 = nXObject2
        millGeomBuilder3 = workPart.CAMSetup.CAMGroupCollection.CreateMillGeomBuilder(featureGeometry3)
        
        nXObject3 = millGeomBuilder3.Commit()
        millGeomBuilder3.Destroy()

    # Add 6 Coordinate Systems
    CSadding(nXObject3, workPart, theSession)
    
   # Get Faces list
    FaceList=body1.GetFaces() # Get Faces list
    surfaceData = []
    selectedFaces = []
    
    # Get Faces Data
    for eachFace in FaceList:
        for each_feature in workPart.Features:
            pass
        stampValue = each_feature.Timestamp
        line = []
        line.append(eachFace) # Add Face object. Remove str conversion to work within sinlge script
        line.append(eachFace.Tag) # Add Face Tag
        props = theUfSession.Modeling.AskFaceData(eachFace.Tag) # There is also a AskFaceProps()
        faceUV = theUfSession.Modeling.AskFaceUvMinmax(eachFace.Tag) # Get surface u- and v- parameters
        line.append(props[0]) # Append NX surface type code
        line.append(props[1]) # Append surface point information
        line.append(props[2]) # Face Direction information 
        line.append(props[3]) # Face boundary information
        line.append(props[4]) # Face major radius
        line.append(props[5]) # Face minor radius - only for torus or cone
        line.append(props[6]) # Face normal direction
        line.append(faceUV) # Add the u,v parameter space min, max of a face. [0] - umin [1] - umax [2] - vmin [3] - vmax
        
        # Create list with excluded closed cylinders by cheking faces
        if props[0] == 16  and props[6] == -1: # Check for Cylindrical Faces and mark them red
            if faceUV[1] - faceUV [0] < 2*math.pi:
                selectedFaces.append(eachFace)
            else: 
                pass
        elif props[0] == 17  and props[6] == -1: # Check for Conical Faces and mark them red
            if faceUV[1] - faceUV [0] < 2*math.pi:
                selectedFaces.append(eachFace)
            else:
                pass
        else:
            selectedFaces.append(eachFace)

        # Measure face
        scCollector1 = workPart.ScCollectors.CreateCollector()
        scCollector1.SetMultiComponent()
        #selectionIntentRuleOptions1 = workPart.ScRuleFactory.CreateRuleOptions()
        #selectionIntentRuleOptions1.SetSelectedFromInactive(False)
        faces1 = [NXOpen.Face.Null] * 1 
        faces1[0] = eachFace
        faceDumbRule1 = workPart.ScRuleFactory.CreateRuleFaceDumb(faces1)
        #faceDumbRule1 = workPart.ScRuleFactory.CreateRuleFaceDumb(faces1, selectionIntentRuleOptions1)
        #selectionIntentRuleOptions1.Dispose()
        rules1 = [None] * 1 
        rules1[0] = faceDumbRule1
        scCollector1.ReplaceRules(rules1, False)
        measureMaster = workPart.MeasureManager.MasterMeasurement()
        measureMaster.SequenceType = NXOpen.MeasureMaster.Sequence.Free
        #measureMaster.UpdateAtTimestamp = True
        measureMaster.SetNameSuffix("Face")
        faceUnits1 = [NXOpen.Unit.Null] * 5 
        unit1 = workPart.UnitCollection.FindObject("SquareMilliMeter")
        faceUnits1[0] = unit1
        unit2 = workPart.UnitCollection.FindObject("MilliMeter")
        faceUnits1[1] = unit2
        faceUnits1[2] = unit2
        faceUnits1[3] = unit2
        faceUnits1[4] = unit2
        measureElement1 = workPart.MeasureManager.FacePropertiesElement(measureMaster, faceUnits1, 0, True, 0.98999999999999999, scCollector1)
        measureElement1.MeasureObject1 = NXOpen.MeasureElement.Measure.Object
        measureElement1.SetExpressionState(0, True)
        measureElement1.SetExpressionState(1, True)
        measureElement1.SetExpressionState(2, True)
        measureElement1.SetExpressionState(3, True)
        measureElement1.SetExpressionState(4, True)
        measureElement1.SetExpressionState(5, True)
        markId5 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "Measurement Update")
        nErrs4 = theSession.UpdateManager.DoUpdate(markId5)

        # Collect Measure information from Expressions tab
        theLw.Open()
        for exp in workPart.Expressions:
            search_line =str(stampValue+1)+") centroid)" # Search For Centroids Data
            if str(search_line) in str(exp.Description):
                CGpoint = []
                CGpoint.append(exp.PointValue.X)
                CGpoint.append(exp.PointValue.Y)
                CGpoint.append(exp.PointValue.Z)
                line.append(CGpoint)
        theLw.Close()
        
        # add collected data to main list
        surfaceData.append(line)

    # Find Features
    markId46 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Visible, "Start")
    featureRecognitionBuilder1 = workPart.CAMSetup.CreateFeatureRecognitionBuilder(NXOpen.CAM.CAMObject.Null)
    manualFeatureBuilder1 = featureRecognitionBuilder1.CreateManualFeatureBuilder()
    featureRecognitionBuilder1.AssignColor = False
    featureRecognitionBuilder1.AddCadFeatureAttributes = False
    featureRecognitionBuilder1.MapFeatures = False
    theSession.SetUndoMarkName(markId46, "Find Features Dialog")
    featureRecognitionBuilder1.RecognitionType = NXOpen.CAM.FeatureRecognitionBuilder.RecognitionEnum.Parametric
    featureRecognitionBuilder1.UseFeatureNameAsType = True 
    featureRecognitionBuilder1.IgnoreWarnings = False
    vecdirections1 = []
    featureRecognitionBuilder1.SetMachiningAccessDirection(vecdirections1, 0.0)
    
    # Features List   
    featureRecognitionBuilder1.SetFeatureTypes(features_data)
    featureRecognitionBuilder1.GeometrySearchType = NXOpen.CAM.FeatureRecognitionBuilder.GeometrySearch.Workpiece
    features1 = featureRecognitionBuilder1.FindFeatures()
    nXObject10 = featureRecognitionBuilder1.Commit()
    featureRecognitionBuilder1.Destroy()
    manualFeatureBuilder1.Destroy()
    
    # Collect all feature faces
    currentFeatureFaces = []
    allFeatureFaces = []
    for eachFeature in features1:
        currentFeatureFaces = eachFeature.GetFaces()
        for eachFeautureFace in currentFeatureFaces:
            allFeatureFaces.append(eachFeautureFace)
    
    # Get Non-feature Faces
    #otherFaces = [x for x in FaceList if x not in allFeatureFaces]
    otherFaces = selectedFaces

    # Add Cavity Mill Operations
    markCavity = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "Create Cavity Mill Operations [FBM AUTO]")
    
    # Cavity Mill Rough
    programGroup = workPart.CAMSetup.CAMGroupCollection.FindObject("PROGRAM")
    method = workPart.CAMSetup.CAMGroupCollection.FindObject("METHOD")
    nCMethod = workPart.CAMSetup.CAMGroupCollection.CreateMethod(method, "mill_contour", "MILL_ROUGH", 
                                                                 NXOpen.CAM.NCGroupCollection.UseDefaultName.TrueValue, "MILL_ROUGH")
    
    methodType = workPart.CAMSetup.CAMGroupCollection.FindObject("MILL_ROUGH")
    tool = workPart.CAMSetup.CAMGroupCollection.FindObject("NONE")
    orientGeometry = workPart.CAMSetup.CAMGroupCollection.FindObject("MCS_TOP")
    operation = workPart.CAMSetup.CAMOperationCollection.Create(programGroup, methodType, tool, orientGeometry, "mill_contour", "CAVITY_MILL", 
                                                                NXOpen.CAM.OperationCollection.UseDefaultName.FalseValue, "CAVITY_MILL_ROUGH")
    cMB1 = workPart.CAMSetup.CAMOperationCollection.CreateCavityMillingBuilder(operation)
    
    # Initialize
    isupdated = cMB1.CutLevel.InitializeData()
    cMB1.CutParameters.UseToolHolder = True
    cMB1.CutParameters.CheckIpwCollisions = True
    cMB1.CutParameters.CutBelowOverhangingBlank = False
    cMB1.CutParameters.IpwType = NXOpen.CAM.CutParametersIpwTypes.ThreeDimension
    cMB1.CutParameters.SmallAreaAvoidance.SmallAreaStatus = NXOpen.CAM.SmallAreaAvoidance.StatusTypes.Ignore
    cMB1.CutParameters.SmallAreaAvoidance.AreaSize.Value = 300.0
    cMB1.CutParameters.CornerControl.SmoothingOption = NXOpen.CAM.CornerControlBuilder.SmoothingOptions.AllPasses
    cMB1.BndStepover.PercentToolFlatBuilder.Value = 49.0
    cMB1.CutParameters.CornerControl.FilletingRadius.Value = 49.0
    # ----------------------------------------------------------------------    
    # Cavity Mill Finish
    nCMethod = workPart.CAMSetup.CAMGroupCollection.CreateMethod(method, "mill_contour", "MILL_FINISH",
                                                                 NXOpen.CAM.NCGroupCollection.UseDefaultName.TrueValue, "MILL_FINISH")
    
    methodType = workPart.CAMSetup.CAMGroupCollection.FindObject("MILL_FINISH")
    operation = workPart.CAMSetup.CAMOperationCollection.Create(programGroup, methodType, tool, orientGeometry, "mill_contour", "CAVITY_MILL",
                                                                NXOpen.CAM.OperationCollection.UseDefaultName.FalseValue, "CAVITY_MILL_FINISH")
    
    cMB2 = workPart.CAMSetup.CAMOperationCollection.CreateCavityMillingBuilder(operation)
    
    # Initialize
    isupdated1 = cMB2.CutLevel.InitializeData()
    cMB2.CutParameters.UseToolHolder = True
    cMB2.CutParameters.CheckIpwCollisions = True
    cMB2.CutParameters.CutBelowOverhangingBlank = False
    cMB2.CutParameters.SmallAreaAvoidance.SmallAreaStatus = NXOpen.CAM.SmallAreaAvoidance.StatusTypes.Ignore
    cMB2.CutParameters.SmallAreaAvoidance.AreaSize.Value = 300.0
    cMB2.BndStepover.PercentToolFlatBuilder.Value = 49.0 
    cMB2.CutParameters.CornerControl.SmoothingOption = NXOpen.CAM.CornerControlBuilder.SmoothingOptions.AllButLastPass
    cMB2.CutParameters.CornerControl.FilletingRadius.Value = 49.0
    cMB2.CutParameters.IpwType = NXOpen.CAM.CutParametersIpwTypes.ThreeDimension
    
    # ----------------------------------------------------------------------    
    # Rest Mill Rough
    orientGeometry = workPart.CAMSetup.CAMGroupCollection.FindObject("MCS_DOWN")
    methodType = workPart.CAMSetup.CAMGroupCollection.FindObject("MILL_ROUGH")
    operation = workPart.CAMSetup.CAMOperationCollection.Create(programGroup, methodType, tool, orientGeometry, "mill_contour", "REST_MILLING", NXOpen.CAM.OperationCollection.UseDefaultName.FalseValue, "REST_MILLING_ROUGH")
    cMB3 = workPart.CAMSetup.CAMOperationCollection.CreateCavityMillingBuilder(operation)
   
    # Initialize  
    isupdated = cMB3.CutLevel.InitializeData()
    cMB3.CutParameters.UseToolHolder = True
    cMB3.CutParameters.CheckIpwCollisions = True
    cMB3.CutParameters.CutBelowOverhangingBlank = False
    cMB3.CutParameters.SmallAreaAvoidance.SmallAreaStatus = NXOpen.CAM.SmallAreaAvoidance.StatusTypes.Ignore
    cMB3.CutParameters.SmallAreaAvoidance.AreaSize.Value = 300.0
    cMB3.BndStepover.PercentToolFlatBuilder.Value = 49.0 
    cMB3.CutParameters.CornerControl.SmoothingOption = NXOpen.CAM.CornerControlBuilder.SmoothingOptions.AllPasses
    cMB3.CutParameters.CornerControl.FilletingRadius.Value = 49.0
    cMB3.CutParameters.IpwType = NXOpen.CAM.CutParametersIpwTypes.ThreeDimension
    # ----------------------------------------------------------------------    
    # Rest Mill Finish
    methodType = workPart.CAMSetup.CAMGroupCollection.FindObject("MILL_FINISH")
    operation = workPart.CAMSetup.CAMOperationCollection.Create(programGroup, methodType, tool, orientGeometry, "mill_contour", "REST_MILLING", NXOpen.CAM.OperationCollection.UseDefaultName.FalseValue, "REST_MILLING_FINISH")
    cMB4 = workPart.CAMSetup.CAMOperationCollection.CreateCavityMillingBuilder(operation)
   
    # Initialize  
    isupdated = cMB4.CutLevel.InitializeData()
    cMB4.CutParameters.UseToolHolder = True
    cMB4.CutParameters.CheckIpwCollisions = True
    cMB4.CutParameters.CutBelowOverhangingBlank = False
    cMB4.CutParameters.SmallAreaAvoidance.SmallAreaStatus = NXOpen.CAM.SmallAreaAvoidance.StatusTypes.Ignore
    cMB4.CutParameters.SmallAreaAvoidance.AreaSize.Value = 300.0
    cMB4.BndStepover.PercentToolFlatBuilder.Value = 49.0 
    cMB4.CutParameters.CornerControl.SmoothingOption = NXOpen.CAM.CornerControlBuilder.SmoothingOptions.AllButLastPass
    cMB4.CutParameters.CornerControl.FilletingRadius.Value = 49.0
    cMB4.CutParameters.IpwType = NXOpen.CAM.CutParametersIpwTypes.ThreeDimension

    ####
    # Create Feature Process
    featureProcessBuilder1 = workPart.CAMSetup.CreateFeatureProcessBuilder()
    featureProcessBuilder1.Type = NXOpen.CAM.FeatureProcessBuilder.FeatureProcessType.RuleBased
    featureProcessBuilder1.SetGeometryLocation("PROGRRAM")
    featureProcessBuilder1.FeatureGrouping = NXOpen.CAM.FeatureProcessBuilder.FeatureGroupingType.UseExisting

    # Selected Processes
    featureProcessBuilder1.SetRuleLibraries(operations_data) # set operations from excel sheet library 
    operations1, featureProcessBuilderStatus1 = featureProcessBuilder1.CreateFeatureProcesses(features1)
    result1 = featureProcessBuilderStatus1.GetResultStatus()
    featureProcessBuilderStatus1.Dispose()
    featureProcessBuilder1.Destroy()
    theSession.CleanUpFacetedFacesAndEdges()
    
    # Get all faces from successfully processed features -------------------------------------------------------------------------------------
    currentFeatureFaces = []
    processed_feature_faces = []
    for each_feature in features1:
        if each_feature.GetGroups():
            currentFeatureFaces = each_feature.GetFaces()
            for eachFeautureFace in currentFeatureFaces:
                processed_feature_faces.append(eachFeautureFace)

    otherFaces = [x for x in FaceList if x not in processed_feature_faces]
    
    # Paste Selected Faces to Cavity Mill Operation
    """
    cMB1.CutAreaGeometry.InitializeData(False)
    geometrySetList = cMB1.CutAreaGeometry.GeometryList
    geometrySet = geometrySetList.FindItem(0)

    faces = [NXOpen.Face.Null] * len(otherFaces) 
    for x in range(len(otherFaces)):
        faces[x] = otherFaces[x]
    faceDumbRule1 = workPart.ScRuleFactory.CreateRuleFaceDumb(faces)
    scCollector = geometrySet.ScCollector
    rules1 = [None] * 1 
    rules1[0] = faceDumbRule1
    scCollector.ReplaceRules(rules1, False)
    """
    # Commit Cavity Mill Rough
    nXObject1 = cMB1.Commit()
    
    # Select Tool
    topZ = cMB1.CutLevel.TopZc
    chopedData = [x for x in surfaceData if x[0] not in processed_feature_faces]
    tool_library = create_tool_library(tools_data)
    rads = find_radi(chopedData)
    #_print("Top Z:"+str(topZ)+" Radius: "+str(rads[1]*4*1.125))
    rough_tool = tool_finder(tool_library, "2", "1", topZ, rads[1]*4*1.125) # tool library var, T value, ST value, Flute length >=, Diameter <=
    finish_tool = tool_finder(tool_library, "2", "1", topZ, rads[1]*2)

    # Paste Tool
    try:
        tool1 = workPart.CAMSetup.CAMGroupCollection.FindObject(rough_tool)
    except:
        tool1, success1 = workPart.CAMSetup.RetrieveTool(rough_tool)

    objectsToBeMoved1 = [NXOpen.CAM.CAMObject.Null] * 1 
    cavityMilling2 = nXObject1
    objectsToBeMoved1[0] = cavityMilling2
    workPart.CAMSetup.MoveObjects(NXOpen.CAM.CAMSetup.View.MachineTool, objectsToBeMoved1, tool1, NXOpen.CAM.CAMSetup.Paste.Inside)    
    
    # Destroy
    cMB1.Destroy()

     # End for Cavity Mill Finish ---------------------------------------------------------------------------------------------------
    # Paste Desired Faces to Cavity Mill Operation
    cMB2.CutAreaGeometry.InitializeData(False)
    geometrySetList = cMB2.CutAreaGeometry.GeometryList
    geometrySet = geometrySetList.FindItem(0)
    
    faces = [NXOpen.Face.Null] * len(otherFaces) 
    for x in range(len(otherFaces)):
        faces[x] = otherFaces[x]
    faceDumbRule1 = workPart.ScRuleFactory.CreateRuleFaceDumb(faces)
    scCollector = geometrySet.ScCollector
    rules1 = [None] * 1 
    rules1[0] = faceDumbRule1
    scCollector.ReplaceRules(rules1, False)

    # Commit
    nXObject1 = cMB2.Commit()

    # Paste Tool
    try:
        tool2 = workPart.CAMSetup.CAMGroupCollection.FindObject(finish_tool)
    except:
        tool2, success2 = workPart.CAMSetup.RetrieveTool(finish_tool)

    objectsToBeMoved1 = [NXOpen.CAM.CAMObject.Null] * 1 
    cavityMilling2 = nXObject1
    objectsToBeMoved1[0] = cavityMilling2
    workPart.CAMSetup.MoveObjects(NXOpen.CAM.CAMSetup.View.MachineTool, objectsToBeMoved1, tool2, NXOpen.CAM.CAMSetup.Paste.Inside)   
    
    # Destroy
    cMB2.Destroy() 
    
    # End for Rest Milling Rough ---------------------------------------------------------------------
    # Paste Selected Faces to Resit Mill Rough Operation
    cMB3.CutAreaGeometry.InitializeData(False)
    geometrySetList = cMB3.CutAreaGeometry.GeometryList
    geometrySet = geometrySetList.FindItem(0)
    
    faces = [NXOpen.Face.Null] * len(otherFaces) 
    for x in range(len(otherFaces)):
        faces[x] = otherFaces[x]
    faceDumbRule1 = workPart.ScRuleFactory.CreateRuleFaceDumb(faces)
    scCollector = geometrySet.ScCollector
    rules1 = [None] * 1 
    rules1[0] = faceDumbRule1
    scCollector.ReplaceRules(rules1, False)

    # Commit
    nXObject3 = cMB3.Commit()

    # Paste Tool
    objectsToBeMoved1 = [NXOpen.CAM.CAMObject.Null] * 1 
    cavityMilling3 = nXObject3
    objectsToBeMoved1[0] = cavityMilling3
    workPart.CAMSetup.MoveObjects(NXOpen.CAM.CAMSetup.View.MachineTool, objectsToBeMoved1, tool1, NXOpen.CAM.CAMSetup.Paste.Inside)   
    
    # Destroy
    cMB3.Destroy()

    # End for Rest Milling Finish -------------------------------------------------------------------
    # Paste Selected Faces to Rest Mill Rough Operation
    cMB4.CutAreaGeometry.InitializeData(False)
    geometrySetList = cMB4.CutAreaGeometry.GeometryList
    geometrySet = geometrySetList.FindItem(0)
    
    faces = [NXOpen.Face.Null] * len(otherFaces) 
    for x in range(len(otherFaces)):
        faces[x] = otherFaces[x]
    faceDumbRule1 = workPart.ScRuleFactory.CreateRuleFaceDumb(faces)
    scCollector = geometrySet.ScCollector
    rules1 = [None] * 1 
    rules1[0] = faceDumbRule1
    scCollector.ReplaceRules(rules1, False)
    
    # Commit
    nXObject4 = cMB4.Commit()
    
    # Paste Tool
    objectsToBeMoved1 = [NXOpen.CAM.CAMObject.Null] * 1 
    cavityMilling4 = nXObject4
    objectsToBeMoved1[0] = cavityMilling4
    workPart.CAMSetup.MoveObjects(NXOpen.CAM.CAMSetup.View.MachineTool, objectsToBeMoved1, tool2, NXOpen.CAM.CAMSetup.Paste.Inside)

    # Destroy
    cMB4.Destroy()

    # Creature Setup Folders and remove empty ones
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

    # Remove groups
    stage2 = workPart.CAMSetup.CAMOperationCollection.FindObject("PROGRAM")
    objects_at_2 = NXOpen.CAM.NCGroup.GetMembers(stage2)
    remove_list = _grop_remover(objects_at_2, workPart)
    if not remove_list:
        pass
        #_print("No Empty Folders") 
    else:
        for i in range(len(remove_list)):
            objectsToBeDeleted = [NXOpen.TaggedObject.Null] * 1
            objectsToBeDeleted[0] = workPart.CAMSetup.CAMOperationCollection.FindObject(remove_list[i]) 
            nErrs1 = theSession.UpdateManager.AddObjectsToDeleteList(objectsToBeDeleted)       
        nErrs2 = theSession.UpdateManager.DoUpdate(id1)

    # Save file
    partSave = workPart.Save(NXOpen.BasePart.SaveComponents.TrueValue, NXOpen.BasePart.CloseAfterSave.FalseValue)
    #partSaveStatus1 = workPart.SaveAs(Output_path+"\\Computed_Assembly.prt")
    partSave.Dispose()
      
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
    
    featureGeometry4 = nXObject3
    nCGroup1 = workPart.CAMSetup.CAMGroupCollection.CreateGeometry(featureGeometry4, "mill_planar", "MCS", NXOpen.CAM.NCGroupCollection.UseDefaultName.FalseValue, "MCS_TOP")
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
    toolaxismode2 = millOrientGeomBuilder1.GetToolAxisMode()
    millOrientGeomBuilder1.SetToolAxisMode(NXOpen.CAM.OrientGeomBuilder.ToolAxisModes.PositiveZOfMcs)
    nXObject4 = millOrientGeomBuilder1.Commit()
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
    
    # ----------------------------------------------
    #   Menu: Insert->Geometry...
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
    op_data['Toolpath Cutting Length'] = str(obj.GetToolpathCuttingLength())
    op_data['Operation Description'] = str(obj.GetStringValue("Template Subtype"))
    if str(obj.GetStringValue("Template Subtype")) in {"CAVITY_MILL", "REST_MILLING"}:
        parent_feature = obj.GetParent(NXOpen.CAM.CAMSetup.View.Geometry)
        if "MCS_" in str(parent_feature.Name):
            op_data['MCS']= str(parent_feature.Name)
        else:
            orient = parent_feature.GetParent()
            op_data['MCS'] = str(orient.Name)    
    else:
        parent_feature = obj.GetParent(NXOpen.CAM.CAMSetup.View.Geometry) 
        orient = parent_feature.GetParent()
        op_data['MCS'] = str(orient.Name)
    return op_data

def _grop_remover(objects_at_start, workPart):
    
    remove_group_list = []

    for each_object in objects_at_start:
        if workPart.CAMSetup.IsGroup(each_object) == True:
            if not "SETUP_" in each_object.Name:
                remove_group_list.append(each_object.Name)
            #_print(str(each_object.Name))
    return(remove_group_list)

def tool_finder(tool_library, t_T, t_ST, t_FluteLength, t_Diameter):
    sorted_tools = []
    search_data = []
    for each_line in tool_library:
        if each_line[4] == t_T and each_line[5] == t_ST:
            if each_line[6] >= t_FluteLength and each_line[7] == t_Diameter:
                search_data.append(each_line)
    if not search_data:
        for each_line in tool_library:
            if each_line[4] == t_T and each_line[5] == t_ST:
                if each_line[6] >= t_FluteLength and each_line[7] <= t_Diameter:
                    search_data.append(each_line)
    if not search_data:
        for each_line in tool_library:
            if each_line[4] == t_T and each_line[5] == t_ST:
                if each_line[6] <= t_FluteLength and each_line[7] <= t_Diameter:
                    search_data.append(each_line)            
    
    sorted_tools=sorted(search_data, key=operator.itemgetter(7,6), reverse=True)
    if sorted_tools:
        return(sorted_tools[0][0])
    else:
        print("\nERROR\nNo matching tools found!")

def create_tool_library(tool_data):
    tool_library = []
    for each_tool in tool_data:
        tool_line = []
        buff = tool_data[each_tool]
        tool_line.append(each_tool) # add tool Name,
        tool_line.append(buff[0]) # Speed,
        tool_line.append(buff[1]) # Feed,
        tool_line.append(buff[2]) # Depth,
        tool_line.append(buff[3]) # T - type,
        tool_line.append(buff[4]) # ST - subtype,
        if buff[5] != '':
            tool_line.append(float(buff[5])) # FLEN - flut length,
        if buff[6] != '':
            tool_line.append(float(buff[6])) # DIA - tool diameter
        tool_library.append(tool_line)
    return(tool_library)

def find_radi(surface_data):
    cylinders_data = []
    # Get cylinders
    for x in surface_data:
        if x[2] == 16: # NX surface type code 16 = cylinder 17 = cone 18 = sphere 19 = revolved (toroidal)
                    # 20 = extruded 22 = bounded plane 23 = fillet (blend) 43 = b-surface 65 = offset surface 66 = foreign surface 
            cylinders_data.append(x)

    sorted_surface = sorted(cylinders_data,key=operator.itemgetter(6), reverse=True)

    max_rad = round(sorted_surface[0][6],1) # get max surface curvature radius
    min_rad = round(sorted_surface[-1][6],1) # get min surface curvature radius
    return(max_rad, min_rad) 
     
main()