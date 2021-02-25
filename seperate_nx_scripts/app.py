# NX 1915
# Journal created by vyacheslav on Fri Jan  8 17:54:23 2021 RTZ 2 (зима)

#
import math
import NXOpen
import NXOpen.CAM
def main() : 

    theSession  = NXOpen.Session.GetSession()
    workPart = theSession.Parts.Work
    displayPart = theSession.Parts.Display
    theUI = NXOpen.UI.GetUI()
    
    theSession.CAMSession.PathDisplay.HideToolPath(theUI.SelectionManager.GetSelectedTaggedObject(0))
    
    holeDrilling1 = workPart.CAMSetup.CAMOperationCollection.FindObject("DRILL_IN_CENTER_S1P_1")
    theSession.CAMSession.PathDisplay.ShowToolPath(holeDrilling1)
    
    markId1 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Visible, "Edit DRILL_IN_CENTER_S1P_1")
    
    markId2 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "Start")
    
    holeDrillingBuilder1 = workPart.CAMSetup.CAMOperationCollection.CreateHoleDrillingBuilder(holeDrilling1)
    
    cycleDwell1 = holeDrillingBuilder1.CycleTable.DwellAtDepth
    
    cycleDwell2 = holeDrillingBuilder1.CycleTable.DwellAtStartPoint
    
    cycleDwell3 = holeDrillingBuilder1.CycleTable.DwellAtFinalDepth
    
    cycleDwell4 = holeDrillingBuilder1.CycleTable.DwellBeforeEngage
    
    cycleDwell5 = holeDrillingBuilder1.CycleTable.DwellBeforeCut
    
    cycleDwell6 = holeDrillingBuilder1.CycleTable.DwellBeforeRetract
    
    cycleStepRetract1 = holeDrillingBuilder1.CycleTable.StepRetract
    
    cycleNodragClearance1 = holeDrillingBuilder1.CycleTable.NodragClearance
    
    cycleSpindle1 = holeDrillingBuilder1.CycleTable.SpindleBeforeEngage
    
    cycleSpindle2 = holeDrillingBuilder1.CycleTable.SpindleBeforeRetract
    
    cycleCoolant1 = holeDrillingBuilder1.CycleTable.CoolantBeforeEngage
    
    cycleCoolant2 = holeDrillingBuilder1.CycleTable.CoolantBeforeCut
    
    cycleCoolant3 = holeDrillingBuilder1.CycleTable.CoolantBeforeRetract
    
    cycleTipRelease1 = holeDrillingBuilder1.CycleTable.TipRelease
    
    holeDrillingBuilder1.CycleTable.AxialStepover.StepoverType = NXOpen.CAM.StepoverBuilder.StepoverTypes.NotSet
    
    holeMachiningCutParameters1 = holeDrillingBuilder1.CuttingParameters
    
    origin1 = NXOpen.Point3d(0.0, 0.0, 0.0)
    normal1 = NXOpen.Vector3d(0.0, 0.0, 1.0)
    plane1 = workPart.Planes.CreatePlane(origin1, normal1, NXOpen.SmartObject.UpdateOption.AfterModeling)
    
    unit1 = workPart.UnitCollection.FindObject("MilliMeter")
    expression1 = workPart.Expressions.CreateSystemExpressionWithUnits("0", unit1)
    
    expression2 = workPart.Expressions.CreateSystemExpressionWithUnits("0", unit1)
    
    holeDrillingCutParameters1 = holeMachiningCutParameters1
    verticalPosition1 = holeDrillingCutParameters1.BottomOffset
    
    verticalPosition2 = holeDrillingCutParameters1.RaptoOffset
    
    theSession.SetUndoMarkName(markId2, "Drilling - [DRILL_IN_CENTER_S1P_1] Dialog")
    
    holeDrillingBuilder1.CycleTable.AxialStepover.StepoverType = NXOpen.CAM.StepoverBuilder.StepoverTypes.NotSet
    
    holeDrillingBuilder1.FeedsBuilder.SurfaceSpeedBuilder.Value = 1.5
    
    holeDrillingBuilder1.FeedsBuilder.RecalculateData(NXOpen.CAM.FeedsBuilder.RecalcuateBasedOn.SurfaceSpeed)
    
    holeDrillingBuilder1.FeedsBuilder.FeedPerToothBuilder.Value = 0.90000000000000002
    
    holeDrillingBuilder1.FeedsBuilder.RecalculateData(NXOpen.CAM.FeedsBuilder.RecalcuateBasedOn.FeedPerTooth)
    
    markId3 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "Drilling - [DRILL_IN_CENTER_S1P_1]")
    
    theSession.DeleteUndoMark(markId3, None)
    
    markId4 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Invisible, "Drilling - [DRILL_IN_CENTER_S1P_1]")
    
    nXObject1 = holeDrillingBuilder1.Commit()
    
    theSession.DeleteUndoMark(markId4, None)
    
    theSession.SetUndoMarkName(markId2, "Drilling - [DRILL_IN_CENTER_S1P_1]")
    
    holeDrillingBuilder1.Destroy()
    
    try:
        # Expression is still in use.
        workPart.Expressions.Delete(expression2)
    except NXOpen.NXException as ex:
        ex.AssertErrorCode(1050029)
        
    try:
        # Expression is still in use.
        workPart.Expressions.Delete(expression1)
    except NXOpen.NXException as ex:
        ex.AssertErrorCode(1050029)
        
    plane1.DestroyPlane()
    
    theSession.DeleteUndoMark(markId2, None)
    
    markId5 = theSession.SetUndoMark(NXOpen.Session.MarkVisibility.Visible, "Generate Tool Paths")
    
    objects1 = [NXOpen.CAM.CAMObject.Null] * 1 
    holeDrilling2 = nXObject1
    objects1[0] = holeDrilling2
    workPart.CAMSetup.GenerateToolPath(objects1)
    
    # ----------------------------------------------
    #   Menu: Tools->Journal->Stop Recording
    # ----------------------------------------------
    
if __name__ == '__main__':
    main()