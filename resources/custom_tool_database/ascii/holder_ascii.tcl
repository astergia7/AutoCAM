###############################################################################
# holder.tcl - DBC Event Handler for database stored as ascii file
###############################################################################
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
# This is path+name of the holder_database.dat file 
# where a holder gets exported. 
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
        set message "Error looking for a holder_database.dat file."
        set message "$message \n Neither of the environment variables"
        set message "$message \n UGII_CAM_LIBRARY_TOOL_METRIC_DIR,"
        set message "$message \n UGII_CAM_LIBRARY_TOOL_ENGLISH_DIR"
        set message "$message \n is defined."
        MOM_abort "\n $message"
    }

#
# mm file
#
    set app 0
    set mm_file_loaded 0

    set ret_cd [ASC_load_data_file $asc_mm_file_name $asc_units(mm) $app]
    if { $ret_cd != 0 } \
    {
        set message "Error, can't open file:"
        set message "$message \n $asc_mm_file_name"
        MOM_abort "\n $message"
    }
    set app 1
    set mm_file_loaded 1

#
# and then inch file
#
    set inch_file_loaded 0

    set ret_cd [ASC_load_data_file $asc_inch_file_name $asc_units(inch) $app]
    if { $ret_cd != 0 } \
    {
        set message "Error, can't open file:"
        set message "$message \n $asc_inch_file_name"
        MOM_abort "\n $message"
    }
    set inch_file_loaded 1

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
    set fname [append fname $env_var "holder_database.dat"]

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
    ASC_retrieve
}

#---------------------------------------------
proc ASC_retrieve {} {
#---------------------------------------------
#
# global input
# ------------
    global asc_debug
    global asc_units

    global dbc_search_units

    global dbc_libref
    global db_row

    global asc_file_loaded
    global asc_database
    global asc_database_count
    global asc_file_name

    global uglib_holder_type   ;#  UG/Library holder type
    global uglib_holder_stype  ;#  UG/Library holder subtype

#
# global output
# -------------
    global dbc_holder_count   
    global dbc_holder_num_sections
    global dbc_holder_description
    global dbc_holder_max_offset
    global dbc_holder_min_diameter
    global dbc_holder_max_diameter
    global dbc_holder_type
    global dbc_holder_subtype
    global dbc_max_offset
    global dbc_query
    global dbc_query_count
    global dbc_cutter_ass_units

    if { $asc_debug == "1" } \
    {
        puts " =========================================="
        puts " procedure  DBC_retrieve for tool holder"
        puts " libref -> $dbc_libref"
    }

#  initialize section count so we can detect if retrieval failed
    set dbc_holder_num_sections 0

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

    if {$db_row >= 0} \
    {
        set units [ASC_ask_att_val _unitt $db_row "" $asc_units(mm) flag]
        if { "$units" == "$asc_units(mm)" } \
            {
            set dbc_cutter_ass_units 0
        } \
            else \
            {
            set dbc_cutter_ass_units 1
        }


        set dbc_holder_type [ASC_ask_att_val HTYPE $db_row "%d" 0 flag]
        set dbc_holder_subtype [ASC_ask_att_val STYPE $db_row "%d" 0 flag]
        set dbc_holder_description [ASC_ask_att_val \
                DESCR $db_row "" "" flag]
        if {$dbc_holder_type == 1 || $dbc_holder_type == 3 || $dbc_holder_type == 4 || $dbc_holder_type == 5} {
            #milling holder
            set dbc_holder_num_sections [ASC_ask_att_val \
                    SNUM $db_row "%d" 0 flag]
            set dbc_holder_max_offset [ASC_ask_att_val \
                    MAXOFF $db_row "%$::double_precision_format" 0 flag]
            set dbc_holder_min_diameter [ASC_ask_att_val \
                    MINDIA $db_row "%$::double_precision_format" 0 flag]
            set dbc_holder_max_diameter [ASC_ask_att_val \
                    MAXDIA $db_row "%$::double_precision_format" 0 flag]
        }

        ASC_load_holder_data
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
proc DBC_execute_query {} {
#---------------------------------------------


global asc_file_loaded
global dbc_query
global dbc_search_units

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
global dbc_query

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

#--------------------------------------------
proc DBC_insert {} {
#--------------------------------------------
    ASC_insert
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
        set message "Error retrieving holder from external library."
        set message "$message \n Holder with the library reference $libref"
        set message "$message \n does not exist in the"
        set message "$message \n ASCII Data File(s):"
        set message "$message \n $asc_file_name"
        MOM_abort "\n $message"
    }

    if { $found == 1 } \
    {
        set message "Error retrieving holder from external library."
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
        set db_row -1
    }
}


proc ASC_load_holder_data {} \
{
    global dbc_holder_type

    if {$dbc_holder_type == 1 || $dbc_holder_type == 3 || $dbc_holder_type == 4 || $dbc_holder_type == 5} {
        ASC_load_milling_holder_data
    } else {
        ASC_load_turning_holder_data
    }
}

proc ASC_load_milling_holder_data {} \
{
    global dbc_attr_count
    global dbc_attr_aliases
    global dbc_attr_id
    global dbc_libref
    global dbc_query_count

    global dbc_seqno
    global dbc_hld_diam
    global dbc_hld_hgt
    global dbc_hld_taper
    global dbc_hld_corner

    global asc_database_count

#  Initialize environment
    set dbc_query_count 0

#  Cycle database looking for matching data records
    for {set db_row 0} {$db_row < $asc_database_count} { incr db_row 1} \
    {
        set tmp_libref [ASC_ask_att_val LIBRF $db_row "" 0 flag]
        if {$tmp_libref == $dbc_libref} \
        {
            set rtype [ASC_ask_att_val RTYPE $db_row "" 0 flag]
            if {$rtype == "2" } \
            {
                 set dbc_seqno($dbc_query_count) [ASC_ask_att_val SEQ \
                     $db_row "" 0 flag]
                 set dbc_hld_diam($dbc_query_count) [ASC_ask_att_val \
                     DIAM $db_row "" 0 flag]
                 set dbc_hld_hgt($dbc_query_count) [ASC_ask_att_val \
                     LENGTH $db_row "" 0 flag]
                 set dbc_hld_taper($dbc_query_count) [ASC_ask_att_val \
                     TAPER $db_row "" 0 flag]
                 set dbc_hld_corner($dbc_query_count) [ASC_ask_att_val \
                     CRAD $db_row "" 0 flag]

                incr dbc_query_count
            }
        }
    }
}

proc ASC_load_turning_holder_data {} {
    global asc_database_count
    global dbc_libref
    global dbc_holder_subtype
    
    global dbc_turn_holder_style
    global dbc_turn_holder_hand
    global dbc_turn_holder_length
    global dbc_turn_holder_width
    global dbc_turn_shank_type
    global dbc_turn_holder_shank_width
    global dbc_turn_holder_shank_line
    global dbc_tool_holder_orient_angle
    global dbc_turn_holder_insert_extension
    global dbc_turn_holder_shank_height
    global dbc_turn_holder_shank_definition_mode
    global dbc_tool_holder_cutting_edge_angle
    global dbc_turn_adapter_tog
    global dbc_turn_adapter_style
    global dbc_turn_adapter_length
    global dbc_turn_adapter_width
    global dbc_turn_adapter_height
    global dbc_turn_adapter_zoffset
    global dbc_turn_adapter_diameter
    global dbc_turn_adapter_step_length
    global dbc_turn_adapter_step_diameter
    global dbc_turn_adapter_taper_length
    global dbc_turn_adapter_taper_angle
    global dbc_turn_adapter_block_length
    global dbc_turn_adapter_block_width
    global dbc_turn_adapter_block_height

    for {set db_row 0} {$db_row < $asc_database_count} { incr db_row 1} {
        set tmp_libref [ASC_ask_att_val LIBRF $db_row "" 0 flag]
        if {$tmp_libref == $dbc_libref} {
           set rtype [ASC_ask_att_val RTYPE $db_row "" 0 flag]
           if {$rtype == "2"} {
               if {$dbc_holder_subtype == 0} {
                   set dbc_turn_holder_style [ASC_ask_att_val \
                           HSTYLE $db_row "%d" 0 flag]
                   # 
                   # Shank definition mode (Insert And Holder = 0, Cutting Edge Angle = 1)
                   set dbc_turn_holder_shank_definition_mode [ASC_ask_att_val SDEFMODE $db_row "" 0 flag]
                   #
                   # Cutting Edge Angle
                   set edge_angle [ASC_ask_att_val CEA $db_row "%$::double_precision_format" 5 flag]
                   set dbc_tool_holder_cutting_edge_angle [expr $edge_angle * asin(1.0) / 90.0]
               } elseif {$dbc_holder_subtype == 1} {
                   set dbc_turn_holder_style [ASC_ask_att_val \
                           GSTYLE $db_row "%d" 23 flag]
                   set dbc_turn_holder_insert_extension [ASC_ask_att_val \
                           INSERTX $db_row "%$::double_precision_format" 0 flag]
               }

               set dbc_turn_holder_hand [ASC_ask_att_val \
                       HHAND $db_row "%d" 0 flag]
               set dbc_turn_holder_length [ASC_ask_att_val \
                       HLENGTH $db_row "%$::double_precision_format" 0 flag]
               set dbc_turn_holder_width [ASC_ask_att_val \
                       HWIDTH $db_row "%$::double_precision_format" 0 flag]
               set dbc_turn_shank_type [ASC_ask_att_val \
                       SHANKT $db_row "%d" 0 flag]
               set dbc_turn_holder_shank_width [ASC_ask_att_val \
                       SHANKW $db_row "%$::double_precision_format" 0 flag]
               set dbc_turn_holder_shank_line [ASC_ask_att_val \
                       SHANKL $db_row "%$::double_precision_format" 0 flag]
               set temp_holder_angle [ASC_ask_att_val \
                       HANGLE $db_row "%$::double_precision_format" 0 flag]
               #convert angle from degrees to radians
               set dbc_tool_holder_orient_angle [expr $temp_holder_angle * asin(1.0) / 90.0]

               set dbc_turn_holder_shank_height [ASC_ask_att_val \
                       SHANKH $db_row "%$::double_precision_format" 0 flag]
               # if shank height is not defined, set it to shank width (square shank)
               if { ($dbc_turn_holder_shank_height) < 0.0001 } {
                   set dbc_turn_holder_shank_height $dbc_turn_holder_shank_width
                }
               #
               # Adapter parameter
               #
               set dbc_turn_adapter_tog [ASC_ask_att_val ADAPTER $db_row "" 0 flag]
               if { ($dbc_turn_adapter_tog) == 1 } {
                   set dbc_turn_adapter_style [ASC_ask_att_val ASTYLE $db_row "" 0 flag]
                   set dbc_turn_adapter_length [ASC_ask_att_val ALENGTH $db_row "%$::double_precision_format" 0 flag]
                   set dbc_turn_adapter_width [ASC_ask_att_val AWIDTH $db_row "%$::double_precision_format" 0 flag]
                   set dbc_turn_adapter_height [ASC_ask_att_val AHEIGHT $db_row "%$::double_precision_format" 0 flag]
                   if { ($dbc_turn_shank_type) == 0 } {
                       # square shank
                       set dbc_turn_adapter_zoffset [ASC_ask_att_val AZOFF $db_row "%$::double_precision_format" 0 flag]
                   } else {
                       # round shank
                       set dbc_turn_adapter_diameter [ASC_ask_att_val ADIAM $db_row "%$::double_precision_format" 0 flag]
                       set dbc_turn_adapter_step_length [ASC_ask_att_val ASTEPLEN $db_row "%$::double_precision_format" 0 flag]
                       set dbc_turn_adapter_step_diameter [ASC_ask_att_val ASTEPDIAM $db_row "%$::double_precision_format" 0 flag]
                       set dbc_turn_adapter_taper_length [ASC_ask_att_val ATAPERLEN $db_row "%$::double_precision_format" 0 flag]
                       set taper_angle [ASC_ask_att_val ATAPERANG $db_row "%$::double_precision_format" 5 flag]
                       set dbc_turn_adapter_taper_angle [expr $taper_angle * asin(1.0) / 90.0]
                       set dbc_turn_adapter_block_length [ASC_ask_att_val ABLCKLEN $db_row "%$::double_precision_format" 0 flag]
                       set dbc_turn_adapter_block_width [ASC_ask_att_val ABLCKWID $db_row "%$::double_precision_format" 0 flag]
                       set dbc_turn_adapter_block_height [ASC_ask_att_val ABLCKHGHT $db_row "%$::double_precision_format" 0 flag]
                   }
               }
           }
        }
    }
}

proc ASC_insert {} \
{
    global asc_database_name
    global asc_file_name
    global asc_units
    global dbc_part_units
    global dbc_event_error
    global dbc_logname

    global dbc_class
    global dbc_cutter_holder_libref
    global dbc_holder_count   
    global dbc_holder_num_sections
    global dbc_holder_description
    global dbc_holder_max_offset
    global dbc_holder_min_diameter
    global dbc_holder_max_diameter
    global dbc_holder_type
    global dbc_holder_subtype

    global dbc_clsf_decimal_places
    global mom_clsf_decimal_places

    global asc_cur_line
    global asc_record_type
    global asc_class
    global asc_record_libref

    global num_formats_processed

    global dbc_export_file_name

    if {$dbc_part_units == "metric"} \
    {
        set base_filename [ASC_get_data_file_name $asc_units(mm)]
    } else \
    {
        set base_filename [ASC_get_data_file_name $asc_units(inch)]
    }


    set asc_tempname $base_filename
    append asc_tempname "_tmp"

    set asc_backupname $base_filename
    append asc_backupname "_bak"

#  back up the existing version of the library
    if [catch {file copy -force $base_filename $asc_backupname} ] \
    {
        set dbc_event_error "Can't create backup file $asc_backupname."
        return
    }

#  open temp file and current library file
    if [catch {open $asc_tempname w} tmp_fileid] \
    {
        set dbc_event_error "Error opening $asc_tempname"
        return
    }

    if [catch {open $base_filename r} input_fileid] \
    {
        set dbc_event_error "Error opening $base_filename"
        return
    }

#  initialize processing flags
    set num_formats_processed 0
    set directory_record_output 0
    set section_records_output 0

#  Since we don't use min and max diameters yet, force the to 0.0 if
#    they aren't defined
    if { [info exists dbc_holder_min_diameter] } \
    {
        set local_min_diameter $dbc_holder_min_diameter
    } else \
    {
        set local_min_diameter 0.0
    }

    if { [info exists dbc_holder_max_diameter] } \
    {
        set local_max_diameter $dbc_holder_max_diameter
    } else \
    {
        set local_max_diameter 0.0
    }


    if {$dbc_holder_type == 2} {
        #for turning holder, variables below should be forced to 0
        set dbc_holder_num_sections 0
        set dbc_holder_max_offset 0.0
        set local_min_diameter 0.0
        set local_max_diameter 0.0
    }

    set new_record \
        [format "DATA | %s | 1 | %d | %d | %d | %.5f | %.5f | %.5f | %s" \
        $dbc_cutter_holder_libref $dbc_holder_type $dbc_holder_subtype \
        $dbc_holder_num_sections $dbc_holder_max_offset $local_min_diameter \
        $local_max_diameter $dbc_holder_description]

#  Cycle over all the records in the input file looking for the spot
#    to insert the input holder
    while {[gets $input_fileid asc_cur_line] >= 0} \
    {
        ASC_classify_line
        switch -- $asc_record_type \
        {
            "Comment"
            {
                puts $tmp_fileid $asc_cur_line
            }
            "Revision"
            {
#  output a new revision line for the new entry and then the input record
                set daytime [clock seconds]
                set out_daytime [clock format $daytime -format "%a %b %d %Y %I:%M %p"]
                set cur_rev "#      $dbc_logname $out_daytime"
                append cur_rev "  Saving $dbc_cutter_holder_libref"

                puts $tmp_fileid $cur_rev
                puts $tmp_fileid $asc_cur_line
            }
            "Class"
            {
                puts $tmp_fileid $asc_cur_line
            }
            "Format"
            {
                incr num_formats_processed
                puts $tmp_fileid $asc_cur_line
            }
            "Directory Data"
            {
                 set libref_cmp [string compare $asc_record_libref $dbc_cutter_holder_libref]
#  If the libref is greater than the current record, output the current record
                if { $libref_cmp == -1 } \
                {
                    puts $tmp_fileid $asc_cur_line
                } elseif { $libref_cmp == 0 } \
                {
#  We have a matching directory record.  Set the directory record output flag
#    and output the new record
                    if { $directory_record_output == 0 } \
                    {
                        puts $tmp_fileid $new_record
                        incr directory_record_output
                    }
                } else \
                {
#  The new record belongs between the previous and current record.  Output
#    it here and then the current one.
                    if { $directory_record_output == 0 } \
                    {
                        puts $tmp_fileid $new_record
                        incr directory_record_output
                    }
                    puts $tmp_fileid $asc_cur_line
                }
            }
            "End Directory Data"
            {
               #  If we haven't output the directory record yet, do it now.  Then this rec
                if { $directory_record_output == 0} \
                {
                    puts $tmp_fileid $new_record
                }
                puts $tmp_fileid $asc_cur_line
            }
            "Section Data"
            {
                set libref_cmp [string compare $asc_record_libref $dbc_cutter_holder_libref]

#  If this data record isn't for the class we're trying to insert, just
#    pass it to the output file.  Otherwise, compare the librefs and
#    determine if it needs to be output yet.
                if { [string compare $dbc_class $asc_class] != 0 } \
                {
                    puts $tmp_fileid $asc_cur_line
                } elseif { $libref_cmp == -1 } \
                {
                    puts $tmp_fileid $asc_cur_line
                } elseif { $libref_cmp == 0 } \
                {
                    if { $section_records_output == 0 } \
                    {
                        ASC_insert_holder_data $tmp_fileid section_records_output
                    }
                } else \
                {
                    if { $section_records_output == 0 } \
                    {
                        ASC_insert_holder_data $tmp_fileid section_records_output
                    }
                    puts $tmp_fileid $asc_cur_line
                }
            }
            "End Section Data"
            {
#  If we haven't output the section records, do it now and then this rec
                if { $section_records_output == 0 && [string compare $dbc_class $asc_class] == 0} \
                {
                    ASC_insert_holder_data $tmp_fileid section_records_output
                }
                puts $tmp_fileid $asc_cur_line
            }
        }
    }

#  Close the input and output files
    if [catch {close $tmp_fileid} ] \
    {
        set dbc_event_error "Error closing $asc_tempname"
        return
    }
    if [catch {close $input_fileid} ] \
    {
        set dbc_event_error "Error closing $base_filename"
        return
    }

#  Rename the output file to the current file name, since we have already
#    copied the current library into a backup file.
    if [catch {file rename -force $asc_tempname $base_filename} ] \
    {
        global errorInfo
        set dbc_event_error "Can't update library file $base_filename."
    }

#  Reinitialize the database to update the run-time data since this doesn't
#    automatically happen on subsequent access attempts.
    DBC_init_db

# Set this here because init_db sets everything to ""
    set dbc_export_file_name $base_filename
}


proc ASC_output_section_records { fileid } \
{
    global dbc_cutter_holder_libref
    global dbc_class
    global dbc_holder_num_sections

    global dbc_seqno
    global dbc_hld_diam
    global dbc_hld_hgt
    global dbc_hld_taper
    global dbc_hld_corner

    switch -- $dbc_class \
    {
    "FDM" -
    "LASER" -
    "WEDM" -
    "MILLING_DRILLING"
    {
        for {set section_count 0 } { $section_count < $dbc_holder_num_sections} {incr section_count} \
        {
            set data_line [format "DATA | %s | 2 | %d | %9.5f | %9.5f | %9.5f | %9.5f" \
                $dbc_cutter_holder_libref $dbc_seqno($section_count) \
                $dbc_hld_diam($section_count) $dbc_hld_hgt($section_count) \
                $dbc_hld_taper($section_count) $dbc_hld_corner($section_count)]

            puts $fileid $data_line
        }
    }
    }
}

proc ASC_classify_line { } \
{
    global asc_cur_line
    global asc_class
    global num_formats_processed
    global asc_record_libref
    global asc_record_type

#  First check if record is some form of comment
    if {[string match {#*} $asc_cur_line] == 1} \
    {
#  It does.  Sort out what kind
        if {[string match #END_DATA $asc_cur_line] == 1} \
        {
            if {$num_formats_processed == 1} \
            {
                set asc_record_type "End Directory Data"
            } else \
            {
                set asc_record_type "End Section Data"
            }
        } elseif {[string match *CLASS* $asc_cur_line] == 1} \
        {
#  We have a Class specification.  Extract the class
            set asc_record_type "Class"
            set asc_class [string trimright $asc_cur_line]
            set tmp_ix [string first CLASS $asc_class]
            set tmp_iy [string wordend $asc_class $tmp_ix]
            set asc_class [string range $asc_class $tmp_iy end]
            set asc_class [string trimleft $asc_class]
        } elseif {[string match *dbc_logname* $asc_cur_line] == 1} \
        {
            set asc_record_type "Revision"
        } else \
        {
            set asc_record_type "Comment"
        }
    } elseif {[string match {FORMAT*} $asc_cur_line] == 1 } \
    {
        set asc_record_type "Format"
    } elseif {[string match {DATA*} $asc_cur_line] ==1} \
    {
#  We have a DATA record.  Check if we are in the directory
#    or a holder section region
        if {$num_formats_processed == 1} \
        {
            set asc_record_type "Directory Data"
        } else \
        {
            set asc_record_type "Section Data"
        }
#  Extract the libref from this data record
        set tmp_ix [string first | $asc_cur_line]
        incr tmp_ix
        set asc_record_libref [string range $asc_cur_line $tmp_ix end]
        set tmp_iy [string first | $asc_record_libref]
        incr tmp_iy -1
        set asc_record_libref [string range $asc_record_libref 0 $tmp_iy]
        set asc_record_libref [string trim $asc_record_libref]
    } else \
    {
#  This doesn't match any previous types, so it is probably a blank line.
#  Whatever it is, treat it as a comment and pass it through.
        set asc_record_type "Comment"
    }
}

proc ASC_insert_holder_data {fileId OUTPUT_MARK} {
    global dbc_holder_type
    upvar $OUTPUT_MARK output_mark

    if {$dbc_holder_type == 1 || $dbc_holder_type == 3 || $dbc_holder_type == 4 || $dbc_holder_type == 5 } {
        ASC_output_section_records $fileId
    } elseif { $dbc_holder_type == 2 } {
        ASC_output_turning_holder_data $fileId
    }
     
    incr output_mark
}

proc ASC_output_turning_holder_data {fileId} {
    global dbc_holder_subtype
    global dbc_holder_description
    global dbc_cutter_holder_libref
    global dbc_turn_holder_style
    global dbc_turn_holder_hand
    global dbc_turn_holder_length
    global dbc_turn_holder_width
    global dbc_turn_shank_type
    global dbc_turn_holder_shank_width
    global dbc_turn_holder_shank_line
    global dbc_tool_holder_orient_angle
    global dbc_turn_holder_insert_extension
    global dbc_turn_holder_shank_height
    global dbc_turn_holder_shank_definition_mode
    global dbc_tool_holder_cutting_edge_angle
    global dbc_turn_adapter_tog
    global dbc_turn_adapter_style
    global dbc_turn_adapter_length
    global dbc_turn_adapter_width
    global dbc_turn_adapter_height
    global dbc_turn_adapter_zoffset
    global dbc_turn_adapter_diameter
    global dbc_turn_adapter_step_length
    global dbc_turn_adapter_step_diameter
    global dbc_turn_adapter_taper_length
    global dbc_turn_adapter_taper_angle
    global dbc_turn_adapter_block_length
    global dbc_turn_adapter_block_width
    global dbc_turn_adapter_block_height

    #convert angle from radians to degrees
    set temp_holder_angle [expr $dbc_tool_holder_orient_angle * 90.0 / asin(1.0)]
    set temp_taper_angle [expr $dbc_turn_adapter_taper_angle * 90.0 / asin(1.0)]

    #convert adapter tog
    if {$dbc_turn_adapter_tog == "Yes"} {
        set temp_turn_adapter_tog 1
    } else {
        set temp_turn_adapter_tog 0
    }

    if {$dbc_holder_subtype == 0} {
        set temp_cutting_edge_angle [expr $dbc_tool_holder_cutting_edge_angle * 90.0 / asin(1.0)]
        #standard turning tool holder
        set new_record \
            [format "DATA | %s | 2 | %2d | %d | %.5f | %.5f | %d | %.5f | %.5f | %.5f | %.5f | %d | %.5f | %s | %d | %.5f |  %.5f | %.5f | %.5f | %.5f | %.5f | %.5f | %.5f | %.5f | %.5f | %.5f | %.5f " \
                $dbc_cutter_holder_libref $dbc_turn_holder_style \
                $dbc_turn_holder_hand $dbc_turn_holder_length \
                $dbc_turn_holder_width $dbc_turn_shank_type $dbc_turn_holder_shank_width \
                $dbc_turn_holder_shank_line $temp_holder_angle $dbc_turn_holder_shank_height \
                $dbc_turn_holder_shank_definition_mode $temp_cutting_edge_angle \
                $temp_turn_adapter_tog $dbc_turn_adapter_style $dbc_turn_adapter_length $dbc_turn_adapter_width \
                $dbc_turn_adapter_height $dbc_turn_adapter_zoffset $dbc_turn_adapter_diameter $dbc_turn_adapter_step_length \
                $dbc_turn_adapter_step_diameter $dbc_turn_adapter_taper_length $temp_taper_angle \
                $dbc_turn_adapter_block_length $dbc_turn_adapter_block_width $dbc_turn_adapter_block_height] \
    } elseif {$dbc_holder_subtype == 1} {
        #grooving tool holder
        set new_record \
            [format "DATA | %s | 2 | %2d | %d | %.5f | %.5f | %d | %.5f | %.5f | %.5f | %.5f | %.5f | %d | %d | %.5f |  %.5f | %.5f | %.5f | %.5f | %.5f | %.5f | %.5f | %.5f | %.5f | %.5f | %.5f " \
                $dbc_cutter_holder_libref $dbc_turn_holder_style \
                $dbc_turn_holder_hand $dbc_turn_holder_length \
                $dbc_turn_holder_width $dbc_turn_shank_type $dbc_turn_holder_shank_width \
                $dbc_turn_holder_shank_line $temp_holder_angle $dbc_turn_holder_insert_extension $dbc_turn_holder_shank_height \
                $temp_turn_adapter_tog $dbc_turn_adapter_style $dbc_turn_adapter_length $dbc_turn_adapter_width \
                $dbc_turn_adapter_height $dbc_turn_adapter_zoffset $dbc_turn_adapter_diameter $dbc_turn_adapter_step_length \
                $dbc_turn_adapter_step_diameter $dbc_turn_adapter_taper_length $temp_taper_angle \
                $dbc_turn_adapter_block_length $dbc_turn_adapter_block_width $dbc_turn_adapter_block_height] \
    }

    puts $fileId $new_record
}

# To enable the new customization mechanism. 
# This should ALWAYS be the last line in the file. 
MOM_extend_for_customization UGII_CAM_CUSTOM_LIBRARY_TOOL_ASCII_DIR dbc_custom_holder_ascii.tcl 

