import pandas as pd
import os

program_folder = os.path.abspath('')
Tools_table = program_folder + '\spreadsheets\Tool_library.xlsx' # Path to read desired tool Excel file
Default_Tool_bat = program_folder + '\\resources\default\\default_tool_database.dat'# Path to default tool database
Generated_Tool_bat = program_folder + '\\\output\\generated_tool_database.dat'# Path to generated tool database

def read_tools():
    workbook = pd.read_excel(Tools_table, dtype=str) # open excel tool table
    workbook.fillna("", inplace = True)

    with open(Default_Tool_bat, 'r') as file:
        text = file.read().split('\n')
        #print(type(text))
    for row in workbook.itertuples():
        if row[1]=='1':
            text = tool_class_selector(row, text)
        else:
            print('No tools were selected in the sheet')
    A = ''
    for i in range(len(text)):
        A += str(text[i]) + '\n'
       # print(str(text[i]) + '\n')
    
    with open(Generated_Tool_bat,'w') as outfile:
        outfile.write(A)
    ("\n-------- Tool Database Created --------\n")

def tool_class_selector(row, text):
    Title = [ 'LIBRF', 'T', 'ST', 'UGT', 'UGST', 'DESCR', 'MATREF', 'MATDES', 'TLNUM', 'ADJREG', 'CUTCOMREG', \
              'HLD', 'HLDDES', 'DIA', 'FN', 'HEI', 'ZOFF', 'DROT', 'FLEN', 'TAPA', 'TIPA', 'COR1', 'CTH', 'HOFF', \
              'ZMOUNT', 'RIGID', 'TSDIA', 'TSLEN', 'TSTLEN', 'RAMPANGLE', 'HELICALDIA', 'MINRAMPLEN', 'MAXCUTWIDTH', \
              'HLDREF', 'TPREF', 'HA', 'DESI',	'TURRETROT', 'INDXNTCH', 'HANGLE', 'YMOUNT', 'XMOUNT', 'RL', \
              'MXTR', 'MXFD', 'MNFD', 'RYOFF', 'MNBD', 'RXOFF', 'LYOFF', 'INSP', 'TP', 'LXOFF', 'ND', 'OA', 'THRDS', 'THCK', \
              'DIA2', 'PD', 'SDIA',	'THRDES', 'UCOR', 'IT', 'PNTA',	'LCOR',	'NOSA', 'NOSR',	'NTD', 'NTL', 'NL',	'SDIST', 'IW', \
              'IL',	'PIT',	'COR',	'PNTL',	'TIPLEN', 'PL',	'CLEN',	'LSA',	'RW', 'LA',	'FIL', 'COR2', 'MXDP', 'IC', 'IA', 'BRAD', \
              'RELA', 'THCT', 'RSA', 'YOFF', 'XOFF', 'RELT', 'BIL', 'FDIA', 'MINP', 'EDIA', 'IEA', 'IEL', 'NOSW', 'FDIS', 'RA', \
              'BTDIA', 'IS', 'MHD',	'D2', 'CHAMFERLEN',	'YCEN',	'WRANG', 'CX1',	'CY1',	'CX2',	'CY2',	'INCA',	'BANG',	'BDIA',	\
              'TDD', 'PSET', 'MINW', 'MAXP', 'MAXH', 'WDIA', 'MINER', 'WRANGE',	'MAXER', 'NOD',	'TOFF',	'RAD',	'BTHA',	'BTHW',	\
              'MAXW', 'MINH', 'SD', 'RD']
    
    DATA = {}
    
    for x in range(len(Title)):
        DATA[Title[x]] = row[x+4]
    
    # Shortcuts:
    t=row[5]
    st=row[6]

    # Operations: 
    # Milling
    if t=='02' and st=='01': # End Mills Non-indexable
        line = text.index('#CLASS END_MILL_NON_INDEXABLE')
        text = insert_that_row(text, DATA, n_=line)
        return text
                
    elif t=='02' and st=='02': # End Mills Indexable 
        line = text.index('#CLASS END_MILL_INDEXABLE')
        text = insert_that_row(text, DATA, n_=line)
        return text

    elif t=='02' and st=='03': # Ball Mills Non-indexable 
        line = text.index('#CLASS BALL_MILL_NON_INDEXABLE')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='02' and st=='05': # Chamfer Mills Non-indexable
        line = text.index('#CLASS CHAMFER_MILL_NON_INDEXABLE')
        text = insert_that_row(text, DATA, n_=line)
        return text

    elif t=='02' and st=='06': # Spherical Mills Non-indexable 
        line = text.index('#CLASS SPHERICAL_MILL_NON_INDEXABLE')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='02' and st=='12': # Face Mills Indexable
        line = text.index('#CLASS FACE_MILL_INDEXABLE')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='02' and st=='21': # T-Slot Mills Non-indexable 
        line = text.index('#CLASS T_SLOT_MILL_NON_INDEXABLE')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='02' and st=='93': # Barrel Mills 
        line = text.index('#CLASS BARREL_MILL')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='02' and st=='90': # UG -  5 Parameter Cutter   
        line = text.index('#CLASS UG_5_PARAMETER')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='02' and st=='91': # UG -  7 Parameter Cutter   
        line = text.index('#CLASS UG_7_PARAMETER')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='02' and st=='92': # UG - 10 Parameter Cutter 
        line = text.index('#CLASS UG_10_PARAMETER')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='02' and st=='51': # Form Tool    
        line = text.index('#CLASS MILL_FORM')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='02' and st=='31': # Thread Mills 
        line = text.index('#CLASS THREAD_MILL')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    # Drilling
    elif t=='03' and st=='01': # Twist Drills 
        line = text.index('#CLASS TWIST_DRILL')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='03' and st=='02': # Insert Drills Indexable 
        line = text.index('#CLASS INDEX_INSERT_DRILL')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='03' and st=='03': # Core Drills non-indexable 
        line = text.index('#CLASS CORE_DRILL_NON_INDEXABLE')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='03' and st=='04': # Step Drills 
        line = text.index('#CLASS STEP_DRILL')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='03' and st=='06': # Insert Drills Non-indexable 
        line = text.index('#CLASS INSERT_DRILL')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='03' and st=='07': # Gun Drills Non-indexable
        line = text.index('#CLASS GUN_DRILL')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='03' and st=='08': # Core Drills indexable
        line = text.index('#CLASS CORE_DRILL_INDEXABLE')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='03' and st=='11': # Spot Facing Tools with Pilot ???
        line = text.index('#CLASS SPOT_FACING')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='03' and st=='12': # Spot Facing Tools without Pilot ???
        line = text.index('#CLASS SPOT_FACING')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='03' and st=='21': # Spot Drills
        line = text.index('#CLASS SPOT_DRILL')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='03' and st=='22': # Center Drills    
        line = text.index('#CLASS CENTER_DRILL')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='03' and st=='31': # Adjustable Boring Tools ???
        line = text.index('#CLASS BORE')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='03' and st=='32': # Fixed Diameter Boring
        line = text.index('#CLASS BORE')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='03' and st=='41': # Machine Chucking Reamers 
        line = text.index('#CLASS CHUCKING_REAMER')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='03' and st=='42': # Taper Machine Reamers   
        line = text.index('#CLASS TAPER_REAMER')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='03' and st=='51': # Counter Boring Tools Non-indexable   
        line = text.index('#CLASS COUNTER_BORE')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='03' and st=='52': # Counter Borring Tools  Indexable ???
        line = text.index('#CLASS COUNTER_BORE')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='03' and st=='61': # Counter Sinking Tools  Non-indexable   
        line = text.index('#CLASS COUNTER_SINKING')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='03' and st=='62': # Counter Sinking Tools  Indexable ???
        line = text.index('#CLASS COUNTER_SINKING')
        text = insert_that_row(text, DATA, n_=line)
        return text
        
    elif t=='03' and st=='71': # Taps 
        line = text.index('#CLASS TAP')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='03' and st=='90': # UG Drills
        line = text.index('#CLASS UG_DRILL')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='03' and st=='100': # Back Counter Sinking Tools
        line = text.index('#CLASS BACK_COUNTER_SINKING')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='03' and st=='33': # Boring Bar  
        line = text.index('#CLASS BORING_BAR')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='03' and st=='34': # Chamfer Boring Bar
        line = text.index('#CLASS CHAMFER_BORING_BAR')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    # Turning
    elif t=='01' and st=='01': # OD Turning  
        line = text.index('#CLASS OD_TURNING')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='01' and st=='02': # ID Turning 
        line = text.index('#CLASS ID_TURNING')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='01' and st=='11': # OD Grooving   
        line = text.index('#CLASS OD_GROOVING')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='01' and st=='12': # ID Grooving 
        line = text.index('#CLASS ID_GROOVING')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='01' and st=='13': # Face Grooving  
        line = text.index('#CLASS FACE_GROOVING')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='01' and st=='14': # Parting
        line = text.index('#CLASS PARTING')
        text = insert_that_row(text, DATA, n_=line)
        return text
        
    elif t=='01' and st=='21': # OD Profiling Tools 
        line = text.index('#CLASS OD_PROFILING')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='01' and st=='22': # ID Profiling Tools
        line = text.index('#CLASS ID_PROFILING')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='01' and st=='31': # OD Threading Tools  
        line = text.index('#CLASS OD_THREADING')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='01' and st=='32': # ID Threading Tools 
        line = text.index('#CLASS ID_THREADING')
        text = insert_that_row(text, DATA, n_=line)
        return text
        
    elif t=='01' and st=='51': # Form Tool ???
        line = text.index('#CLASS FORM_TOOL') # no class existed
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='01' and st=='91': # Turning Button
        line = text.index('#CLASS UG_TURNING_BUTTON')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    # Solid
    elif t=='04' and st=='01': # Generic 
        line = text.index('#CLASS GENERIC')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='04' and st=='02': # Probe
        line = text.index('#CLASS PROBE')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='04' and st=='04': # Stamping
        line = text.index('#CLASS STAMPING')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    # Laser
    elif t=='05' and st=='01': # Standard Laser     
        line = text.index('#CLASS STD_LASER')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='05' and st=='02': # Deposition Laser   
        line = text.index('#CLASS DEPOSITION_LASER')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='05' and st=='03': # Hardening Laser 
        line = text.index('#CLASS HARDENING_LASER')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    # Wedm
    elif t=='06' and st=='01': # Wire
        line = text.index('#CLASS WIRE')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    # Robotic
    elif t=='07' and st=='01': # End Effector - End Mill based 
        line = text.index('#CLASS ROBOTIC_END_MILL')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='07' and st=='02': # End Effector - Ball Mill based 
        line = text.index('#CLASS ROBOTIC_BALL_MILL')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    # Multi-tool
    elif t=='08' and st=='01': # Turning  
        line = text.index('#CLASS MULTITOOL_TURN')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    elif t=='08' and st=='02': # Drilling and turning
        line = text.index('#CLASS MULTITOOL_DRILL_TURN')
        text = insert_that_row(text, DATA, n_=line)
        return text
    
    else:
        print('Register error. No corresponding tool classes were found.')

    return text

def insert_that_row(text_, DATA_, n_):
    Reqs_ = text_[n_+1].split(' ')[1:]
    new_line = 'DATA'
    for x in Reqs_:
        new_line += ' | ' + DATA_[x]
    new_text = text_[:(n_+3)].copy()
    tail = text_[(n_+3):].copy()
    new_text.append(new_line)
    new_text += tail
    text_ = new_text
    return text_

#read_tools()
