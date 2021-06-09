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
import json
from pathlib import Path

def main(): 
    program_folder = os.path.abspath('')
    theSession = NXOpen.Session.GetSession()
    theSession.Parts.LoadOptions.UsePartialLoading = False
    displayPart = theSession.Parts.Display
    if displayPart is None:
        displayPart, loadStatus = theSession.Parts.OpenDisplay(r"-@file_path@-")
    workPart = theSession.Parts.Work
    theUfSession = NXOpen.UF.UFSession.GetUFSession()
    theLw = theSession.ListingWindow
    outputFilePath = program_folder + '\\output\\' + str(displayPart.Name)
    outputJson = program_folder + '\\resources\\json\\parts.txt'
    a = ''
    b = 0
    while True:
        try:
            Path(outputFilePath+a).mkdir(parents=True, exist_ok=False)
            break
        except:
            a = '_'
            b += 1
            a = a+str(b)
    
    outputFilePath = outputFilePath+a

    assembly_components = []
    part_var = []
    blank_var = []
    single_part = False

    # Check assebmly or single file
    theLw.Open()
    try:
        comps = displayPart.ComponentAssembly.RootComponent.GetChildren() # initialize list to hold components
        for x in comps:
            #theLw.WriteLine(x.DisplayName)
            assembly_components.append(x.DisplayName)
        # _print(assembly_components) # Uncomment to check assembly parts list

        part_var = [s for s in assembly_components if "_Part" in s or "_part" in s]

        if not part_var:
            part_var.append(str(displayPart.Name)) 
    except:
        part_var.append(str(displayPart.Name))
        single_part = True
    theLw.Close()

    asmPath = displayPart.FullPath

    fileClone = NXOpen.UF.Clone()
    fileClone.Terminate()  
    fileClone.Initialise(NXOpen.UF.Clone.OperationClass.CLONE_OPERATION)
    fileClone.SetDefNaming(NXOpen.UF.Clone.NamingTechnique.NAMING_RULE)
    fileClone.SetDefDirectory(outputFilePath)
    
    if single_part == True:
        fileClone.AddPart(asmPath)
    else:
        fileClone.AddAssembly(asmPath)

    nameRule = NXOpen.UF.Clone.NameRuleDef()
    nameRule.Type = NXOpen.UF.Clone.NameRuleType.PREPEND_STRING
    nameRule.BaseString = ""
    nameRule.NewString = "AutoCAM_"

    nf = fileClone.InitNamingFailures()
    fileClone.SetNameRule(nameRule,nf)
    fileClone.SetDryrun(False)
    fileClone.PerformClone(nf)
    fileClone.Terminate()    

    data = []
    data.append(outputFilePath)
    data.append("AutoCAM_"+str(displayPart.Name))
    # Create Json file
    
    with open(outputJson, 'w') as result_file:
        json.dump(data, result_file)

def _print(message):
   
    NXOpen.UI.GetUI().NXMessageBox.Show("Print Message",NXOpen.NXMessageBox.DialogType.Information,str(message))

if __name__ == '__main__':
    main()