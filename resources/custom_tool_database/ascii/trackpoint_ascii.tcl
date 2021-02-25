###############################################################################
# trackpoint_ascii.tcl - DBC Event Handler for database stored as ascii file
###############################################################################
##############################################################################
# REVISIONS
#   Date        Who              Reason
#   25-Jan-2006 rlm              initial release
#   14-Dec-2011 JM               Add dbc_export_file_name
#   27-Feb-2014 Cheng Wang       cam10008: Add definition type
#   13-Nov-2017 JM               no export backup if multitool export
#   26-Oct-2018 Shorbojeet Das   PR#8340732: Add customization support for double precision control.
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
#
# This is path+name of the trackpoint_database.dat file 
# where a tracking point gets exported.
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
        set message "Error looking for a trackpoint_database.dat file."
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
    set fname [append fname $env_var "trackpoint_database.dat"]

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

#
# global output
# -------------
    global dbc_trackpoint_count
    global dbc_trackpoint_type
    global dbc_trackpoint_subtype
    global dbc_query
    global dbc_query_count


    if { $asc_debug == "1" } \
    {
        puts " =========================================="
        puts " procedure  DBC_retrieve for tool tracking points"
        puts " libref -> $dbc_libref"
    }

#  initialize point count so we can detect if retrieval failed
    set dbc_trackpoint_count 0

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
        set dbc_trackpoint_type [ASC_ask_att_val T $db_row "%d" 0 flag]
        set dbc_trackpoint_subtype [ASC_ask_att_val STYPE $db_row "%d" 0 flag]
            
        ASC_load_trackpoint_data
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
        set message "Error retrieving trackpoints from external library."
        set message "$message \n Trackpoints with the library reference $libref"
        set message "$message \n do not exist in the"
        set message "$message \n ASCII Data File(s):"
        set message "$message \n $asc_file_name"
        MOM_abort "\n $message"
    }

    if { $found == 1 } \
    {
        set message "Error retrieving trackpoints from external library."
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

proc ASC_load_trackpoint_data {} \
{
    global dbc_attr_count
    global dbc_attr_aliases
    global dbc_attr_id
    global dbc_libref
    global dbc_query_count

    global dbc_trackpoint_count
    global dbc_trackpoint_name
    global dbc_trackpoint_seqno
    global dbc_trackpoint_adjust
    global dbc_trackpoint_adjust_status
    global dbc_trackpoint_cutcom
    global dbc_trackpoint_cutcom_status
    global dbc_trackpoint_diam
    global dbc_trackpoint_length
    global dbc_trackpoint_z_offset
    global dbc_trackpoint_zoff_status
    global dbc_trackpoint_x_offset
    global dbc_trackpoint_y_offset
    global dbc_trackpoint_radius_id
    global dbc_trackpoint_cluster_id
    global dbc_trackpoint_tool_angle
    global dbc_trackpoint_radius
    global dbc_trackpoint_def_type

    global asc_database_count

#  Initialize environment
    set dbc_trackpoint_count 0

#  Cycle database looking for matching data records
    for {set db_row 0} {$db_row < $asc_database_count} { incr db_row 1} \
    {
        set tmp_libref [ASC_ask_att_val LIBRF $db_row "" 0 flag]
        if {$tmp_libref == $dbc_libref} \
        {
#  Set common data
            set dbc_trackpoint_name($dbc_trackpoint_count) [ASC_ask_att_val \
                NAME $db_row "%s" 0 flag]
            set dbc_trackpoint_seqno($dbc_trackpoint_count) [ASC_ask_att_val \
                SEQ $db_row "%d" 0 flag]
            set dbc_trackpoint_adjust($dbc_trackpoint_count) [ASC_ask_att_val \
                ADJREG $db_row "%d" 0 flag]
            set dbc_trackpoint_cutcom($dbc_trackpoint_count) [ASC_ask_att_val \
                CUTREG $db_row "%d" 0 flag]

#  Get type of Tracking point
            set type [ASC_ask_att_val T $db_row "" 0 flag]

#  Milling_Drilling
            if {$type == "1" } \
            {
                set dbc_trackpoint_adjust_status($dbc_trackpoint_count) [ASC_ask_att_val \
                    ADJSTAT $db_row "%d" 0 flag]
                set dbc_trackpoint_cutcom_status($dbc_trackpoint_count) [ASC_ask_att_val \
                    CUTSTAT $db_row "%d" 0 flag]
                set dbc_trackpoint_diam($dbc_trackpoint_count) [ASC_ask_att_val \
                    DIAM $db_row "%$::double_precision_format" 0 flag]
                set dbc_trackpoint_length($dbc_trackpoint_count) [ASC_ask_att_val \
                    DIST $db_row "%$::double_precision_format" 0 flag]
                set dbc_trackpoint_z_offset($dbc_trackpoint_count) [ASC_ask_att_val \
                    ZOFF $db_row "%$::double_precision_format" 0 flag]
                set dbc_trackpoint_zoff_status($dbc_trackpoint_count) [ASC_ask_att_val \
                    ZOFFSTAT $db_row "%d" 0 flag]
                set dbc_trackpoint_def_type($dbc_trackpoint_count) [ASC_ask_att_val \
                    DEFTYPE $db_row "%d" 0 flag]
            } elseif {$type == "2" } \
            {
#  Turning
                set dbc_trackpoint_x_offset($dbc_trackpoint_count) [ASC_ask_att_val \
                    XOFF $db_row "%$::double_precision_format" 0 flag]
                set dbc_trackpoint_y_offset($dbc_trackpoint_count) [ASC_ask_att_val \
                    YOFF $db_row "%$::double_precision_format" 0 flag]
                set dbc_trackpoint_radius_id($dbc_trackpoint_count) [ASC_ask_att_val \
                    RADID $db_row "%d" 0 flag]
                set dbc_trackpoint_cluster_id($dbc_trackpoint_count) [ASC_ask_att_val \
                    CLUSTID $db_row "%d" 0 flag]
                set dbc_trackpoint_tool_angle($dbc_trackpoint_count) [ASC_ask_att_val \
                    ANGLE $db_row "%$::double_precision_format" 0 flag]
                set dbc_trackpoint_radius($dbc_trackpoint_count) [ASC_ask_att_val \
                    RAD $db_row "%$::double_precision_format" 0 flag]
            }

            incr dbc_trackpoint_count
        }
    }
}


proc DBC_create_backup_data_file {} \
{
    global dbc_event_error
    global dbc_part_units
    global asc_units


    if {$dbc_part_units == "metric"} \
    {
        set base_filename [ASC_get_data_file_name $asc_units(mm)]
    } else \
    {
        set base_filename [ASC_get_data_file_name $asc_units(inch)]
    }


    set asc_backupname $base_filename
    append asc_backupname "_bak"

    if [catch {file copy -force $base_filename $asc_backupname} ] \
    {
        set dbc_event_error "Can't create backup file $asc_backupname."
        return 1
    }

    return 0
}


proc ASC_insert {} \
{
    global asc_database_name
    global asc_file_name
    global asc_units
    global dbc_part_units
    global dbc_event_error
    global dbc_logname

    global dbc_trackpoint_class
    global dbc_cutter_trackpoint_libref
    global dbc_trackpoint_count   

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

    global dbc_ongoing_multitool_export_flag
    set create_backup_file 1
    if { [info exists dbc_ongoing_multitool_export_flag] } \
    {
        if { $dbc_ongoing_multitool_export_flag == 1 } \
        {
            set create_backup_file 0
        }
    }

#  back up the existing version of the library
    if { $create_backup_file == 1 } \
    {
        set error_flag [DBC_create_backup_data_file]
        if {$error_flag == 1} \
        {
            return
        }
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

#  Cycle over all the records in the input file looking for the spot
#    to insert the input trackpoint set
    set trackpoints_output 0
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
                append cur_rev "  Saving $dbc_cutter_trackpoint_libref"

                puts $tmp_fileid $cur_rev
                puts $tmp_fileid $asc_cur_line
            }
            "Class"
            {
#  Save indicator for this class matching the input class
                set class_match [string compare $dbc_trackpoint_class $asc_class]
                puts $tmp_fileid $asc_cur_line
            }
            "Format"
            {
                puts $tmp_fileid $asc_cur_line
            }
            "Data"
            {
                set libref_cmp [string compare $asc_record_libref $dbc_cutter_trackpoint_libref]

#  If this data record isn't for the class we're trying to insert, just
#    pass it to the output file.  Otherwise, compare the librefs and
#    determine if it needs to be output yet.
                if { $class_match != 0 } \
                {
                    puts $tmp_fileid $asc_cur_line
                } elseif { $libref_cmp == -1 } \
                {
                    puts $tmp_fileid $asc_cur_line
                } elseif { $libref_cmp == 0 } \
                {
                    if { $trackpoints_output == 0 } \
                    {
                        ASC_output_trackpoints $tmp_fileid
                        incr trackpoints_output
                    }
                } else \
                {
                    if { $trackpoints_output == 0 } \
                    {
                        ASC_output_trackpoints $tmp_fileid
                        incr trackpoints_output
                    }
                    puts $tmp_fileid $asc_cur_line
                }
            }
            "End Data"
            {
#  If this End Data record is for the class we're trying to insert,
#    check if the trackpoints have been output yet.  If not, 
#    output them now and then this record.
                if { $class_match == 0 } \
                {
                    if { $trackpoints_output == 0 } \
                    {
                        ASC_output_trackpoints $tmp_fileid
                        incr trackpoints_output
                    }
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

proc ASC_output_trackpoints { fileid } \
{
    global dbc_cutter_trackpoint_libref
    global dbc_trackpoint_class
    global dbc_trackpoint_count

    global dbc_trackpoint_name
    global dbc_trackpoint_seqno
    global dbc_trackpoint_adjust
    global dbc_trackpoint_adjust_status
    global dbc_trackpoint_cutcom
    global dbc_trackpoint_cutcom_status
    global dbc_trackpoint_diam
    global dbc_trackpoint_length
    global dbc_trackpoint_z_offset
    global dbc_trackpoint_zoff_status
    global dbc_trackpoint_x_offset
    global dbc_trackpoint_y_offset
    global dbc_trackpoint_radius_id
    global dbc_trackpoint_cluster_id
    global dbc_trackpoint_tool_angle
    global dbc_trackpoint_radius
    global dbc_trackpoint_def_type

    switch -- $dbc_trackpoint_class \
    {
    "MILLING_DRILLING"
    {
        for {set trackpoint_count 0 } { $trackpoint_count < $dbc_trackpoint_count} {incr trackpoint_count} \
        {
            set data_line [format "DATA | %s | 1 | 0 | %s | %d | %d | %d | %d | %d | %9.5f | %9.5f | %9.5f | %d | %d" \
                $dbc_cutter_trackpoint_libref $dbc_trackpoint_name($trackpoint_count) \
                $dbc_trackpoint_seqno($trackpoint_count) \
                $dbc_trackpoint_adjust($trackpoint_count) $dbc_trackpoint_adjust_status($trackpoint_count) \
                $dbc_trackpoint_cutcom($trackpoint_count) $dbc_trackpoint_cutcom_status($trackpoint_count) \
                $dbc_trackpoint_diam($trackpoint_count) $dbc_trackpoint_length($trackpoint_count) \
                $dbc_trackpoint_z_offset($trackpoint_count) $dbc_trackpoint_zoff_status($trackpoint_count) \
                $dbc_trackpoint_def_type($trackpoint_count)]
            puts $fileid $data_line
        }
    }
    "TURNING"
    {
        for {set trackpoint_count 0 } { $trackpoint_count < $dbc_trackpoint_count} {incr trackpoint_count} \
        {
            set data_line [format "DATA | %s | 2 | 0 | %s | %d | %d | %d | %9.5f | %9.5f | %d | %d | %9.5f | %9.5f" \
                $dbc_cutter_trackpoint_libref $dbc_trackpoint_name($trackpoint_count) \
                $dbc_trackpoint_seqno($trackpoint_count) \
                $dbc_trackpoint_adjust($trackpoint_count) $dbc_trackpoint_cutcom($trackpoint_count) \
                $dbc_trackpoint_x_offset($trackpoint_count) $dbc_trackpoint_y_offset($trackpoint_count) \
                $dbc_trackpoint_radius_id($trackpoint_count) $dbc_trackpoint_cluster_id($trackpoint_count) \
                $dbc_trackpoint_tool_angle($trackpoint_count) $dbc_trackpoint_radius($trackpoint_count)]
            puts $fileid $data_line
        }
    }
    }
}

proc ASC_classify_line { } \
{
    global asc_cur_line
    global asc_class
    global asc_record_libref
    global asc_record_type

#  First check if record is some form of comment
    if {[string match {#*} $asc_cur_line] == 1} \
    {
#  It does.  Sort out what kind
        if {[string match #END_DATA $asc_cur_line] == 1} \
        {
            set asc_record_type "End Data"
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
#  We have a DATA record.
        set asc_record_type "Data"

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

# To enable the new customization mechanism. 
# This should ALWAYS be the last line in the file. 
MOM_extend_for_customization UGII_CAM_CUSTOM_LIBRARY_TOOL_ASCII_DIR dbc_custom_trackpoint_ascii.tcl
