###############################################################################
# dbc_tool_ascii.tcl - DBC Event Handler for database stored as ascii file
###############################################################################
##############################################################################
# REVISIONS
#   Date       Who              Reason
#   04-Dec-98  naveen &         Initial
#              binu
#   24-Mar-99  Dave Yoon        Remove source paths
#   12-May-99  Joachim Meyer    New format of the data file
#   17-Jun-99  Joachim Meyer    Remove test file open
#   05-Jul-99  Joachim Meyer    Use MOM_abort for error message
#                               Use MOM__boot for sourcing general tcl files
#                               Dummy procedure MOM__halt
#   06-Jul-99  Joachim Meyer    Retrieve Threading/Profiling tools
#   27-Jul-99  Joachim Meyer    Retrieve UG Legacy tools
#   05-Aug-99  Joachim Meyer    Load tool_database.dat into memory 
#                               depending on file size
#   24-Aug-99  Joachim Meyer    Correct inserttype for threading tools
#   08-Oct-99  Joachim Meyer    Add DBC_ask_library_values
#   15-Oct-99  Joachim Meyer    Retrieve taps and counter sinking tools
#   10-May-00  Joachim Meyer    Retrieve also values for tool number,
#                               cutcom and adjust register
#   27-Aug-01  Joachim Meyer    Manage also inscribed circle
#   05-Dec-01  Joachim Meyer    Map D2 diameter of face mills to the UG diameter 
#   05-Dec-01  Murthy Mandaleeka Map Hole Making Tools
#   28-Jan-02  Murthy Mandaleeka Add Pitch and Shank Diameter for Thread Mill 
#   15-Feb-02  Joachim Meyer    Correct full nose radius insert width
#   25-Feb-02  Murthy Mandaleeka Add Parameters for Step Drill
#   08-May-02  Joachim Meyer     Add set_step_drill_para
#   12-Jun-02  Joachim Meyer     Move hole maing tool retrieve to separate
#                                procedure set_drilling_para
#   03-Apr-03  Juergen Wartmann  Adjust tracking side evaluation for grooving
#                                tools having no PSET attribute
#   24-Apr-03  Joachim Meyer     Automatic calculation of second tracking side
#                                for turning grooving cutters
#   07-May-03  Gopal Srinath     Allowd the query to carry units 
#   26-May-03  Joachim Meyer     Map lib thread shape to UG types
#   27-May-03  Gopal Srinath     removed the call to set_part_unit
#                                in DBC_execute_query and 
#                                DBC_execute_query_for_count 
# 02Sep2003   JM                 set xmount, ymount, zmount paras
#   26-Nov-2003 rlm              Add Rigidity to tool database
#   02-Feb-2005 rlm              Add support for tool export
#   30-Jun-2005 rlm              Add DBC_ask_class_by_type
#   27-Jun-2006 rlm              Add tool export support for Mill user defined,
#                                  step-drill and turning form tools
#   28-Nov-2006 rlm              Fix test for inch file size
#   24-Mar-2009 jm               Fix full nose radius tracking point
#   21-Oct-2009 jm               Improve default value for insert thickness
#                                and relief angle
#   25-Nov-2009 vanderko         Add thread_form_name
#   01-Feb-2010 Leo Hu            Retrieve Shoulder Distance of step drill tool
#   21-Jul-2010 Peter Mao        camarch8001 - shank tool and chamfer mill
#   14-Oct-2010 Peter Mao        camarch8002 - tool library alignment
#   14-Nov-2010 Peter Mao        camarch8002 - change the format for several parameters
#                                              from 7 and 10 parameters tools
#   30-Nov-2010 Peter Mao        camarch8001 - Machining parameters on cutter
#   08-Nov-2011 Peter Mao        Add holder angle for turning tool
#   14-Dec-2011 JM               Add dbc_export_file_name
#   21-Mar-2012 Peter Mao        6683970     - Change the default value
#   11-Apr-2012 Peter Mao        6691519     - Change the default value
#   28-Sep-2012 Mario Mao        camarch9042 - add point length and core drill
#   04-Jan-2013 Cheng Wang       Add support for Laser Tool <camarch9030>
#   25-Jan-2013 Mario Mao        1912099 - retrieve tip angle for face grooving
#   04-Feb-2013 Mario Mao        6835301 retrieve designation
#   07-Feb-2013 Mario Mao        6806427 Add flute length for center/spot drill and countersink
#   26-Apr-2013 Mario Mao        6861162 Adjust flute length retrieve scenario
#   03-Jun-2013 Mario Mao        1937332 add none option for tool direction
#   23-Jul-2013 Gopal Srinath            User Defined Parameters at retrieval
#   17-Sep-2013 Mario Mao                Retrieve include angle and tip dia for tap
#   08-Apr-2014 Mark Rief                Move User Defined Parameters to dbc_tool_ud_data_sample.tcl
#   28-Jul-2014 R. Miner         7126165 Fix calculation of point length
#   29-Jan-2015 Cheng Wang       cam10052:Add support for Back Countersink Tool
#   15-May-2015 R. Miner                 Fix import of deposition laser.
#   21-Oct-2015 Jenny Zhang      cam11035 - Add Boring Bar tool
#   16-Nov-2015 Jenny Zhang      cam11035 - Remove Back Angle and add Relief Width for Boring Bar tool
#   23-Nov-2015 Jenny Zhang      cam11035 - Use Pilot Diameter and Pilot Length for Boring Bar tool
#   23-Jan-2018 J. Meyer         cam12081 - Add index notch and turret rot angles
#   20-Aug-2018 Shorbojeet Das   PR#9157535, PR#8375989 - Add more precision for spherical tool computation.
#   06-Sep-2018 Shorbojeet Das   PR#9237134 - Add retrieval method for FDM tools.
#   20-Sep-2018 Shorbojeet Das   Enable customization support.
#   06-Dec-2018 Shorbojeet/Gopal PR9239403 - Differentiate between Tap and Thread tools for Form/Thread shape. 
#   16-Jan-2019 Shanaz Mistry    cam18010.2: Add retrieval methods for Taper barrel
#   05-Feb-2019 Shanaz Mistry    cam18010.2: Fix retrieval issue with working angle
#   29-Jul-2019 Jingzhao Zhang   cam19046.1: Retrieve/Export tool with new parameters ("Relief Length" and "Relief Diameter") 
#   30-Jul-2019 Shorbojeet/Gopal PR9538312 - Update logic to correctly map different thread form descriptions to form type.
#   22-Aug-2019 Frank Armbrust   cam19009.1: Add tool helix angle for retrieve/export from tool database.
#   02-Sep-2019 Frank Armbrust   cam19009.1: Change tool helix angle from deg to radians.
##############################################################################
#

# Default double precision value format.
set double_precision_format "g"

proc ASC_t_create_filename {env_var_name filename} \
{
#
# Creates a complete filename by evaluating an environment variable
# for the directory information
#
    set env_var [MOM_ask_env_var $env_var_name]
    if { $env_var == "" } \
    {
         set message "Can't read environment variable $env_var_name"
         MOM_abort "\n $message"
    }

    set fname ""
    set fname [append fname $env_var $filename]

    return $fname

}

proc MOM__boot {} \
{
# source some general procedures 

#
# dbc_ascii_general.tcl
#
  set filename \
      [ASC_t_create_filename "UGII_UG_LIBRARY_DIR" "dbc_ascii_general.tcl"]
  if { [catch {source $filename}] == "1" } \
  {
      set message "Can't load .tcl file: $filename"
      MOM_abort "\n $message"
  }

#
# dbc_tool_general.tcl
#
  set filename \
      [ASC_t_create_filename "UGII_UG_LIBRARY_DIR" "dbc_tool_general.tcl"]
  if { [catch {source $filename}] == "1" } \
  {
       set message "Can't load .tcl file: $filename"
       MOM_abort "\n $message"
  }

#
#  Tool export procedures
#
  set filename \
      [ASC_t_create_filename "UGII_CAM_LIBRARY_TOOL_ASCII_DIR" "dbc_tool_ascii_export.tcl"]
  if { [catch {source $filename}] == "1" } \
  {
       set message "Can't load .tcl file: $filename"
       MOM_abort "\n $message"
  }

#
#  Tool record build procedures
#
  set filename \
      [ASC_t_create_filename "UGII_CAM_LIBRARY_TOOL_ASCII_DIR" "dbc_tool_build_ascii.tcl"]
  if { [catch {source $filename}] == "1" } \
  {
       set message "Can't load .tcl file: $filename"
       MOM_abort "\n $message"
  }


# Only for testing
####    source /cam/v160/jm_mct/dbc_ascii_general.tcl
####    source /cam/v160/jm_mct/dbc_tool_general.tcl
}

proc MOM__halt {} \
{

}

#---------------------------------------------
proc DBC_init_db {} \
{

global asc_debug 
global asc_file_name
global asc_units
global asc_part_units

global asc_mm_file_name
global asc_inch_file_name
global asc_file_loaded
global asc_file_load_limit

global dbc_cutter_ass_units

global asc_database_count


#
# Global variables set by DBC for Input/Output
#

global dbc_lhs_exp
global dbc_rhs_exp
global dbc_relop
global dbc_query
global dbc_subqry1
global dbc_subqry2
global dbc_boolop 
global dbc_class_name
global dbc_attr_count
global dbc_attr_id 
global dbc_query_count
global dbc_libref 
global dbc_var_list
#
# This is path+name of the tool_database.dat file 
# where a tool gets exported, see also dbc_tool_ascii_export.tcl.
# It is used within NX CAM to provide feedback
# to the user about tool export
#
global dbc_export_file_name  


set dbc_lhs_exp     ""
set dbc_rhs_exp     ""
set dbc_relop   ""
set dbc_query   ""
set dbc_subqry1 ""
set dbc_subqry2 ""
set dbc_boolop  ""
set dbc_class_name  ""
set dbc_attr_count  0
set dbc_attr_id     ""
set dbc_query_count 0
set dbc_libref ""
set dbc_var_list ""

set asc_debug 0
set asc_file_name ""
set dbc_export_file_name ""
set asc_part_units ""
set dbc_cutter_ass_units ""


#
#  If the number of bytes of the file is smaller than
#  this  asc_file_load_limit then the file is loaded into
#  memory. This file_load_limit can be set by an environment
#  variable 
#

    set asc_file_loaded 0

    set env_var [MOM_ask_env_var UGII_CAM_LIBRARY_TOOL_ASCII_LOAD_LIMIT]
    if { $env_var == "" } \
    {
        set asc_file_load_limit 200000
    } \
    else \
    {
        set asc_file_load_limit [string trim $env_var]
    }

#
# Set the unit for tool search to the part unit
#
  ASC_set_part_unit

#
# ask the mm and inch filenames
#
  set asc_mm_file_name   [ASC_get_data_file_name $asc_units(mm)]
  set asc_inch_file_name [ASC_get_data_file_name $asc_units(inch)]
  if { $asc_mm_file_name == "" &&  $asc_inch_file_name == "" } \
  {
       set message "Error looking for a tool_database.dat file."
       set message "$message \n Neither of the environment variables"
       set message "$message \n UGII_CAM_LIBRARY_TOOL_METRIC_DIR,"
       set message "$message \n UGII_CAM_LIBRARY_TOOL_ENGLISH_DIR"
       set message "$message \n is defined."
       MOM_abort "\n $message"
  }

#
# Ask the size of the files
#
  set ret_val_mm 1
  set size_mm 0
  if { $asc_mm_file_name != "" } \
  {
     set ret_val_mm [catch {file size $asc_mm_file_name} size_mm]
  }

  set ret_val_inch 1
  set size_inch 0
  if { $asc_inch_file_name != "" } \
  {
     set ret_val_inch [catch {file size $asc_inch_file_name} size_inch]
  }

  if { $ret_val_mm == "1" &&  $ret_val_inch == "1" } \
  {
     set message "Error, can't read a tool_database.dat file."
     set message "$message \n Neither of the files"
     set message "$message \n $asc_mm_file_name"
     set message "$message \n $asc_inch_file_name"
     set message "$message \n can be read."
     MOM_abort "\n $message"
  }

#
# If the files have a size not too big, try to load them
#
  set size_mm_inch [expr $size_mm + $size_inch]
#
# mm file
#
  set app 0
  set mm_file_loaded 0
  if { $ret_val_mm == 0 && $size_mm_inch < $asc_file_load_limit } \
  {
     set ret_cd [ASC_load_data_file $asc_mm_file_name $asc_units(mm) $app]
     if { $ret_cd != 0 } \
     {
        set message "Error, can't open file:"
        set message "$message \n $asc_mm_file_name"
        MOM_abort "\n $message"
     }
     set app 1
     set mm_file_loaded 1
  }

#
# and then inch file
#
  set inch_file_loaded 0
  if { $ret_val_inch == 0 && $size_mm_inch < $asc_file_load_limit } \
  {
     set ret_cd [ASC_load_data_file $asc_inch_file_name $asc_units(inch) $app]
     if { $ret_cd != 0 } \
     {
        set message "Error, can't open file:"
        set message "$message \n $asc_inch_file_name"
        MOM_abort "\n $message"
     }
     set inch_file_loaded 1
  }

#
# if mm or inch or both files are loaded set the flag
#
  if { $inch_file_loaded == 1 || $mm_file_loaded == 1 } \
  {
      set asc_file_loaded 1
  }

#
# This variable is only used for error messages
#
  set asc_file_name " $asc_mm_file_name"
  set asc_file_name "$asc_file_name \n $asc_inch_file_name"

}

proc ASC_get_data_file_name { unit } \
{
#
# Returns the filename for ASCII Data File depending on the
# specified unit.
#
global asc_units
 
  if {$unit == $asc_units(mm)} \
  {
    set env_var_name UGII_CAM_LIBRARY_TOOL_METRIC_DIR
  } \
  else \
  {
    set env_var_name UGII_CAM_LIBRARY_TOOL_ENGLISH_DIR
  }

  set env_var [MOM_ask_env_var $env_var_name]
  if { $env_var == "" } \
  {
       return ""
  }

  set fname ""
  set fname [append fname $env_var "tool_database.dat"]

  return $fname
}

proc ASC_set_part_unit {} \
{

global dbc_part_units
global dbc_search_units
global asc_units

  MOM_ask_part_units  ;# writes to dbc_part_units

  if {$dbc_part_units == "metric"} \
  {
      set dbc_search_units $asc_units(mm)
  } \
  else \
  {
      set dbc_search_units $asc_units(inch)

  }
}

#---------------------------------------------
proc DBC_retrieve {} {
#---------------------------------------------
global dbc_libref

        ASC_retrieve
}

#---------------------------------------------
proc ASC_retrieve {} {
#---------------------------------------------
#
#  Check if optional user defined parameters are to be added to the tool.
#  This is done by the file "dbc_tool_ud_data.tcl" in UGII_CAM_LIBRARY_TOOL_ASCII_DIR. 
#  This file must contain a proc DBC_ud_data which will do the data assignment.
#  A sample of this file dbc_tool_ud_data_sample.tcl is provided.
#  It must be renamed and modified to suit by the user.
#
#  To make these visible in the NX Tool dialog, add the customizable item 
#  library user parameters to the tool dialog in the library_dialogs.prt template.
#

   set toolAsciiDir [MOM_ask_env_var UGII_CAM_LIBRARY_TOOL_ASCII_DIR]
   set udLibData "dbc_tool_ud_data.tcl"

#  Check if the commad does not exist and source the file if it exists 
   if { [llength [info commands DBC_ud_data]] == 0 } {
      if { [file exists ${toolAsciiDir}$udLibData ] } {
         source ${toolAsciiDir}$udLibData
      }
   }
#  If the command now exsits call it
   if { [llength [info commands DBC_ud_data]] } {
      DBC_ud_data
   }

# global input
# ------------
   global asc_debug
   global asc_units

   global dbc_search_units

   global dbc_libref
   global dbc_retrieve_var_list


   global asc_file_loaded
   global asc_database
   global asc_database_count
   global asc_file_name

   global ug_ctr_type     ;#  UG cutter type     
   global ug_ctr_stype    ;#  UG cutter subtype

   global uglib_tl_type   ;#  UG/Library tool type
   global uglib_tl_stype  ;#  UG/Library tool subtype

#
# global output
# -------------
   global dbc_holding_system 
   global dbc_cutter_count   
   global dbc_cutter_ass_units  ;#   (0=mm, 1=inch)

#
# A tool assembly can have several cutters so we store the data in arrays
# the array count varies in the range 0 <= n < $dbc_cutter_count
#
  global dbc_cutter_number
  global dbc_cutter_name
  global dbc_cutter_ctlg_num
  global dbc_cutter_type    
  global dbc_cutter_subtype 

#
# Data for 5/7/10 parameter milling tool
  global dbc_cutter_diameter  
  global dbc_cutter_height    
  global dbc_cutter_flute_ln  
  global dbc_cutter_cor1_rad  
  global dbc_cutter_taper_ang 
  global dbc_cutter_tip_ang   
  global dbc_cutter_num_flutes

  global dbc_cutter_relief_diameter
  
  global dbc_cutter_chamfer_length
  global dbc_cutter_face_mill_dia2
  global dbc_cutter_is_face_mill
  global dbc_cutter_direction        ;# (milling tools)
  global dbc_cutter_insert_position  ;# (turning tools)

  global dbc_cutter_z_offset 

#
# edit 10-May-2000  
# add global vars for tool number, adjust and cutcom registers
#
  global dbc_cutter_tool_number
  global dbc_cutter_adj_reg
  global dbc_cutter_cutcom_reg

  global dbc_rigidity

  global dbc_cutter_xcen_cor1
  global dbc_cutter_ycen_cor1
  global dbc_cutter_cor2_rad 
  global dbc_cutter_xcen_cor2
  global dbc_cutter_ycen_cor2

#
# Data for T cutter and Barrel
  global dbc_cutter_shank_dia  
  global dbc_cutter_low_cor_rad
  global dbc_cutter_up_cor_rad 
#  additional for barrel
  global dbc_cutter_ycen_barrel
  global dbc_cutter_barrel_rad 
  global dbc_cutter_working_angle
#
# drill
  global dbc_cutter_point_ang  

# Data for Back Countersink
  global dbc_cutter_insert_size
  global dbc_cutter_min_hole_diameter

# Data for Boring Bar
  global dbc_cutter_front_insert_length
  global dbc_cutter_back_insert_length
  global dbc_cutter_lead_angle
  global dbc_cutter_insert_angle
  global dbc_cutter_relief_length
  global dbc_cutter_relief_width

#
# Turning std/boring

  global dbc_cutter_nose_rad   
  global dbc_cutter_nose_ang   
  global dbc_cutter_orientation

  global dbc_cutter_tracking_point

  global dbc_cutter_cut_edge_length
  global dbc_cutter_size_opt 


  global dbc_cutter_inserttype     

  global dbc_cutter_thickness      
  global dbc_cutter_thickness_type 

  global dbc_cutter_relief_ang     
  global dbc_cutter_relief_ang_type

  global dbc_cutter_max_depth      
  global dbc_cutter_max_depth_flag  ;#indicates if specified

  global dbc_cutter_max_toolreach  
  global dbc_cutter_max_toolreach_flag  ;#indicates if specified

  global dbc_cutter_min_boring_dia    
  global dbc_cutter_min_boring_dia_flag  ;#indicates if specified

  global dbc_cutter_min_facing_dia
  global dbc_cutter_min_facing_dia_flag  ;#indicates if specified

  global dbc_cutter_max_facing_dia
  global dbc_cutter_max_facing_dia_flag  ;#indicates if specified

  global dbc_cutter_x_offset       
  global dbc_cutter_x_offset_flag      ;#indicates if specified

  global dbc_cutter_y_offset       
  global dbc_cutter_y_offset_flag      ;#indicates if specified

  global dbc_cutter_xmount
  global dbc_cutter_ymount
  global dbc_cutter_zmount

#Turning grooving
  global dbc_cutter_insert_width   
  global dbc_cutter_insert_length  

  global dbc_cutter_side_ang       
  global dbc_cutter_left_ang       
  global dbc_cutter_right_ang      


  global dbc_cutter_radius         
  global dbc_cutter_left_cor_rad   
  global dbc_cutter_right_cor_rad  

  global dbc_cutter_preset             ;# 0,1,2 = left, both, right

# X/Y offsets for grooving
  global dbc_cutter_left_xoff     
  global dbc_cutter_left_xoff_flag

  global dbc_cutter_left_yoff     
  global dbc_cutter_left_yoff_flag

  global dbc_cutter_right_xoff    
  global dbc_cutter_right_xoff_flag

  global dbc_cutter_right_yoff    
  global dbc_cutter_right_yoff_flag

# Tracking points for grooving
  global dbc_cutter_left_tp       
  global dbc_cutter_right_tp      

# Some tool holder data
  global dbc_tool_holder_diameter
  global dbc_tool_holder_length
  global dbc_tool_holder_taper
  global dbc_tool_holder_offset
  global dbc_cutter_holder_libref

# Trackpoint library reference
  global dbc_cutter_trackpoint_libref

# For threading tools
  global dbc_cutter_thread_left_ang
  global dbc_cutter_thread_right_ang
  global dbc_cutter_thread_tip_offset
  global dbc_cutter_thread_insert_width
  global dbc_cutter_thread_nose_width
  global dbc_cutter_thread_insert_length
  global dbc_cutter_thread_nose_rad      ;#-2653

# For Button tools (turning)
  global dbc_cutter_button_diameter
  global dbc_cutter_holder_angle
  global dbc_cutter_holder_width

# For Ring Type Joint
  global dbc_cutter_nose_width

#  Turning Form Tools
  global dbc_cutter_initial_edge_angle
  global dbc_cutter_initial_edge_length

#
# part file name  with cutter graphics
   global dbc_partfile_name
   global dbc_cutter_ass_part_name

# Cutter description
   global dbc_cutter_description

# Reference to cutter material table
   global dbc_cutter_tool_material_libref

   global dbc_cutter_coolant_through

   global dbc_cutter_holder_orient_angle

 # Index Notch and Incr Turret Rotation
    global dbc_cutter_index_notch
    global dbc_cutter_turret_rotation

# Data for process force calculation
  global dbc_cutter_tool_helix_angle

#####   set PI 3.14159265358979324


   if { $asc_debug == "1" } \
   {
        puts " =========================================="
        puts " procedure  DBC_retrieve for tool assembly"
        puts " libref -> $dbc_libref"
   }

#
# Look for the desired libref
#
       if { $asc_file_loaded == 1 } \
       {
           ASC_array_search_libref $dbc_libref db_row 
       } \
       else \
       {
           ASC_file_search_libref $dbc_libref db_row
       }

#
# partfile name for tool graphic
#
   set dbc_cutter_ass_part_name     ""
   append dbc_cutter_ass_part_name $dbc_libref ".prt"
   set dbc_partfile_name $dbc_cutter_ass_part_name

#
#  number of cutters and holding system
   set dbc_cutter_count  1
   set dbc_holding_system  [ASC_ask_att_val HLD $db_row "" 4711 flag]

#
#  Unit of cutter
#
   set units [ASC_ask_att_val _unitt $db_row "" $asc_units(mm) flag]
   if { "$units" == "$asc_units(mm)" } \
   {
      set dbc_cutter_ass_units 0
   } \
   else \
   {
      set dbc_cutter_ass_units 1
   }

#
#  Cutter number always 1 because multi tools are not yet supported
   set dbc_cutter_number(0) 1
#
#  Cutter name is the libref
   set  dbc_cutter_name(0) $dbc_libref
#
#  We take the same for catalog number
   set  dbc_cutter_ctlg_num(0) $dbc_cutter_name(0)

#
# Now we determine the UG Cutter type and subtype from the
# UG/Library type and subtype
  set type     [ASC_ask_att_val  T $db_row "" 4711 flag]
  set lib_type $type

  if { $flag == "0" } \
  {
     set message "Error retrieving tool from external library."
     set message "$message \n Tool with the library reference $dbc_libref has"
     set message "$message \n no type (T) attribute in the"
     set message "$message \n ASCII Data File(s): $asc_file_name"
     MOM_abort "\n $message"
  }
  set subtype  [ASC_ask_att_val ST $db_row "" 4711ayab flag]
  set lib_subtype $subtype
  if { $flag == "0" } \
  {
     set message "Error retrieving tool from external library."
     set message "$message \n Tool with the library reference $dbc_libref has"
     set message "$message \n no subtype (ST) attribute in the "
     set message "$message \n ASCII Data File(s): $asc_file_name"
     MOM_abort "\n $message"
  }

# turning holder angle
  set holderAngle [ASC_ask_att_val HANGLE $db_row "%$::double_precision_format" 0 flag]
  set dbc_cutter_holder_orient_angle(0) [UGLIB_convert_deg_to_rad $holderAngle]

#  Try to get the rigidity factor.  If none defined, return 1.0
  set dbc_rigidity [ASC_ask_att_val RIGID $db_row "%$::double_precision_format" 1.0 flag]
  if { $flag == "0" } \
  {
      set dbc_rigidity 1.0
  }

#
#  Look if UG type and subtype are speicified in the library
#
  set ug_type        [ASC_ask_att_val  UGT  $db_row "" 4711 flag1]
  set ug_subtype     [ASC_ask_att_val  UGST $db_row "" $ug_ctr_stype(UNDEFINED) flag2]
   
  if { $flag1 == "0" } \
  {
#
#     UG type and subtype are not specified in the library -> do the default mapping
      UGLIB_convert_type_subtype  $type $subtype \
                                  dbc_cutter_type(0) dbc_cutter_subtype(0)
  } \
  else \
  {
       set err_flag [UGLIB_check_ug_type_subtype $ug_type $ug_subtype]
       if { $err_flag == "1" } \
       {
          set message "Error retrieving tool from external library."
          set message "$message \n The specified UG tool type/subtype (UGT/UGST) does not exist."
          set message "$message \n UGT = $ug_type, UGST =  $ug_subtype "
          MOM_abort "\n $message"
       }
#
#       remove leading 0 if specified
#
        set dbc_cutter_type(0) $ug_type
        set dbc_cutter_type(0) [string trim $ug_type]
        set dbc_cutter_type(0) [string trimleft $ug_type "0"]
        if {$dbc_cutter_type(0) == ""} {set dbc_cutter_type(0) 0}
 
        set dbc_cutter_subtype(0) $ug_subtype
        set dbc_cutter_subtype(0) [string trim $dbc_cutter_subtype(0)]
        set dbc_cutter_subtype(0) [string trimleft $dbc_cutter_subtype(0) "0"]
        if {$dbc_cutter_subtype(0) == ""} {set dbc_cutter_subtype(0) 0}

  }

  if { $dbc_cutter_type(0) == $ug_ctr_type(THREAD) } \
  {

#
#     Thread type and pitch
#
      set thread_type [ASC_ask_att_val THRDS $db_row "" 1 flag1]
      set pitch       [ASC_ask_att_val PIT   $db_row "%$::double_precision_format" 10 flag2]


      if { $flag1 == "1" && $flag2 == "1" } \
      {
#
#        In this case the subtype of the threading tool and 
#        all parameters are determined by the type and pitch
#
         UGLIB_calc_thread_params   $thread_type $pitch                 \
                                    $dbc_cutter_ass_units               \
                                     dbc_cutter_subtype(0)              \
                                     dbc_cutter_thread_left_ang(0)      \
                                     dbc_cutter_thread_right_ang(0)     \
                                     dbc_cutter_thread_tip_offset(0)    \
                                     dbc_cutter_thread_insert_width(0)  \
                                     dbc_cutter_thread_nose_width(0)    \
                                     dbc_cutter_thread_insert_length(0) 
      } \
      else \
      {
#
#       In this case we hope that all the UG required 
#       thread parameters are specified in the library
#
#       Thread Left Angle
           set angle [ASC_ask_att_val LA $db_row "%$::double_precision_format" 30 flag]
           set dbc_cutter_thread_left_ang(0) [UGLIB_convert_deg_to_rad $angle]
#
#       Thread Right Angle
           set def_val $angle
           set angle [ASC_ask_att_val RA $db_row "%$::double_precision_format" $def_val flag]
           set dbc_cutter_thread_right_ang(0) [UGLIB_convert_deg_to_rad $angle]
#
#       Thread Tip Offset
           set dbc_cutter_thread_tip_offset(0) \
               [ASC_ask_att_val TOFF $db_row "%$::double_precision_format" 2 flag]
#
#       Thread Insert Width
           set dbc_cutter_thread_insert_width(0) \
               [ASC_ask_att_val IW $db_row "%$::double_precision_format" 4 flag]
#
#       Thread Nose Width
           set dbc_cutter_thread_nose_width(0) \
               [ASC_ask_att_val NOSW $db_row "%$::double_precision_format" 2 flag]
#
#       Thread Insert Length
           set dbc_cutter_thread_insert_length(0) \
               [ASC_ask_att_val IL $db_row "%$::double_precision_format" 3 flag]
      }
  }

#
# Nose Width for the Ring Type Joint
  set dbc_cutter_nose_width(0) [ASC_ask_att_val NOSW $db_row "%$::double_precision_format" 2 flag]

#
# Reference to cutter material table
#
  catch { unset dbc_cutter_tool_material_libref(0) }
  set value [ASC_ask_att_val MATREF $db_row "" 0 flag]
  if { $flag == 1 } { set dbc_cutter_tool_material_libref(0) $value }

#
# Cutter description
#
  set dbc_cutter_description(0) \
      [ASC_ask_att_val DESCR $db_row "" "No Description" flag]

#
# Some tool holder data
#
#
# Holder Diameter
#
  set dbc_tool_holder_diameter(0) [ASC_ask_att_val HDIA $db_row "%$::double_precision_format" 0 flag]
#
# Holder Length
#
  set dbc_tool_holder_length(0) [ASC_ask_att_val HLEN $db_row "%$::double_precision_format" 0 flag]
#
# Holder Taper
#
  set angle [ASC_ask_att_val HTAP $db_row "%$::double_precision_format" 0 flag]
  set dbc_tool_holder_taper(0) [UGLIB_convert_deg_to_rad $angle]

# Coolant Through
  set dbc_cutter_coolant_through(0) [ASC_ask_att_val CTH $db_row "%d" 0 flag]

#
# Holder offset
#
  set dbc_tool_holder_offset(0) [ASC_ask_att_val HOFF $db_row "%$::double_precision_format" 0 flag]

#
#  Holder library libref
#
  set dbc_cutter_holder_libref(0) [ASC_ask_att_val HLDREF $db_row "" "" flag]

#
#  Trackpoint library libref
#
  set dbc_cutter_trackpoint_libref(0) [ASC_ask_att_val TPREF $db_row "" "" flag]

#
# some milling tool values
#
# Diameter
#
  set dbc_cutter_diameter(0) [ASC_ask_att_val DIA $db_row "%$::double_precision_format" 10.939 flag]


#
# Drill Point Angle
#
  set angle [ASC_ask_att_val PNTA $db_row   "%$::double_precision_format" 180 flag]
  set dbc_cutter_point_ang(0) [UGLIB_convert_deg_to_rad $angle]

#
# Height
#
  set def_val [expr 3 * $dbc_cutter_diameter(0)]
  set dbc_cutter_height(0) [ASC_ask_att_val HEI $db_row "%$::double_precision_format" $def_val flag]

#
# Flute Length
#
  set def_val [expr 0.5 * $dbc_cutter_height(0)]
  if {$type == $uglib_tl_type(MILL) && $subtype == $uglib_tl_stype(MILL_FORM)} {
      set def_val 0.0
  }
  set dbc_cutter_flute_ln(0) [ASC_ask_att_val FLEN $db_row "%$::double_precision_format" $def_val flag]
#
#
# Direction of rotation (1 clockwise, 2 counterclockwise)
#
  set direction [ASC_ask_att_val DROT $db_row "" 1 flag]

     if { $direction == "03" || $direction == "3"} \
     {
#        right 
         set dbc_cutter_direction(0) 1
     } \
     elseif { $direction == "04" || $direction == "4"} \
     {
#        left 
         set dbc_cutter_direction(0) 2
     } \
     else \
     {
#       none
        set dbc_cutter_direction(0) 0
     }
#
# Taper Angle
#
  set angle [ASC_ask_att_val TAPA $db_row "%$::double_precision_format" 0 flag]
  set dbc_cutter_taper_ang(0) [UGLIB_convert_deg_to_rad $angle]

#
# Number of Flutes
#
  set dbc_cutter_num_flutes(0) [ASC_ask_att_val FN $db_row "" 1 flag]

#
# Z - Offset 
#
  set dbc_cutter_z_offset(0) [ASC_ask_att_val ZOFF $db_row "%$::double_precision_format" 0.0 flag]

# Z Mount
  set dbc_cutter_zmount(0) [ASC_ask_att_val ZMOUNT $db_row "%$::double_precision_format" 0.0 flag]

#
# edit 10-May-2000,
# retrieve also values for tool number, adjust and cutcom registers
# In the case where the attribute is not specified in the library, we make
# sure that the global vars dbc_cutter_.. are not set
# This causes that in this case the toggle in the tool dialog in UG is
# not activated 
#
   catch { unset dbc_cutter_tool_number(0) } 
   set value [ASC_ask_att_val TLNUM $db_row "%d" 4711 flag]
   if { $flag == 1 } { set dbc_cutter_tool_number(0) $value }

   catch { unset dbc_cutter_adj_reg(0) } 
   set value [ASC_ask_att_val ADJREG $db_row "%d" 4711 flag]
   if { $flag == 1 } { set dbc_cutter_adj_reg(0) $value }

   catch { unset dbc_cutter_cutcom_reg(0) } 
   set value [ASC_ask_att_val CUTCOMREG $db_row "%d" 4711 flag]
   if { $flag == 1 } { set dbc_cutter_cutcom_reg(0) $value }

# Tool Helix Angle in radians
   set helix_angle [ASC_ask_att_val HA $db_row "%$::double_precision_format" 0 flag]
   set dbc_cutter_tool_helix_angle(0) [UGLIB_convert_deg_to_rad $helix_angle]

# 5 Parameter Milling Tool
#
# Relief Diameter
   set dbc_cutter_relief_diameter(0)      [ASC_ask_att_val RD $db_row "%$::double_precision_format" 0 flag]
#
# 7/10 Parameter Milling Tool
#
# Corner 1 Radius
#
  set dbc_cutter_cor1_rad(0) [ASC_ask_att_val COR1 $db_row "%s" 0 flag]
#
# Corner 1 Center (x,y) (we map Genius x,y to UG y,x)
#
  set dbc_cutter_xcen_cor1(0) [ASC_ask_att_val CX1 $db_row "%s" 123 flag]
  set dbc_cutter_ycen_cor1(0) [ASC_ask_att_val CY1 $db_row "%s" 123 flag]
#
# Corner 2 Radius
#
  set dbc_cutter_cor2_rad(0) [ASC_ask_att_val COR2 $db_row "%s" 0 flag]
#
# Corner 2 Center (x,y) (we map Genius x,y to UG y,x)
#
  set dbc_cutter_xcen_cor2(0) [ASC_ask_att_val CX2 $db_row "%s" 123 flag]
  set dbc_cutter_ycen_cor2(0) [ASC_ask_att_val CY2 $db_row "%s" 123 flag]

# Special case - shank diameter on spherical mill.
# Shank diameter/neck diameter has to be read with a higher precision for consistency.
  if {$dbc_cutter_type(0) == $ug_ctr_type(MILL) && \
      $dbc_cutter_subtype(0) == $ug_ctr_stype(SPHERICAL)} \
  {
    set dbc_cutter_shank_dia(0) [ASC_ask_att_val SDIA $db_row "%0.6f" $def_val flag]
  } \
  else \
  {
    #
    # Data for T cutter and Barrel
    #
    set def_val [expr $dbc_cutter_diameter(0) / 4]
    set dbc_cutter_shank_dia(0) [ASC_ask_att_val SDIA $db_row "%$::double_precision_format" $def_val flag]
  }

  set dbc_cutter_low_cor_rad(0) [ASC_ask_att_val LCOR $db_row "%$::double_precision_format" 0 flag]
  set dbc_cutter_up_cor_rad(0)  [ASC_ask_att_val UCOR $db_row "%$::double_precision_format" 0 flag]
#
# additional for barrel
#
  set dbc_cutter_ycen_barrel(0) [ASC_ask_att_val YCEN $db_row "%$::double_precision_format" 5  flag]
  set dbc_cutter_barrel_rad(0)  [ASC_ask_att_val BRAD $db_row "%$::double_precision_format" 22 flag]
  set wangle [ASC_ask_att_val WRANG $db_row "%$::double_precision_format" 0 flag]
  set dbc_cutter_working_angle(0) [UGLIB_convert_deg_to_rad $wangle]

# chamfer mill and face mill
  set dbc_cutter_is_face_mill(0) FALSE
  if {$dbc_cutter_type(0) == $ug_ctr_type(MILL) && \
      $dbc_cutter_subtype(0) == $ug_ctr_stype(CHAMFER)} \
  {
     # Chamfer Mill Tool
     set dbc_cutter_chamfer_length(0) [ASC_ask_att_val CHAMFERLEN $db_row "%$::double_precision_format" 0 flag]
  }

 # if it is face mill
 if {$type == $uglib_tl_type(MILL) && \
     ($subtype == $uglib_tl_stype(NI_FACE_MILL) || \
      $subtype == $uglib_tl_stype(I_FACE_MILL) )} {

      set dbc_cutter_is_face_mill(0) TRUE
      set dbc_cutter_face_mill_dia2(0) [ASC_ask_att_val D2 $db_row "%$::double_precision_format" 0.0 flag]

      set dbc_cutter_subtype(0) $ug_ctr_stype(CHAMFER)
 }

#
# Data for Back Countersink
#
  set dbc_cutter_insert_size(0)       [ASC_ask_att_val IS  $db_row "%$::double_precision_format" 0 flag]
  set dbc_cutter_min_hole_diameter(0) [ASC_ask_att_val MHD $db_row "%$::double_precision_format" 0 flag]

#
# Data for Boring Bar
#
  set dbc_cutter_front_insert_length(0)    [ASC_ask_att_val FIL  $db_row "%$::double_precision_format" 0 flag]
  set dbc_cutter_back_insert_length(0)     [ASC_ask_att_val BIL $db_row "%$::double_precision_format" 0 flag]
  set dbc_cutter_relief_length(0)          [ASC_ask_att_val RL $db_row "%$::double_precision_format" 0 flag]
  set dbc_cutter_relief_width(0)           [ASC_ask_att_val RW $db_row "%$::double_precision_format" 0 flag]

  set lead_angle [ASC_ask_att_val LA $db_row "%$::double_precision_format" 0 flag]
  set dbc_cutter_lead_angle(0) [UGLIB_convert_deg_to_rad $lead_angle]

  set insert_angle [ASC_ask_att_val IA $db_row "%$::double_precision_format" 0 flag]
  set dbc_cutter_insert_angle(0) [UGLIB_convert_deg_to_rad $insert_angle]

#
#
# Turning std
#
# Nose Radius (also for threading)
#
  set dbc_cutter_nose_rad(0) [ASC_ask_att_val NOSR $db_row  "%$::double_precision_format" 1 flag]
  set dbc_cutter_thread_nose_rad(0)  $dbc_cutter_nose_rad(0)

#
# Nose Angle
#
  set angle [ASC_ask_att_val NOSA $db_row  "%$::double_precision_format" 80 flag]
  set dbc_cutter_nose_ang(0) [UGLIB_convert_deg_to_rad $angle]

#
# Orientation Angle
#
  set angle [ASC_ask_att_val OA $db_row "%$::double_precision_format" 5 flag]
  set dbc_cutter_orientation(0) [UGLIB_convert_deg_to_rad $angle]

#
# Tracking Point
#
  set dbc_cutter_tracking_point(0) [ASC_ask_att_val TP $db_row "%$::double_precision_format" 3 flag]

#
# insert length for grooving
  set dbc_cutter_insert_length(0) \
      [ASC_ask_att_val IL $db_row  "%$::double_precision_format" 10 flag]

# 
# Insert position for turning tools (topside=0, downside=1)
#
  set dbc_cutter_insert_position(0) [ASC_ask_att_val INSP $db_row "" 0 flag]

#
# Inserttype
#
  if {  $dbc_cutter_type(0) == $ug_ctr_type(TURN) } \
  {
     set type [ASC_ask_att_val IT $db_row "" "C" flag]
     set dbc_cutter_inserttype(0) [UGLIB_convert_inserttype $type]
  } \
  else \
  {
     set dbc_cutter_inserttype(0) 0

     if { $dbc_cutter_type(0) == $ug_ctr_type(GROOVE) } \
     {
        if { $dbc_cutter_subtype(0) == $ug_ctr_stype(GROOVE_FNR) } \
        {
            set dbc_cutter_inserttype(0) 1
        } \
        elseif { $dbc_cutter_subtype(0) == $ug_ctr_stype(GROOVE_RING) } \
        {
            set dbc_cutter_inserttype(0) 2
        } \
        elseif { $dbc_cutter_subtype(0) == $ug_ctr_stype(GROOVE_USER) } \
        {
            set dbc_cutter_inserttype(0) 3
        } \
        else \
        {
            set dbc_cutter_inserttype(0) 0
        }
     } \
     elseif { $dbc_cutter_type(0) == $ug_ctr_type(THREAD) } \
     {
        if { $dbc_cutter_subtype(0) == $ug_ctr_stype(THREAD_TRAP) } \
        {
           set dbc_cutter_inserttype(0) 1
        }
     }
  }

#
# Cut Edge Length or inscribed circle
#
  set dbc_cutter_cut_edge_length(0) \
      [ASC_ask_att_val CLEN $db_row  "%$::double_precision_format" 10 flag]

  set ic_dia \
      [ASC_ask_att_val IC $db_row  "%$::double_precision_format" 10 flag1]
  
  if { $flag1 == 1 } \
  {
#     if inscribed circle is specified then we always compute 
#     the cut edge length and set the flag that the user wants to see the 
#     inscribed circle in the UG tool dialog
    
#     Default cut edge length for unknown inserttypes
#     is the specified value or the IC

      set def_val $ic_dia
      if { $flag == 1 } { set def_val $dbc_cutter_cut_edge_length(0) }

      set dbc_cutter_cut_edge_length(0) \
          [UGLIB_convert_ic2cut_edge_length $ic_dia \
                                            $dbc_cutter_inserttype(0) \
                                            $dbc_cutter_nose_ang(0)   \
                                            $def_val] 

#     show inscribed circle in tool dialog
      set dbc_cutter_size_opt(0) 1 

  } \
  else \
  {
#     show cut edge length in tool dialog
      set dbc_cutter_size_opt(0) 0 

  }

#  Initial edge angle and length
  set tmp [ASC_ask_att_val IEA $db_row "%$::double_precision_format" 0.0 flag]
  set dbc_cutter_initial_edge_angle(0) [UGLIB_convert_deg_to_rad $tmp]
  set dbc_cutter_initial_edge_length(0) [ASC_ask_att_val IEL $db_row "%$::double_precision_format" 0.0 flag]

#
# Thickness
#
  set def_val 6.35
  if { $dbc_cutter_ass_units == 1 } { set def_val 0.25 }
  set dbc_cutter_thickness(0) [ASC_ask_att_val THCK $db_row  "%$::double_precision_format" $def_val flag]

  if {  $dbc_cutter_type(0) == $ug_ctr_type(TURN) && \
      ( $dbc_cutter_subtype(0) == $ug_ctr_stype(TURN_STD) || \
        $dbc_cutter_subtype(0) == $ug_ctr_stype(TURN_BUTTON) \
      ) \
     } \
    {
       set type [ASC_ask_att_val THCT $db_row "" "(06)" flag1]
       # set dbc_cutter_thickness_type(0) [UGLIB_convert_thickness_type $type]

       # Check if value and type is consistent and set the globals
       UGLIB_set_thickness_type_and_value $dbc_cutter_thickness(0) $flag \
                                          $type $flag1 $dbc_cutter_ass_units
    }

#
# Relief Angle
#
  set angle [ASC_ask_att_val RELA $db_row "%$::double_precision_format" 3 flag]
  # set dbc_cutter_relief_ang(0) [UGLIB_convert_deg_to_rad $angle]

  set type [ASC_ask_att_val RELT $db_row "" "A" flag1]
  # set dbc_cutter_relief_ang_type(0) [UGLIB_convert_relief_angle_type $type]

  # Check if value and type is consistent and set the globals
  UGLIB_set_relief_angle_type_and_value $angle $flag \
                                        $type  $flag1


#
# Max Depth
#
  set dbc_cutter_max_depth(0) [ASC_ask_att_val MXDP $db_row "%$::double_precision_format" 2 flag]
  set dbc_cutter_max_depth_flag(0) $flag
  if {[string trim $dbc_cutter_max_depth(0)] == ""} {
     set dbc_cutter_max_depth_flag(0) 0
  }

#
# Max Toolreach
#
  set dbc_cutter_max_toolreach(0) [ASC_ask_att_val MXTR $db_row "%$::double_precision_format" 50 flag]
  set dbc_cutter_max_toolreach_flag(0) $flag
  if {[string trim $dbc_cutter_max_toolreach(0)] == ""} {
     set dbc_cutter_max_toolreach_flag(0) 0
  }

#
# Min Boring Diameter
#
  set dbc_cutter_min_boring_dia(0) [ASC_ask_att_val MNBD $db_row "%$::double_precision_format" 50 flag]
  set dbc_cutter_min_boring_dia_flag(0) $flag
  if {[string trim $dbc_cutter_min_boring_dia(0)] == ""} {
     set dbc_cutter_min_boring_dia_flag(0) 0
  }

#
# Min/Max Facing Diameter
#
    set dbc_cutter_min_facing_dia(0) [ASC_ask_att_val MNFD $db_row "%$::double_precision_format" 10 flag]
    set dbc_cutter_min_facing_dia_flag(0) $flag 
    if {[string trim $dbc_cutter_min_facing_dia(0)] == ""} {
        set dbc_cutter_min_facing_dia_flag(0) 0
    }

    set dbc_cutter_max_facing_dia(0) [ASC_ask_att_val MXFD $db_row "%$::double_precision_format" 20 flag]
    set dbc_cutter_max_facing_dia_flag(0) $flag 
    if {[string trim $dbc_cutter_max_facing_dia(0)] == ""} {
        set dbc_cutter_max_facing_dia_flag(0) 0
    }

#
# X Offset
#
  set dbc_cutter_x_offset(0) [ASC_ask_att_val XOFF $db_row "%$::double_precision_format" 100 flag]
  set dbc_cutter_x_offset_flag(0) $flag

# X Mount
  set dbc_cutter_xmount(0) [ASC_ask_att_val XMOUNT $db_row "%$::double_precision_format" 0.0 flag]

# for grooving
  if { $dbc_cutter_type(0)    == $ug_ctr_type(GROOVE) && \
       $dbc_cutter_subtype(0) == $ug_ctr_stype(GROOVE_FNR) } \
  {
#      for Full Nose Radius we have left = right = x
       set dbc_cutter_left_xoff(0)  $dbc_cutter_x_offset(0)
       set dbc_cutter_left_xoff_flag(0)  $flag
       set dbc_cutter_right_xoff(0)  $dbc_cutter_x_offset(0)
       set dbc_cutter_right_xoff_flag(0)  $flag
  } \
  else \
  {
     set dbc_cutter_left_xoff(0) [ASC_ask_att_val LXOFF $db_row  "%$::double_precision_format" 100 flag]
     set dbc_cutter_left_xoff_flag(0)  $flag
     set dbc_cutter_right_xoff(0) [ASC_ask_att_val RXOFF $db_row "%$::double_precision_format" 100 flag]
     set dbc_cutter_right_xoff_flag(0)  $flag
  }

#
# Y Offset
#
  set dbc_cutter_y_offset(0) [ASC_ask_att_val YOFF $db_row "%$::double_precision_format" 100 flag]
  set dbc_cutter_y_offset_flag(0) $flag

# Y Mount
  set dbc_cutter_ymount(0)  [ASC_ask_att_val YMOUNT $db_row "%$::double_precision_format" 0.0 flag]

# for grooving

  if { $dbc_cutter_type(0)    == $ug_ctr_type(GROOVE) && \
       $dbc_cutter_subtype(0) == $ug_ctr_stype(GROOVE_FNR) } \
  {
#      for Full Nose Radius we have left = right = y
       set dbc_cutter_left_yoff(0)  $dbc_cutter_y_offset(0)
       set dbc_cutter_left_yoff_flag(0)  $flag
       set dbc_cutter_right_yoff(0)  $dbc_cutter_y_offset(0)
       set dbc_cutter_right_yoff_flag(0)  $flag
  } \
  else \
  {
    set dbc_cutter_left_yoff(0) [ASC_ask_att_val LYOFF $db_row  "%$::double_precision_format" 100 flag]
    set dbc_cutter_left_yoff_flag(0)  $flag
    set dbc_cutter_right_yoff(0) [ASC_ask_att_val RYOFF $db_row "%$::double_precision_format" 100 flag]
    set dbc_cutter_right_yoff_flag(0)  $flag
  }

#
# Some grooving data
#

#
# Insert width
#
  set dbc_cutter_insert_width(0) [ASC_ask_att_val IW $db_row "%$::double_precision_format" 3 flag]
#
#   For a full nose radius cutter we have insert width = 2 * radius
#   <JM PR4415554>but only if IW is not explicitely specified
    if { $flag == 0 } \
    {
        if {  $dbc_cutter_type(0)    == $ug_ctr_type(GROOVE) &&   \
              $dbc_cutter_subtype(0) == $ug_ctr_stype(GROOVE_FNR) } \
        {
              set radius [ASC_ask_att_val RAD $db_row "%$::double_precision_format" 1 flag]
	      set dbc_cutter_insert_width(0) [expr 2 * $radius]
        }
    }

#
# Side angle left and right
#
  set angle [ASC_ask_att_val LSA $db_row "%$::double_precision_format" 0 flag1]
  set dbc_cutter_left_ang(0) [UGLIB_convert_deg_to_rad $angle]

  set angle [ASC_ask_att_val RSA $db_row "%$::double_precision_format" 0 flag2]
  set dbc_cutter_right_ang(0) [UGLIB_convert_deg_to_rad $angle]

  if { $flag1 == 1  &&  $flag2 == 0 } \
  {
       set dbc_cutter_right_ang(0)  $dbc_cutter_left_ang(0)
  } \
  elseif {  $flag1 == 0  &&  $flag2 == 1 } \
  {
       set dbc_cutter_left_ang(0)  $dbc_cutter_right_ang(0)
  }

  set dbc_cutter_side_ang(0)   $dbc_cutter_left_ang(0)

#
# Corner radius for grooving
#
  set dbc_cutter_left_cor_rad(0)  [ASC_ask_att_val COR  $db_row  "%$::double_precision_format" 0 flag1]
  set dbc_cutter_right_cor_rad(0) [ASC_ask_att_val COR2 $db_row  "%$::double_precision_format" 0 flag2]
  if { $flag1 == 1  &&  $flag2 == 0 } \
  {
      set dbc_cutter_right_cor_rad(0) $dbc_cutter_left_cor_rad(0) 
  } \
  elseif {  $flag1 == 0  &&  $flag2 == 1 } \
  {
      set dbc_cutter_left_cor_rad(0) $dbc_cutter_right_cor_rad(0) 
  }

  set dbc_cutter_radius(0) $dbc_cutter_left_cor_rad(0)

#
# Cutter preset and tracking point
#
  set preset [ASC_ask_att_val PSET $db_row  "" 0 flag]
  UGLIB_compute_tracking_side $dbc_cutter_tracking_point(0) \
                              $preset \
                              [UGLIB_convert_rad_to_deg $dbc_cutter_orientation(0)] \
                              dbc_cutter_preset(0) \
                              dbc_cutter_left_tp(0) \
                              dbc_cutter_right_tp(0)

#
# Edit <17-Mar-2009> Full Nose Radius is of type grooving but it has only 
# one TP. We make sure that dbc_cutter_left_tp is the one specified in the DB
# The value from the DB is on dbc_cutter_tracking_point(0)
#
  if {  $dbc_cutter_type(0)    == $ug_ctr_type(GROOVE) &&   \
        $dbc_cutter_subtype(0) == $ug_ctr_stype(GROOVE_FNR) } \
  {
       if { $dbc_cutter_left_tp(0)  != $dbc_cutter_tracking_point(0) } \
       {
             set dbc_cutter_right_tp(0) $dbc_cutter_left_tp(0)
             set dbc_cutter_left_tp(0)  $dbc_cutter_tracking_point(0)
       }
  }


#  For Parting tools, only one tracking point is defined, so return
#    the X and Y offsets in the appropriate side variables
  if { $lib_type == $uglib_tl_type(TURN) && \
       $lib_subtype == $uglib_tl_stype(PARTING)} \
  {
      if { $preset == "L" } \
      {
          set dbc_cutter_right_xoff(0) $dbc_cutter_x_offset(0)
          set dbc_cutter_right_xoff_flag(0) $dbc_cutter_x_offset_flag(0)
          set dbc_cutter_right_yoff(0) $dbc_cutter_y_offset(0)
          set dbc_cutter_right_yoff_flag(0) $dbc_cutter_y_offset_flag(0)
      } else \
      {
          set dbc_cutter_left_xoff(0) $dbc_cutter_x_offset(0)
          set dbc_cutter_left_xoff_flag(0) $dbc_cutter_x_offset_flag(0)
          set dbc_cutter_left_yoff(0) $dbc_cutter_y_offset(0)
          set dbc_cutter_left_yoff_flag(0) $dbc_cutter_y_offset_flag(0)
      }
  }

#
# Tip Angle for grooving cutters
#
  set angle [ASC_ask_att_val TIPA $db_row "%$::double_precision_format" 0 flag]
  if { $lib_subtype != $uglib_tl_stype(FACE_GROOVE) && $dbc_cutter_preset(0) == 2 } \
  {
#     For left cutters we have to negate the angle
      set angle [expr $angle * (-1)]
  }

  set dbc_cutter_tip_ang(0) [UGLIB_convert_deg_to_rad $angle]

# Button Tools (turning)
#
# Button Diameter
#
  set dbc_cutter_button_diameter(0) [ASC_ask_att_val BTDIA $db_row "%$::double_precision_format" 0 flag]
#
# Button Holder Angle
#
  set angle [ASC_ask_att_val BTHA $db_row "%$::double_precision_format" 0 flag]
  set dbc_cutter_holder_angle(0) [UGLIB_convert_deg_to_rad $angle]
#
# Button Holder Width
#
  set dbc_cutter_holder_width(0) [ASC_ask_att_val BTHW $db_row "%$::double_precision_format" 0 flag]

#
#  Index Notch and incremental turret rotation
#
  set dbc_cutter_index_notch(0)     [ASC_ask_att_val INDXNTCH  $db_row "%$::double_precision_format" 0 flag]
  set dbc_cutter_turret_rotation(0) [ASC_ask_att_val TURRETROT $db_row "%$::double_precision_format" 0 flag]

#
#  Set Tool Parameters for New Hole Making Tools
#
   if {$dbc_cutter_type(0)    == $ug_ctr_type(DRILL)} {
       set_drilling_para $db_row
   }

#  Set tapered shank diameter
  ASC_retrieve_shank_data $db_row

# Set machining parameters
  ASC_retrieve_machining_parameters $db_row

# Set laser tool data
  ASC_retrieve_laser_tool_data $db_row
  
 
# Set fused deposition data
  ASC_retrieve_fused_deposition_parameters $db_row
}


proc set_drilling_para { db_row } \
{
  global dbc_lib_tool_diameter
  global dbc_lib_tool_length
  global dbc_lib_tool_flute_length
  global dbc_lib_tool_direction
  global dbc_lib_tool_flutes_number
  global dbc_lib_tool_pilot_diameter
  global dbc_lib_tool_pilot_length
  global dbc_lib_tool_coolant_through
  global dbc_lib_tool_z-offset
  global dbc_lib_tool_x-offset
  global dbc_lib_tool_corner1_radius
  global dbc_lib_tool_point_angle
  global dbc_lib_tool_point_length
  global dbc_lib_tool_tip_angle
  global dbc_lib_tool_included_angle
  global dbc_lib_tool_tip_diameter
  global dbc_lib_tool_tip_length
  global dbc_lib_tool_bell_diameter
  global dbc_lib_tool_bell_angle
  global dbc_lib_tool_shank_diameter
  global dbc_lib_tool_taper_angle
  global dbc_lib_tool_taper_diameter_distance
  global dbc_lib_tool_pitch
  global dbc_lib_tool_thread_forming_method
  global dbc_lib_tool_cutting_diameter
  global dbc_lib_tool_insert_length
  global dbc_lib_tool_form_type
  global dbc_lib_tool_thread_form_name
  global dbc_lib_tool_number_of_teeth
  global dbc_lib_tool_step_diameter
  global dbc_lib_tool_step_height
  global dbc_lib_tool_step_angle
  global dbc_lib_tool_step_radius
  global dbc_lib_tool_holder_diameter
  global dbc_lib_tool_holder_length
  global dbc_lib_tool_holder_taper
  global dbc_lib_tool_holder_offset
  global dbc_lib_tool_designation

  global dbc_cutter_subtype

  global ug_ctr_stype

# Set Common Parameters for all Drill Type Tools
# Tool Diameter ( DIA in the table )
#
      set dbc_lib_tool_diameter(0) [ASC_ask_att_val DIA $db_row "%$::double_precision_format" 10.939 flag]
#
# Number of Flutes
#
      set dbc_lib_tool_flutes_number(0) [ASC_ask_att_val FN $db_row "" 1 flag]
#
# Direction of rotation (1 clockwise, 2 counterclockwise)
#
  set direction [ASC_ask_att_val DROT $db_row "" 1 flag]

      if { $direction == "03" || $direction == "3"} \
         {
#            right
             set dbc_lib_tool_direction(0) 1
         } \
         elseif { $direction == "04" || $direction == "4"} \
         {
#            left
             set dbc_lib_tool_direction(0) 2
         }
#
# Height
#
  set def_val [expr 3 * $dbc_lib_tool_diameter(0)]
  set dbc_lib_tool_length(0) [ASC_ask_att_val HEI $db_row "%$::double_precision_format" $def_val flag]
#
# Flute Length
#
  set def_val [expr 0.5 * $dbc_lib_tool_length(0)]
  set dbc_lib_tool_flute_length(0) [ASC_ask_att_val FLEN $db_row "%$::double_precision_format" $def_val flag]

#
# Drill Point Angle and Point Length
# 
# We need to check the consistency of PA and PL for drills except core drill 
  if { $dbc_cutter_subtype(0) != $ug_ctr_stype(DRILL_CORE_DRILL) }   \
  {
#     Check consistency of these two field, according to the following rules,
#	    If PL or PA is blank - use the other
#	    If PL and PA are inconsistent, use PA and calculate PL.
#	    Round-off errors must not be introduced. If both are present, read PA, 
#	    calculate PL, compare to PL in library. If within tolerance, use PA and PL from library.
      set angle [ASC_ask_att_val PNTA $db_row   "%$::double_precision_format" 180 point_angle_exist]
      set point_angle [UGLIB_convert_deg_to_rad $angle]
      set point_length [ASC_ask_att_val PNTL $db_row   "%$::double_precision_format"  0  point_length_exist]

      if { $dbc_cutter_subtype(0) == $ug_ctr_stype(DRILL_STEP_DRILL) ||  \
          $dbc_cutter_subtype(0) == $ug_ctr_stype(DRILL_CENTER_BELL) } \
      {
          set dbc_lib_tool_tip_diameter(0) [ASC_ask_att_val DIA $db_row "%$::double_precision_format" 10.939 flag]
          set diameter $dbc_lib_tool_tip_diameter(0)
      }                                                                    \
      else                                                                 \
      { 
          set diameter $dbc_lib_tool_diameter(0)
      }

      if { $point_angle_exist != "0" && $point_length_exist == "0" } \
      {    
          if { $point_angle == 0 } \
          {
              set point_length 0
          } \
          else \
          {
              set point_length [expr 0.5 * $diameter / tan( 0.5 * $point_angle)] 
          }
      }

      if { $point_angle_exist == "0" && $point_length_exist != "0" } \
      {                                                             
          set point_angle [expr atan(0.5 * $diameter / $point_length) * 2] 
      }

      if { $point_angle == 0 } \
      {
          set calculated_point_length 0
      } \
      else \
      {
          set calculated_point_length [expr 0.5 * $diameter / tan( 0.5 * $point_angle)]
      }

      if { $point_length < [expr $calculated_point_length - 0.001] \
              || $point_length > [expr $calculated_point_length + 0.001] } \
      {                                                                 
          set point_length $calculated_point_length                     
      }
  }                                                                         \
  else                                                                      \
  {
#     For Core Drill the default point angle is 90.
      set angle [ASC_ask_att_val PNTA $db_row   "%$::double_precision_format" 90 point_angle_exist]
      set point_angle [UGLIB_convert_deg_to_rad $angle]
      set point_length [ASC_ask_att_val PNTL $db_row   "%$::double_precision_format"  0  point_length_exist]
  }
          
  set dbc_lib_tool_point_angle(0) $point_angle
  set dbc_lib_tool_point_length(0) $point_length

# Holder Information
#
# Holder Diameter
#
  set dbc_lib_tool_holder_diameter(0) [ASC_ask_att_val HDIA $db_row "%$::double_precision_format" 0 flag]
#
# Holder Length
#
  set dbc_lib_tool_holder_length(0) [ASC_ask_att_val HLEN $db_row "%$::double_precision_format" 0 flag]
#
# Holder Taper
#
  set angle [ASC_ask_att_val HTAP $db_row "%$::double_precision_format" 0 flag]
  set dbc_lib_tool_holder_taper(0) [UGLIB_convert_deg_to_rad $angle]
#
# Holder offset
#
  set dbc_lib_tool_holder_offset(0) [ASC_ask_att_val HOFF $db_row "%$::double_precision_format" 0 flag]

#
# Corner radius
  set dbc_lib_tool_corner1_radius(0) [ASC_ask_att_val COR1 $db_row "%$::double_precision_format" 0 flag]

#
#  Shank diameter
  set dbc_lib_tool_shank_diameter(0) \
         [ASC_ask_att_val SDIA $db_row "%$::double_precision_format" $dbc_lib_tool_diameter(0) flag]

#
#  Pilot Diameter and Length
   set dbc_lib_tool_pilot_diameter(0) [ASC_ask_att_val PD $db_row "%$::double_precision_format" 0 flag]
   set dbc_lib_tool_pilot_length(0) \
       [ASC_ask_att_val PL $db_row "%$::double_precision_format" $dbc_lib_tool_pilot_diameter(0) flag]

#
#  Thread type and thread name
   set t_type [ASC_ask_att_val THRDS $db_row "%d" 0 flag]
   set dbc_lib_tool_thread_form_name(0) [ASC_ask_att_val THRDES $db_row "" "" flag]
   if { $dbc_cutter_subtype(0) != $ug_ctr_stype(DRILL_TAP) }   \
   {
	   if { $t_type == 1 && $dbc_lib_tool_thread_form_name(0) == "ISO Metric 60" } {
			set dbc_lib_tool_form_type(0) [UGLIB_map_thread_type $t_type]
	   } elseif { $t_type == 1 && $dbc_lib_tool_thread_form_name(0) == "M - ISO Metric 60 deg" } {
			set dbc_lib_tool_form_type(0) [UGLIB_map_thread_type $t_type]
	   } elseif { $t_type == 5 && $dbc_lib_tool_thread_form_name(0) == "UNC Un. Coarse Thread 60" } {
			set dbc_lib_tool_form_type(0) [UGLIB_map_thread_type $t_type]
	   } else {
			set dbc_lib_tool_form_type(0) $t_type
	   }
   } \
   else \
   {    
       set dbc_lib_tool_form_type(0) [UGLIB_map_thread_type $t_type]
   }

   set dbc_lib_tool_thread_form_name(0) [ASC_ask_att_val THRDES $db_row "" "" flag]

#
#  Sub Type specific parameters
#
       if { $dbc_cutter_subtype(0) == $ug_ctr_stype(DRILL_CENTER_BELL) } \
       {

           set dbc_lib_tool_designation(0) [ASC_ask_att_val DESI $db_row "" "" flag]

           set dbc_lib_tool_tip_diameter(0) [ASC_ask_att_val DIA $db_row "%$::double_precision_format" 10.939 flag]
# Shank Diameter ( DIA2 in the table )
#
           set dbc_lib_tool_diameter(0) [ASC_ask_att_val DIA2 $db_row "%$::double_precision_format" 10.939 flag]
           set dbc_lib_tool_shank_diameter(0) $dbc_lib_tool_diameter(0)
#
#          Tip Length
#
           set def_val [expr 0.5 * $dbc_lib_tool_length(0)]
           set dbc_lib_tool_tip_length(0) [ASC_ask_att_val TIPLEN $db_row "%$::double_precision_format" $def_val flag]
#
#          Included Angle - For Type A center Drills the included angle is 60 Degs.
#
           set angle [ASC_ask_att_val INCA $db_row "%$::double_precision_format" 60 flag]
           set dbc_lib_tool_included_angle(0) [UGLIB_convert_deg_to_rad $angle]
#
# Tip Angle is related to Point Angle
#
           set angle [ASC_ask_att_val PNTA $db_row   "%$::double_precision_format" 180 flag]
           set angle [expr 90.0 - $angle * 0.5]
           set dbc_lib_tool_tip_angle(0) [UGLIB_convert_deg_to_rad $angle]

# Bell Angle and Bell Diameter
           set angle [ASC_ask_att_val BANG $db_row  "%$::double_precision_format" 0.0 flag]
           set dbc_lib_tool_bell_angle(0) [UGLIB_convert_deg_to_rad $angle]
           set dbc_lib_tool_bell_diameter(0) [ASC_ask_att_val BDIA $db_row "%$::double_precision_format" 0.0 flag]

# Flute Length
           set def_val 0.0 
           set dbc_lib_tool_flute_length(0) [ASC_ask_att_val FLEN $db_row "%$::double_precision_format" $def_val flag]

#          dbc_lib_tool_corner1_radius
#          dbc_lib_tool_shank_diameter
#          dbc_lib_tool_taper_angle
        } \
        elseif { $dbc_cutter_subtype(0) == $ug_ctr_stype(DRILL_COUNTERSINK) } \
        {
#
#          Tool Diameter ( DIA in the table )
#
           set dbc_lib_tool_diameter(0) [ASC_ask_att_val DIA $db_row "%$::double_precision_format" 10.939 flag]
#
#
#          Included Angle -  Is the Point Angle for CounterSunk Tools
#
           set angle [ASC_ask_att_val PNTA $db_row   "%$::double_precision_format" 180 flag]
           set dbc_lib_tool_included_angle(0) [UGLIB_convert_deg_to_rad $angle]
#
#          Tip Diameter ( DIA in the table )
#
           set dbc_lib_tool_tip_diameter(0) [ASC_ask_att_val DIA2 $db_row "%$::double_precision_format" 10.939 flag]

#          Flute Length
           
           set def_val 0.0 
           set dbc_lib_tool_flute_length(0) [ASC_ask_att_val FLEN $db_row "%$::double_precision_format" $def_val flag]
        } \
        elseif { $dbc_cutter_subtype(0) == $ug_ctr_stype(DRILL_REAM) } \
        {
#
#          Tool Shank Diameter
#
           set def_val $dbc_lib_tool_diameter(0)
           set dbc_lib_tool_shank_diameter(0) [ASC_ask_att_val SDIA $db_row "%$::double_precision_format" $def_val flag]

#
#          Tip Length
#
           set def_val [expr 0.2 * $dbc_lib_tool_diameter(0)]
           set dbc_lib_tool_tip_length(0) [ASC_ask_att_val TIPLEN $db_row "%$::double_precision_format" $def_val flag]

#
#          Taper Diameter Distance
#
           set def_val $dbc_lib_tool_flute_length(0)
           set dbc_lib_tool_taper_diameter_distance(0) [ASC_ask_att_val TDD $db_row "%$::double_precision_format" $def_val flag]

           #Taper Angle
           set angle [ASC_ask_att_val TAPA $db_row "%$::double_precision_format" 0.0 flag]
           set dbc_lib_tool_taper_angle(0) [UGLIB_convert_deg_to_rad $angle]
#
        } \
        elseif { $dbc_cutter_subtype(0) == $ug_ctr_stype(DRILL_TAP) } \
        {
           set dbc_lib_tool_designation(0) [ASC_ask_att_val DESI $db_row "" "" flag]
#
#          Tool Shank Diameter
#
           set def_val $dbc_lib_tool_diameter(0)
           set dbc_lib_tool_shank_diameter(0) [ASC_ask_att_val SDIA $db_row "%$::double_precision_format" $def_val flag]
#
#          Pitch
#
           set dbc_lib_tool_pitch(0) [ASC_ask_att_val PIT $db_row "%$::double_precision_format" 10.939 flag]

#
#          Tip Length
#
           set def_val [expr 0.2 * $dbc_lib_tool_diameter(0)]
           set dbc_lib_tool_tip_length(0) [ASC_ask_att_val TIPLEN $db_row "%$::double_precision_format" $def_val flag]

#
#          Taper Diameter Distance
#
           set def_val $dbc_lib_tool_flute_length(0)
           set dbc_lib_tool_taper_diameter_distance(0) [ASC_ask_att_val TDD $db_row "%$::double_precision_format" $def_val flag]

           #Taper Angle
           set angle [ASC_ask_att_val TAPA $db_row "%$::double_precision_format" 0.0 flag]
           set dbc_lib_tool_taper_angle(0) [UGLIB_convert_deg_to_rad $angle]

           #Include Angle and Tip Diameter
           #     Check consistency of these two field, according to the following rules,
           #	    If INCA or DIA2 is blank - use the other
           #	    Round-off errors must not be introduced. If both are present, read INCA, 
           #	    calculate DIA2, compare to DIA2 in library. If within tolerance, 
           #	    use INCA and DIA2 from library.
           set angle [ASC_ask_att_val INCA $db_row   "%$::double_precision_format" 90.0 included_angle_exist]
           set included_angle [UGLIB_convert_deg_to_rad $angle]
           set tip_diameter [ASC_ask_att_val DIA2 $db_row   "%$::double_precision_format"  0  tip_diameter_exist]

           if { $included_angle_exist != "0" && $tip_diameter_exist == "0" } \
               {                                                             
               set tip_diameter [ expr $dbc_lib_tool_diameter(0) - 2.0 * $dbc_lib_tool_tip_length(0) \
                                    * tan( 0.5 * $included_angle ) - 2.0 * \
                                    ( $dbc_lib_tool_taper_diameter_distance(0) - $dbc_lib_tool_tip_length(0) ) \
                                    * tan($dbc_lib_tool_taper_angle(0)) ] 
           }

           if { $included_angle_exist == "0" && $tip_diameter_exist != "0" } \
               {                                                             
               set included_angle [ expr 2.0 * atan(( $dbc_lib_tool_diameter(0) - $tip_diameter -  \
                                    2.0 * ($dbc_lib_tool_taper_diameter_distance(0) - $dbc_lib_tool_tip_length(0) )  \
                                    * tan($dbc_lib_tool_taper_angle(0)) ) / (2.0 * $dbc_lib_tool_tip_length(0))) ] 
           }

           set calculated_tip_diameter [ expr $dbc_lib_tool_diameter(0) - 2.0 * $dbc_lib_tool_tip_length(0) \
                                            * tan( 0.5 * $included_angle ) - 2.0 * \
                                            ( $dbc_lib_tool_taper_diameter_distance(0) - $dbc_lib_tool_tip_length(0) ) \
                                            * tan($dbc_lib_tool_taper_angle(0)) ] 

           if { $tip_diameter < [expr $calculated_tip_diameter - 0.001] \
               || $tip_diameter > [expr $calculated_tip_diameter + 0.001] } \
               {                                                                 
               set tip_diameter $calculated_tip_diameter                     
           }

           set dbc_lib_tool_included_angle(0) $included_angle
           set dbc_lib_tool_tip_diameter(0) $tip_diameter

        } \
        elseif { $dbc_cutter_subtype(0) == $ug_ctr_stype(DRILL_SPOT_FACE) } \
        {
#
#          Tool Diameter ( DIA in the table )
#
           set dbc_lib_tool_diameter(0) [ASC_ask_att_val DIA $db_row "%$::double_precision_format" 10.939 flag]
#
        } \
        elseif { $dbc_cutter_subtype(0) == $ug_ctr_stype(DRILL_SPOT_DRILL) } \
        {
#
#          Tool Diameter ( DIA in the table )
#
           set dbc_lib_tool_diameter(0) [ASC_ask_att_val DIA $db_row "%$::double_precision_format" 10.939 flag]

#          Flute Length
           
           set def_val 0.0 
           set dbc_lib_tool_flute_length(0) [ASC_ask_att_val FLEN $db_row "%$::double_precision_format" $def_val flag]
        } \
        elseif { $dbc_cutter_subtype(0) == $ug_ctr_stype(DRILL_THREAD_MILL) } \
        {
           set dbc_lib_tool_designation(0) [ASC_ask_att_val DESI $db_row "" "" flag]
#
#          Tool Shank Diameter ( SDIA in the table )
#
           set dbc_lib_tool_shank_diameter(0) [ASC_ask_att_val SDIA $db_row "%$::double_precision_format" 10.939 flag]
#
#          Pitch ( PIT in the table )
#
           set dbc_lib_tool_pitch(0) [ASC_ask_att_val PIT $db_row "%$::double_precision_format" 10.939 flag]
#
        } \
        elseif {$dbc_cutter_subtype(0) == $ug_ctr_stype(DRILL_BORE)} \
        {
            set dbc_lib_tool_corner1_radius(0) [ASC_ask_att_val COR $db_row "%$::double_precision_format" 0 flag]
        } \
        elseif { $dbc_cutter_subtype(0) == $ug_ctr_stype(DRILL_STEP_DRILL) } \
        {
            set dbc_lib_tool_corner1_radius(0) [ASC_ask_att_val COR $db_row "%$::double_precision_format" 0 flag]
            set_step_drill_para $db_row
        }
}

proc set_step_drill_para { db_row } \
{
   global dbc_lib_tool_flute_length
   global dbc_lib_tool_point_angle
   global dbc_lib_tool_tip_diameter
   global dbc_lib_tool_tip_length
   global dbc_lib_tool_step_diameter
   global dbc_lib_tool_step_height
   global dbc_lib_tool_step_angle
   global dbc_lib_tool_step_radius
   global dbc_lib_tool_shoulder_distance
   global dbc_step_count

  UGLIB_unset_step_drill_paras

#  Initialize step count
    set dbc_step_count 0

# Tool Tip Diameter ( DIA in the table )
#
    set dbc_lib_tool_tip_diameter(0) [ASC_ask_att_val DIA $db_row "%$::double_precision_format" 10.939 flag]
#
# Tip Length( TIPL in the table )
#
    set dbc_lib_tool_tip_length(0) [ASC_ask_att_val TIPL $db_row "%$::double_precision_format" 10.939 flag]
#
# Shoulder Distance( SD in the table )
#
    set dbc_lib_tool_shoulder_distance(0) [ASC_ask_att_val SD $db_row "%$::double_precision_format" 0.0 flag]

#
# calculate step 0 thats the tip

    set tiplen [ASC_ask_att_val TIPLEN $db_row "%$::double_precision_format" 10.939 flag]
    UGLIB_calc_chamfer_step 0.0 $dbc_lib_tool_tip_diameter(0) \
                            $dbc_lib_tool_point_angle(0)  tip_height
    set dbc_lib_tool_tip_length(0) [expr $tiplen + $tip_height]

#
#  Check for the old stype step drill parameters.  Do remaining code only
#    if it is found
    set tmp [ASC_ask_att_val SD1 $db_row "%$::double_precision_format" 0.0 flag]
# Step Parameters
#
    if { $flag == 1 } \
    {
# Step 1
#
# Check if angle ne 180
# 
        set angle    [ASC_ask_att_val SA1 $db_row "%$::double_precision_format" 10.939 flag]
        set dia      [ASC_ask_att_val SD1 $db_row "%$::double_precision_format" 10.939 flag]
        set length   [ASC_ask_att_val SL1 $db_row "%$::double_precision_format" 10.939 flag1]

        set n_inx 1
        if { $flag == 1 } \
        {
             UGLIB_calc_ug_step_parameters $dbc_lib_tool_tip_diameter(0) $dia $angle \
                 n_steps ug_sd1 ug_sa1 ug_sd2 ug_sa2 

             set dbc_lib_tool_step_diameter(0) $ug_sd1
             set dbc_lib_tool_step_angle(0)    $ug_sa1
             set dbc_lib_tool_step_radius(0)   0
             if { $flag1 == 1 } \
             { 
                  set dbc_lib_tool_step_height(0) $length
             } \
             else \
             {
                  set dbc_lib_tool_step_height(0) [expr $dbc_lib_tool_flute_length(0) - \
                                               $dbc_lib_tool_tip_length(0)]
             }

             if { $n_steps > 1 } \
             {
#
#                   Step length ( or height ) for chamfer part
                 UGLIB_calc_chamfer_step $dbc_lib_tool_tip_diameter(0) \
                                     $dia [UGLIB_convert_deg_to_rad $angle] \
                                     dbc_lib_tool_step_height(0)
#
#             
                 set n_inx 2
                 set dbc_lib_tool_step_diameter(1) $ug_sd2
                 set dbc_lib_tool_step_angle(1)    $ug_sa2
                 set dbc_lib_tool_step_radius(1)   0
                
                 set L1       [ASC_ask_att_val SL1 $db_row "%$::double_precision_format" 10.939 flag]
                 if { $flag == 0 } \
                 {
#                        not specified
                      set L1 [expr $dbc_lib_tool_flute_length(0) - \
                               $dbc_lib_tool_step_height(0)  - \
                               $dbc_lib_tool_tip_length(0)]
 
                 }
                 set dbc_lib_tool_step_height(1)   $L1
              }
        }

# Step 2
#
          
        set angle2    [ASC_ask_att_val SA2 $db_row "%$::double_precision_format" 10.939 flag]
        set dia2      [ASC_ask_att_val SD2 $db_row "%$::double_precision_format" 10.939 flag]

        if { $flag == 1 } \
        {

             UGLIB_calc_ug_step_parameters $dia $dia2 $angle2 \
                 n_steps ug_sd1 ug_sa1 ug_sd2 ug_sa2 

             set dbc_lib_tool_step_diameter($n_inx) $ug_sd1
             set dbc_lib_tool_step_angle($n_inx)    $ug_sa1
             set dbc_lib_tool_step_radius($n_inx)   0

             if { $n_inx == 1 } \
             {   
                 set L1 [expr $dbc_lib_tool_flute_length(0) - \
                          $dbc_lib_tool_tip_length(0)   - \
                          $dbc_lib_tool_step_height(0)] 
             } \
             else \
             {
                 set L1 [expr $dbc_lib_tool_flute_length(0) - \
                          $dbc_lib_tool_tip_length(0)   - \
                          $dbc_lib_tool_step_height(0)  - \
                          $dbc_lib_tool_step_height(1) ]
             }
             set dbc_lib_tool_step_height($n_inx)   $L1

             if { $n_steps > 1 } \
             {
                 UGLIB_calc_chamfer_step $dia \
                                     $dia2 [UGLIB_convert_deg_to_rad $angle] \
                                     dbc_lib_tool_step_height($n_inx)

                 incr n_inx
                 set dbc_lib_tool_step_diameter($n_inx) $ug_sd2
                 set dbc_lib_tool_step_angle($n_inx)    $ug_sa2
                 set dbc_lib_tool_step_radius($n_inx)   0
                 if { $n_inx == 2 } \
                 {   
                     set L1 [expr $dbc_lib_tool_flute_length(0) - \
                              $dbc_lib_tool_tip_length(0)   - \
                              $dbc_lib_tool_step_height(0)  - \
                              $dbc_lib_tool_step_height(1)]
                 } \
                 else \
                 {
                     set L1 [expr $dbc_lib_tool_flute_length(0) - \
                              $dbc_lib_tool_tip_length(0)   - \
                              $dbc_lib_tool_step_height(0)  - \
                              $dbc_lib_tool_step_height(1)  - \
                              $dbc_lib_tool_step_height(2)]
                 }
                 set dbc_lib_tool_step_height($n_inx)   $L1
             }
        }
        incr n_inx
        set dbc_step_count $n_inx
    }
}

proc DBC_ask_library_values {} \
{
#
# global input
   global dbc_libref
   global dbc_db_ids_count
   global dbc_db_ids

   global asc_file_loaded
 
#
# global output
   global dbc_db_ids_value

#
# Look for the desired libref
#
    if { $asc_file_loaded == 1 } \
    {
        ASC_array_search_libref $dbc_libref db_row 
    } \
    else \
    {
        ASC_file_search_libref $dbc_libref db_row
    }
#
# and set the desired values
#
    for { set inx 0 } { $inx < $dbc_db_ids_count } { incr inx } \
    {
        set dbc_db_ids_value($dbc_db_ids($inx)) \
           [ASC_ask_att_val $dbc_db_ids($inx) $db_row "" "" flag]
    }
}

#---------------------------------------------
proc DBC_translate_att_alias {} {
#---------------------------------------------

   ASC_translate_att_alias
}

#---------------------------------------------
proc DBC_create_criterion {} {
#---------------------------------------------

    ASC_create_criterion
}

#---------------------------------------------
proc DBC_create_query {} {
#---------------------------------------------

    ASC_create_query
}

#---------------------------------------------
proc DBC_insert {} {
#---------------------------------------------

    ASC_insert
}

#---------------------------------------------
proc DBC_execute_query {} {
#---------------------------------------------

global asc_file_loaded


   if { $asc_file_loaded == 0 } \
   {
       ASC_file_exec_qry 0
   } \
   else \
   {
       ASC_append_unit_to_query
       ASC_execute_query
   }
}

#---------------------------------------------
proc DBC_execute_query_for_count {} {
#---------------------------------------------

global asc_file_loaded


   if { $asc_file_loaded == 0 } \
   {
       ASC_file_exec_qry 1
   } \
   else \
   {
       ASC_append_unit_to_query
       ASC_execute_query_for_count
   }

}


proc ASC_append_unit_to_query {} \
{
global dbc_search_units
global dbc_query
global asc_units

  set lhs "\$asc_database(\$db_row,_unitt)"

  set subquery1 "($lhs == \"$asc_units(unknown)\")"  
  set subquery2 "($lhs == \"$dbc_search_units\")"
 
  set subquery "($subquery1 || $subquery2)"

  set dbc_query "$dbc_query && $subquery"

}

proc ASC_file_exec_qry { for_count } \
{
#
# Executes the query on a file depending on the current setting 
# of the  dbc_search_units
#
# for_count = 1 => do only execute_query_for_count

global dbc_search_units
global asc_units
global asc_mm_file_name
global asc_inch_file_name
global dbc_query_count
global dbc_query
global units_from_query

   if {[info exists units_from_query]} {
      set dbc_search_units $units_from_query
      unset units_from_query
   }

   if { $dbc_search_units == $asc_units(mm) } \
   {
      set file_name  $asc_mm_file_name 
      set units $asc_units(mm)
   } \
   else \
   {
      set file_name  $asc_inch_file_name 
      set units $asc_units(inch)
   }

   set dbc_query_count 0
   if { $for_count == 1 } \
   {
       set ret_cd  [ASC_file_execute_query_for_count $file_name $units]
   } \
   else \
   {
       set ret_cd  [ASC_file_execute_query  $file_name $units]
   }

   if { $ret_cd != 0 } \
   {
        set message "Error, can't open file:"
        set message "$message \n $file_name"
        MOM_abort "\n $message"
   }   
}

proc ASC_file_search_libref { libref db_row_ref } \
{
upvar $db_row_ref db_row

global dbc_search_units
global asc_units
global asc_mm_file_name
global asc_inch_file_name
global asc_file_name


#
# We search in mm and inch file for the desired libref
#
   set found 2
   if { $dbc_search_units == $asc_units(mm) } \
   {
#
#     Start with the mm file
      if { $asc_mm_file_name != "" } \
      {
         set found [ASC_file_find_object_by_att \
                      $asc_mm_file_name $asc_units(mm) \
                      LIBRF $libref db_row]
         if { $found != 0 } \
         {
#              Not found -> Try again with the inch file
               if { $asc_inch_file_name != "" } \
               {
                  set found [ASC_file_find_object_by_att \
                              $asc_inch_file_name $asc_units(inch) \
                              LIBRF $libref db_row]
               }
         }
      }
   } \
   else \
   {
#
#     Start with the inch file
      if { $asc_inch_file_name != "" } \
      {
         set found [ASC_file_find_object_by_att \
                      $asc_inch_file_name $asc_units(inch) \
                      LIBRF $libref db_row]
         if { $found != 0 } \
         {
#              Not found -> Try again with the mm file
               if { $asc_mm_file_name != "" } \
               {
                  set found [ASC_file_find_object_by_att \
                              $asc_mm_file_name $asc_units(mm) \
                              LIBRF $libref db_row]
               }
         }
      }
   }

   if { $found == 2 } \
   {
       set message "Error retrieving tool from external library."
       set message "$message \n Tool with the library reference $libref"
       set message "$message \n does not exist in the"
       set message "$message \n ASCII Data File(s):"
       set message "$message \n $asc_file_name"
       MOM_abort "\n $message"
   }

   if { $found == 1 } \
   {
       set message "Error retrieving tool from external library."
       set message "$message \n Neither of the files"
       set message "$message \n $asc_mm_file_name"
       set message "$message \n $asc_inch_file_name"
       set message "$message \n can be read."
       MOM_abort "\n $message"
   }
}

proc ASC_array_search_libref { libref db_row_ref } \
{
upvar $db_row_ref db_row

global asc_file_name

   set found [ASC_array_find_object_by_att LIBRF $libref db_row ]

   if { $found == 2 } \
   {
       set message "Error retrieving tool from external library."
       set message "$message \n Tool with the library reference $libref"
       set message "$message \n does not exist in the"
       set message "$message \n ASCII Data File(s):"
       set message "$message \n $asc_file_name"
       MOM_abort "\n $message"
   }
}

proc DBC_ask_missing_aliases { } \
{
    global dbc_libref
    ASC_ask_missing_aliases
}

proc DBC_map_class { } \
{
    UGLIB_map_class
}

proc DBC_ask_class_type_and_subtype { } \
{
    UGLIB_ask_class_type_and_subtype
}

proc DBC_ask_class_by_type { } \
{
    global dbc_cutter_type
    global dbc_cutter_subtype
    global dbc_class
    global asc_type
    global asc_subtype

    set asc_type $dbc_cutter_type
    set asc_subtype $dbc_cutter_subtype

    UGLIB_ask_class

#  if no class was found, return UNDEFINED
    if {! [info exists dbc_class] } \
    {
        set dbc_class "UNDEFINED"
    }
}

proc DBC_ask_class { } \
{
    global dbc_libref
    global asc_file_loaded
    global asc_type
    global asc_subtype

# Get the library type and subtype

#
# Look for the desired libref
#
    if { $asc_file_loaded == 1 } \
    {
        ASC_array_search_libref $dbc_libref db_row 
    } \
    else \
    {
        ASC_file_search_libref $dbc_libref db_row
    }
    set asc_type     [ASC_ask_att_val  T $db_row "" 4711 flag]
    set asc_subtype  [ASC_ask_att_val ST $db_row "" 4711ayab flag]

    UGLIB_ask_class
}

#  This proc searches the database for a matching record to the input
#    libref, but returns db_row set to -1 if no match found.
proc ASC_search_libref_no_abort { libref db_row_ref } \
{
    upvar $db_row_ref db_row
    global asc_file_loaded
    global dbc_search_units
    global asc_units
    global asc_mm_file_name
    global asc_inch_file_name
    global asc_file_name

    if { $asc_file_loaded == 1 } \
    {
        set found [ASC_array_find_object_by_att LIBRF $libref db_row ]
    } else \
    {
#
# We search in mm and inch file for the desired libref
#
        set found 2
        if { $dbc_search_units == $asc_units(mm) } \
        {
#
#     Start with the mm file
            if { $asc_mm_file_name != "" } \
            {
                set found [ASC_file_find_object_by_att \
                      $asc_mm_file_name $asc_units(mm) \
                      LIBRF $libref db_row]
                if { $found != 0 } \
                {
#              Not found -> Try again with the inch file
                    if { $asc_inch_file_name != "" } \
                    {
                        set found [ASC_file_find_object_by_att \
                              $asc_inch_file_name $asc_units(inch) \
                              LIBRF $libref db_row]
                    }
                }
            }
        } \
        else \
        {
#
#     Start with the inch file
            if { $asc_inch_file_name != "" } \
            {
                set found [ASC_file_find_object_by_att \
                      $asc_inch_file_name $asc_units(inch) \
                      LIBRF $libref db_row]
                if { $found != 0 } \
                {
#              Not found -> Try again with the mm file
                    if { $asc_mm_file_name != "" } \
                    {
                        set found [ASC_file_find_object_by_att \
                              $asc_mm_file_name $asc_units(mm) \
                              LIBRF $libref db_row]
                    }
                }
            }
        }
    }
#  If we didn't find it, set row reference to -1
    if { $found != 0} \
    {
        set db_row -1
    }
}

#---------------------------------------------
proc DBC_update {} {
#---------------------------------------------

    ASC_update
}

proc ASC_retrieve_shank_data {db_row} {
  global dbc_cutter_tool_tapered_shank_diameter
  global dbc_cutter_tool_tapered_shank_length
  global dbc_cutter_tool_tapered_shank_taper_length

  set dbc_cutter_tool_tapered_shank_diameter(0) [ASC_ask_att_val TSDIA $db_row "%$::double_precision_format" 0 flag]
  set dbc_cutter_tool_tapered_shank_length(0) [ASC_ask_att_val TSLEN $db_row "%$::double_precision_format" 0 flag]
  set dbc_cutter_tool_tapered_shank_taper_length(0) [ASC_ask_att_val TSTLEN $db_row "%$::double_precision_format" 0 flag]
}


proc ASC_retrieve_machining_parameters {db_row} {
  global dbc_cutter_helical_ramp_angle
  global dbc_cutter_min_ramp_length
  global dbc_cutter_min_ramp_length_source
  global dbc_cutter_helical_diameter
  global dbc_cutter_helical_diameter_source
  global dbc_cutter_max_cut_width
  global dbc_cutter_max_cut_width_source

  set dbc_cutter_helical_ramp_angle(0) [ASC_ask_att_val RAMPANGLE $db_row "%$::double_precision_format" 15.0 flag]

  set percent_string "%T"

  set temp [string trim [ASC_ask_att_val HELICALDIA $db_row "%s" "90%T" flag]]
  if [string match "*$percent_string" $temp] {
     set dbc_cutter_helical_diameter_source(0) 1
     set dbc_cutter_helical_diameter(0) [string trimright $temp $percent_string]
  } else {
     set dbc_cutter_helical_diameter_source(0) 0
     set dbc_cutter_helical_diameter(0) $temp
  }

  set temp [string trim [ASC_ask_att_val MINRAMPLEN $db_row "%s" "70%T" flag]]
  if [string match "*$percent_string" $temp] {
     set dbc_cutter_min_ramp_length_source(0) 1
     set dbc_cutter_min_ramp_length(0) [string trimright $temp $percent_string]
  } else {
     set dbc_cutter_min_ramp_length_source(0) 0
     set dbc_cutter_min_ramp_length(0) $temp
  }

  set temp [string trim [ASC_ask_att_val MAXCUTWIDTH $db_row "%s" "50%T" flag]]
  if [string match "*$percent_string" $temp] {
     set dbc_cutter_max_cut_width_source(0) 1
     set dbc_cutter_max_cut_width(0) [string trimright $temp $percent_string]
  } else {
     set dbc_cutter_max_cut_width_source(0) 0
     set dbc_cutter_max_cut_width(0) $temp
  }
}

proc ASC_retrieve_laser_tool_data {db_row} {
  global dbc_laser_nozzle_diameter
  global dbc_laser_nozzle_length
  global dbc_laser_nozzle_tip_diameter
  global dbc_laser_nozzle_taper_length
  global dbc_laser_focal_distance
  global dbc_laser_focal_diameter
  global dbc_laser_minimum_power
  global dbc_laser_maximum_power
  global dbc_laser_standoff_distance
  global dbc_laser_working_diameter
  global dbc_laser_working_range

  set dbc_laser_nozzle_diameter(0) [ASC_ask_att_val ND $db_row "%$::double_precision_format" 0 flag]
  set dbc_laser_nozzle_length(0) [ASC_ask_att_val NL $db_row "%$::double_precision_format" 0 flag]
  set dbc_laser_nozzle_tip_diameter(0) [ASC_ask_att_val NTD $db_row "%$::double_precision_format" 0 flag]
  set dbc_laser_nozzle_taper_length(0) [ASC_ask_att_val NTL $db_row "%$::double_precision_format" 0 flag]
  set dbc_laser_focal_diameter(0) [ASC_ask_att_val FDIA $db_row "%$::double_precision_format" 0 flag]
  set dbc_laser_focal_distance(0) [ASC_ask_att_val FDIS $db_row "%$::double_precision_format" 0 flag]
  set dbc_laser_minimum_power(0) [ASC_ask_att_val MINP $db_row "%$::double_precision_format" 0 flag]
  set dbc_laser_maximum_power(0) [ASC_ask_att_val MAXP $db_row "%$::double_precision_format" 0 flag]
  set dbc_laser_standoff_distance(0) [ASC_ask_att_val SDIST $db_row "%$::double_precision_format" 0 flag]
  set dbc_laser_working_diameter(0) [ASC_ask_att_val WDIA $db_row "%$::double_precision_format" 0 flag]
  set dbc_laser_working_range(0) [ASC_ask_att_val WRANGE $db_row "%$::double_precision_format" 0 flag]
}

proc ASC_retrieve_fused_deposition_parameters {db_row} {
    global dbc_laser_standoff_distance
    global dbc_laser_nozzle_diameter
    global dbc_laser_nozzle_length
    global dbc_laser_nozzle_taper_length
    global dbc_laser_nozzle_tip_diameter
    global dbc_nozzle_orifice_diameter
    global dbc_extrusion_diameter
    global dbc_min_bead_width
    global dbc_max_bead_width
    global dbc_min_bead_height
    global dbc_max_bead_height
    global dbc_min_extrusion_rate
    global dbc_max_extrusion_rate
    
    
    set dbc_laser_standoff_distance(0) [ASC_ask_att_val SDIST $db_row "%$::double_precision_format" 0 flag]
    set dbc_extrusion_diameter(0) [ASC_ask_att_val EDIA $db_row "%$::double_precision_format" 0 flag]
    set dbc_laser_nozzle_diameter(0) [ASC_ask_att_val ND $db_row "%$::double_precision_format" 0 flag]
    set dbc_laser_nozzle_length(0) [ASC_ask_att_val NL $db_row "%$::double_precision_format" 0 flag]
    set dbc_laser_nozzle_tip_diameter(0) [ASC_ask_att_val NTD $db_row "%$::double_precision_format" 0 flag]
    set dbc_laser_nozzle_taper_length(0) [ASC_ask_att_val NTL $db_row "%$::double_precision_format" 0 flag]
    set dbc_nozzle_orifice_diameter(0) [ASC_ask_att_val NOD $db_row "%$::double_precision_format" 0 flag]
    set dbc_min_bead_width(0) [ASC_ask_att_val MINW $db_row "%$::double_precision_format" 0 flag]
    set dbc_max_bead_width(0) [ASC_ask_att_val MAXW $db_row "%$::double_precision_format" 0 flag]
    set dbc_min_bead_height(0) [ASC_ask_att_val MINH $db_row "%$::double_precision_format" 0 flag]
    set dbc_max_bead_height(0) [ASC_ask_att_val MAXH $db_row "%$::double_precision_format" 0 flag]
    set dbc_min_extrusion_rate(0) [ASC_ask_att_val MINER $db_row "%$::double_precision_format" 0 flag]
    set dbc_max_extrusion_rate(0) [ASC_ask_att_val MAXER $db_row "%$::double_precision_format" 0 flag]
}


# To enable the new customization mechanism.
# This should ALWAYS be the last line in the file.
MOM_extend_for_customization UGII_CAM_CUSTOM_LIBRARY_TOOL_ASCII_DIR dbc_custom_tool_ascii.tcl
