import NXOpen
import NXOpen.UF
import NXOpen.CAM
import NXOpen.Assemblies
import json
import os

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
    id1 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Visible, "FBM GENERATE TOOL PATH")
    
    # Initialize CAM setup and session
    try:
        theSession.ApplicationSwitchImmediate("UG_APP_MANUFACTURING")
        CAM_Setup_Build = workPart.CreateCamSetup("mill_planar") # initialize cam_setup
        theSession.CAMSession.SpecifyConfiguration("${UGII_CAM_CONFIG_DIR}cam_general")
        kinematicConfigurator1 = workPart.CreateKinematicConfigurator()
    except: 
        pass 

    # Generate Tool Path
    NCobjects = [NXOpen.CAM.CAMObject.Null] * 1 
    NCobjects[0] = workPart.CAMSetup.CAMGroupCollection.FindObject("PROGRAM")
    workPart.CAMSetup.GenerateToolPath(NCobjects)

    # Save file
    partSave = workPart.Save(NXOpen.BasePart.SaveComponents.TrueValue, NXOpen.BasePart.CloseAfterSave.FalseValue)
    partSave.Dispose()
      

def _print(message):
  NXOpen.UI.GetUI().NXMessageBox.Show("Print Message",NXOpen.NXMessageBox.DialogType.Information,str(message))

main()