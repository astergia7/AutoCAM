###############################################################################
# dbc_tool_ascii_export.tcl - DBC Event Handler procs to support exporting tool
###############################################################################
##############################################################################
# REVISIONS
#   Date        Who            Reason
#   02-Feb-2005 rlm            Initial Release
#   21-Apr-2005 rlm            Reset dbc_part_units in insert to current value
#   15-Jun-2005 rlm 5280252    Pass drill subtype to ASC_build_drill
#   02-Mar-2006 rlm            Add support for MILL_FORM
#   28-Nov-2006 rlm            Add support for Solid Model Tools
#   13-Jul-2010 Peter Mao      camarch8001 - chamfer mill
#   20-Aug-2010 Peter Mao      camarch8001 - spherical mill
#   14-Oct-2010 Peter Mao      camarch8002 - tool library alignment
#   02-Mar-2011 Peter Mao      Add face grooving
#   04-Mar-2011 Peter Mao      Remove thickness attribute for grooving tool
#   18-Jan-2012 JM             init dbc_export_file_name
#   12-Oct_2012 Mario Mao      camarch9042 - add Core Drill
#   04-Jan-2013 Cheng Wang     Add support for Laser Tool <camarch9030>
#   25-Jan-2013 Carl Shang     camuif9095 - add wire tool
#   31-Jan-2013 Mario Mao      6817429 Add holding system for barrel mill/mill form/step drill
#   14-May-2013 Peter Mao      Allow exporting chamfer mill as face mill
#   15-Dec-2014 Carl Shang     cam10052 - Add Back Counter Sink
#   21-Oct-2015 Jenny Zhang    cam11035 - Addd Boring Bar tool
#   10-Dec-2015 Jenny Zhang    cam11035 - Add Chamfer Boring Bar tool
#   22-Dec-2015 Jeremy Wight   Add robot types
#   10-Jun-2016 Gopal Srinath  Added Deposition Laser
#   23-Jun-2017 Gopal Srinath  8899107 Corrected the subtype for ROBOTIC_BALL_MILL to 3 and made it consistent with the BALL_MILL_NON_INDEXABLE
#   28-Jul-2017 Joachim Meyer  Add Multitool to ASC_build_tool_record
#   13-Nov-2017 Joachim Meyer  Create backup file only if not a multi-tool
#   17-Aug-2018 Shorbojeet Das PR9237134 Fix rollup, add FDM/Tangent Barrel Tool
#   05-Oct-2018 Dieter Krach   cam18046: Add HARDENING_LASER to ASC_build_tool_record
#   06-Dec-2018 Shorbojeet Das PR9239403 - Add Thread Shape for Tap Tools only.
#   15-Jan-2019 Shanaz Mistry  cam18010.2: Add Taper Barrel tool
#   23-Jan-2019 Quittschau     cam18014.17.1: Add shaping tool type
#   26-Mar-2019 Quittschau     cam18014.17.8: Rename shaping tool to stamping tool
#   18-Apr-2019 Shorbojeet Das PR9441380: Add UG_5_PARAMETER in ASC_ask_missing_aliases. 
##############################################################################
#
#
#  ASC_ask_missing_aliases
#
#  Procedure to return a list of aliases not defined in the current cutter
#    which must be supplied to allow the system to build a valid database
#    entry.
#
proc ASC_ask_missing_aliases { } \
{
    global dbc_class
    global dbc_att_count
    global dbc_tmp_aliases
    global dbc_template_attributes
    global dbc_libref
    global dbc_tool_holding_system
    global dbc_tool_preset_cutter
    global asc_file_loaded

    set dbc_att_count 0

#  check if libref currently exists.  If so, return the current values of
#    the aliases to prompt for.
    ASC_search_libref_no_abort $dbc_libref db_row

#  First, add Holding system for all classes which use it
    switch -- $dbc_class \
    {
        "END_MILL_NON_INDEXABLE" -
        "END_MILL_INDEXABLE" -
        "BALL_MILL_NON_INDEXABLE" -
        "CHAMFER_MILL_NON_INDEXABLE" -
        "SPHERICAL_MILL_NON_INDEXABLE" -
        "FACE_MILL_INDEXABLE" -
        "T_SLOT_MILL_NON_INDEXABLE" -
        "THREAD_MILL" -
        "UG_5_PARAMETER" -
        "UG_7_PARAMETER" -
        "UG_10_PARAMETER" -
        "TWIST_DRILL" -
        "INDEX_INSERT_DRILL" -
        "INSERT_DRILL" -
        "GUN_DRILL" -
        "CORE_DRILL_NON_INDEXABLE" -
        "CORE_DRILL_INDEXABLE" -
        "SPOT_FACING" -
        "SPOT_DRILL" -
        "CENTER_DRILL" -
        "COUNTER_SINKING" -
        "BACK_COUNTER_SINKING" -
        "TAP" -
        "CHUCKING_REAMER" -
        "TAPER_REAMER" -
        "BORE" -
        "STEP_DRILL" -
        "COUNTER_BORE" -
        "BORING_BAR" -
        "CHAMFER_BORING_BAR" -
        "OD_TURNING" -
        "ID_TURNING" -
        "OD_GROOVING" -
        "ID_GROOVING" -
        "FACE_GROOVING" -
        "PARTING" -
        "OD_THREADING" -
        "ID_THREADING" -
        "OD_PROFILING" -
        "ID_PROFILING" -
        "GENERIC" -
        "PROBE" -
        "STD_LASER" -
        "DEPOSITION_LASER" -
        "WIRE" -
        "BARREL_MILL" -
        "MILL_FORM" -
        "ROBOTIC_END_MILL" -
        "ROBOTIC_BALL_MILL" -
        "MULTITOOL_TURN" -
        "MULTITOOL_DRILL_TURN"
        {
            if {! [info exists dbc_tool_holding_system] || \
                [string length $dbc_tool_holding_system] == 0 } \
            {
                set dbc_tmp_aliases($dbc_att_count) "Holder"
                if { $db_row > -1 } \
                {
                    set dbc_template_attributes($dbc_att_count) [ASC_ask_att_val HLD $db_row "" "" flag]
                } else \
                {
                    set dbc_template_attributes($dbc_att_count) ""
                }
                incr dbc_att_count
            }
        }
    }

#  Now for more class specific attributes
    if { [string compare $dbc_class "TAP"] == 0 } \
    {
        set dbc_tmp_aliases($dbc_att_count) "ThreadShapeDrill"
        if {$db_row > -1} \
        {
            set dbc_template_attributes($dbc_att_count) [ASC_ask_att_val THRDS $db_row "" "" flag]
        } else \
        {
            set dbc_template_attributes($dbc_att_count) ""
        }
        incr dbc_att_count
    }

    if { [string compare $dbc_class "OD_THREADING"] == 0 || \
         [string compare $dbc_class "ID_THREADING"] == 0 } \
    {
        set dbc_tmp_aliases($dbc_att_count) "ThreadShapeTurn"
        if {$db_row > -1} \
        {
            set dbc_template_attributes($dbc_att_count) [ASC_ask_att_val THRDS $db_row "" "" flag]
        } else \
        {
            set dbc_template_attributes($dbc_att_count) ""
        }
        incr dbc_att_count
        set dbc_tmp_aliases($dbc_att_count) "CuttingEdgeLength"
        if {$db_row > -1} \
        {
            set dbc_template_attributes($dbc_att_count) [ASC_ask_att_val CLEN $db_row "" "" flag]
        } else \
        {
            set dbc_template_attributes($dbc_att_count) ""
        }
        incr dbc_att_count
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

    global dbc_class
    global dbc_libref

    global dbc_clsf_decimal_places
    global mom_clsf_decimal_places

    global asc_cur_line
    global asc_record_type
    global asc_class
    global asc_record_libref
    global new_tool_record

    global dbc_export_file_name

    global num_formats_processed

    MOM_ask_part_units

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

#  initialize processing flags
    set class_match -1
    set tool_output 0

#  build new tool record
    ASC_build_tool_record

#  Cycle over all the records in the input file looking for the spot
#    to insert the input tool
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
                append cur_rev "  Saving $dbc_libref"

                puts $tmp_fileid $cur_rev
                puts $tmp_fileid $asc_cur_line
            }
            "Class"
            {
                puts $tmp_fileid $asc_cur_line

#  Compare this class to the class of tool we are inserting
                set class_match [string compare $dbc_class $asc_class]

#  Since we are attempting to support two FORMAT specifications for STEP_DRILL,
#    we need to know when we start processing that class
                set step_drill_match [string match $asc_class "STEP_DRILL"]
            }
            "Format"
            {
                puts $tmp_fileid $asc_cur_line

#  Since we are attempting to support two FORMAT specifications for STEP_DRILL,
#  we need to do some special testing to ensure that export places its records
#  in the proper FORMAT section.  Only the section with no step parameters is
#  being supported.
                if {$class_match == 0 && $step_drill_match == 1} \
                {
                    set old_section [string match *SD1* $asc_cur_line]
                } else \
                {
                    set old_section 0
                }
            }
            "Data"
            {
                set libref_cmp [string compare $asc_record_libref $dbc_libref]

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
#  If we are dealing with Step Drills, we need more checking.  Since we
#  only export new format Step Drills, we need to determine if we are in
#  the new section of data.  If not, skip the record so we don't get 
#  duplicate librefs
                    if {($step_drill_match == 0) || \
                        ($step_drill_match == 1 && $old_section == 0)} \
                    {
                        puts $tmp_fileid $new_tool_record
                        set tool_output 1
                    }
                } else \
                {
                    if { $tool_output == 0 } \
                    {
#  If we are dealing with Step Drills, we need more checking.  Since we
#  only export new format Step Drills, we need to determine if we are in
#  the new section of data.  If not, skip the record so we don't get 
#  duplicate librefs
                        if {($step_drill_match == 0) || \
                            ($step_drill_match == 1 && $old_section == 0)} \
                        {
                            puts $tmp_fileid $new_tool_record
                            set tool_output 1
                        }
                    }
                    puts $tmp_fileid $asc_cur_line
                }
            }
            "End Data"
            {
#  If we haven't output the tool record and we are processing the
#    class of the input tool, do it now and then this rec
                if { $tool_output == 0 && $class_match == 0} \
                {
#  If we are dealing with Step Drills, we need more checking.  Since we
#  only export new format Step Drills, we need to determine if we are in
#  the new section of data.  If not, skip the record so we don't get 
#  duplicate librefs
                    if {($step_drill_match == 0) || \
                         ($step_drill_match == 1 && $old_section == 0)} \
                    {
                        puts $tmp_fileid $new_tool_record
                        set tool_output 1
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
#  We have a DATA record
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

proc ASC_build_tool_record { } \
{
    global dbc_class
    global dbc_libref
    global asc_lib_subtype
    global asc_nx_subtype

    global uglib_tl_stype



#  Call class specific proc to build the required tool record
#  The case values must match the tool classes described in the .def file
    switch -- $dbc_class \
    {
        "END_MILL_NON_INDEXABLE"
        {
            set asc_lib_subtype 1
            set asc_nx_subtype 1 
            ASC_build_end_mill
        }
        "END_MILL_INDEXABLE"
        {
            set asc_lib_subtype 2
            set asc_nx_subtype 1 
            ASC_build_end_mill
        }
        "BALL_MILL_NON_INDEXABLE"
        {
            set asc_lib_subtype 3
            set asc_nx_subtype 4 
            ASC_build_end_mill
        }
        "CHAMFER_MILL_NON_INDEXABLE"
        {
            set asc_lib_subtype 5
            set asc_nx_subtype  5
            ASC_build_end_mill
        }
        "SPHERICAL_MILL_NON_INDEXABLE"
        {
            set asc_lib_subtype 6
            set asc_nx_subtype 6
            ASC_build_end_mill
        }
        "FACE_MILL_INDEXABLE"
        {
            set asc_lib_subtype 12 
            set asc_nx_subtype 5 
            ASC_build_end_mill
        }
        "T_SLOT_MILL_NON_INDEXABLE"
        {
            ASC_build_t_cutter
        }
        "BARREL_MILL"
        {
            ASC_build_barrel_mill
        }
        "UG_5_PARAMETER"
        {
            set asc_lib_subtype 90 
            ASC_build_ug_cutter
        }
        "UG_7_PARAMETER"
        {
            set asc_lib_subtype 91 
            ASC_build_ug_cutter
        }
        "UG_10_PARAMETER"
        {
            set asc_lib_subtype 92 
            ASC_build_ug_cutter
        }
        "THREAD_MILL"
        {
            ASC_build_thread_mill
        }
        "MILL_FORM"
        {
            ASC_build_mill_form
        }
        "TWIST_DRILL"
        {
            set asc_lib_subtype 1 
            set asc_nx_subtype 0 
            ASC_build_drill
        }
        "INDEX_INSERT_DRILL"
        {
            set asc_lib_subtype 2 
            set asc_nx_subtype 0 
            ASC_build_drill
        }
        "CORE_DRILL_NON_INDEXABLE"
        {
            set asc_lib_subtype 3 
            set asc_nx_subtype 13 
            ASC_build_drill
        }
        "CORE_DRILL_INDEXABLE"
        {
            set asc_lib_subtype 8 
            set asc_nx_subtype 13 
            ASC_build_drill
        }
        "INSERT_DRILL"
        {
            set asc_lib_subtype 6 
            set asc_nx_subtype 0 
            ASC_build_drill
        }
        "GUN_DRILL"
        {
            set asc_lib_subtype 7 
            set asc_nx_subtype 0 
            ASC_build_drill
        }
        "SPOT_FACING"
        {
            set asc_lib_subtype 12
            set asc_nx_subtype 3
            ASC_build_drill
        }
        "SPOT_DRILL"
        {
            set asc_lib_subtype 21 
            set asc_nx_subtype 4 
            ASC_build_drill
        }
        "UG_DRILL"
        {
            set asc_lib_subtype 90 
            ASC_build_drill
        }
        "CENTER_DRILL"
        {
            ASC_build_center_drill
        }
        "STEP_DRILL"
        {
            ASC_build_step_drill
        }
        "BORE"
        {
            ASC_build_bore
        }
        "COUNTER_BORE"
        {
            ASC_build_counter_bore
        }
        "BORING_BAR"
        {
            ASC_build_boring_bar
        }
        "CHAMFER_BORING_BAR"
        {
            ASC_build_chamfer_boring_bar
        }
        "COUNTER_SINKING"
        {
            ASC_build_counter_sink
        }
        "BACK_COUNTER_SINKING"
        {
            ASC_build_back_counter_sink
        }
        "TAP"
        {
            ASC_build_tap
        }
        "CHUCKING_REAMER"
        {
            set asc_lib_subtype 41 
            ASC_build_reamer
        }
        "TAPER_REAMER"
        {
            set asc_lib_subtype 42 
            ASC_build_reamer
        }
        "OD_TURNING"
        {
            set asc_lib_subtype 1 
            ASC_build_turning
        }
        "ID_TURNING"
        {
            set asc_lib_subtype 2 
            ASC_build_turning
        }
        "UG_TURNING_STD"
        {
            set asc_lib_subtype 90 
            ASC_build_turning
        }
        "UG_TURNING_BUTTON"
        {
            set asc_lib_subtype 91 
            ASC_build_turning
        }
        "OD_GROOVING"
        {
            set asc_lib_subtype 11 
            ASC_build_grooving
        }
        "ID_GROOVING"
        {
            set asc_lib_subtype 12 
            ASC_build_grooving
        }
        "FACE_GROOVING"
        {
            set asc_lib_subtype 13 
            ASC_build_grooving
        }
        "UG_GROOVING_STD"
        {
            set asc_lib_subtype 92 
            ASC_build_grooving
        }
        "UG_GROOVING_USER"
        {
            set asc_lib_subtype 95 
            ASC_build_grooving
        }
        "PARTING"
        {
            set asc_lib_subtype 14 
            ASC_build_grooving
        }
        "UG_GROOVING_FNR"
        {
            set asc_lib_subtype 93 
            ASC_build_grooving_fnr
        }
        "UG_GROOVING_RING"
        {
            set asc_lib_subtype 94 
            ASC_build_grooving
        }
        "OD_PROFILING"
        {
            set asc_lib_subtype 21 
            ASC_build_turn_profiling
        }
        "ID_PROFILING"
        {
            set asc_lib_subtype 22 
            ASC_build_turn_profiling
        }
        "OD_THREADING"
        {
            set asc_lib_subtype 31 
            set asc_nx_subtype 1 
            ASC_build_thread
        }
        "ID_THREADING"
        {
            set asc_lib_subtype 32 
            set asc_nx_subtype 1 
            ASC_build_thread
        }
        "UG_THREADING_STD"
        {
            set asc_lib_subtype 96 
            set asc_nx_subtype 1 
            ASC_build_thread
        }
        "UG_THREADING_TRAPEZ"
        {
            set asc_lib_subtype 97 
            set asc_nx_subtype 4 
            ASC_build_thread
        }
        "TURN_FORM"
        {
            ASC_build_turn_form
        }
        "GENERIC"
        {
            ASC_build_solid_generic
        }
        "WIRE"
        {
            ASC_build_wire
        }
        "PROBE"
        {
            ASC_build_solid_probe
        }
        "STD_LASER"
        {
            set asc_lib_subtype 1
            set asc_nx_subtype 0 
            ASC_build_soft_laser
        }
        "DEPOSITION_LASER"
        {
            set asc_lib_subtype 2
            set asc_nx_subtype 1 
            ASC_build_soft_laser
        }
        "ROBOTIC_END_MILL"
        {
            set asc_lib_subtype 1
            set asc_nx_subtype 1 
            ASC_build_end_mill_with_type 07
        }
        "ROBOTIC_BALL_MILL"
        {
			# Changed library subtype to 3 so that it is consistent with the BALL MILL 
            set asc_lib_subtype 3
            set asc_nx_subtype 4
            ASC_build_end_mill_with_type 07
        }
        "MULTITOOL_TURN"
        {
            set asc_lib_subtype $uglib_tl_stype(MULTITOOL_TURN)
            ASC_build_multitool
        }
        "MULTITOOL_DRILL_TURN"
        {
            set asc_lib_subtype $uglib_tl_stype(MULTITOOL_DRILL_TURN)
            ASC_build_multitool
        }
        "TANGENT_BARREL_MILL"
        {
            set asc_lib_subtype 94
            ASC_build_tangent_barrel_mill
        }
        "TAPER_BARREL_MILL"
        {
            set asc_lib_subtype 95
            ASC_build_taper_barrel_mill
        }
        "FUSED_DEPOSITION_MATERIAL_EXTRUDER"
        {
            set asc_lib_subtype 1
            set asc_nx_subtype 0
            ASC_build_fused_deposition
        }
        "HARDENING_LASER"
        {
            set asc_lib_subtype $uglib_tl_stype(HARDENING_LASER)
            ASC_build_hardening_laser
        }
        "STAMPING"
        {
            set asc_lib_subtype $uglib_tl_stype(STAMPING)
            ASC_build_stamping
        }
    }
}

proc ASC_update {} \
{
    global asc_database_name
    global asc_file_name
    global asc_units
    global dbc_part_units
    global dbc_event_error
    global dbc_logname

    global dbc_class
    global dbc_libref

    global dbc_clsf_decimal_places
    global mom_clsf_decimal_places

    global asc_cur_line
    global asc_record_type
    global asc_class
    global asc_record_libref
    global new_tool_record

    global num_formats_processed

    set dbc_class ""

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
    set class_match -1
    set add_libref 0

#  Cycle over all the records in the input file looking for the spot
#    to insert the input tool
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
                puts $tmp_fileid $asc_cur_line
            }
            "Class"
            {
                puts $tmp_fileid $asc_cur_line
            }
            "Format"
            {
                puts $tmp_fileid $asc_cur_line
                if {[string match *HLDREF* $asc_cur_line] == 1} \
                {
                    set add_libref 1
                } else \
                {
                    set add_libref 0
                }
            }
            "Data"
            {
                if { $add_libref == 1 } \
                {
                    append asc_cur_line " | "
                }
                puts $tmp_fileid $asc_cur_line
            }
            "End Data"
            {
                puts $tmp_fileid $asc_cur_line
                set add_libref 0
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
}

