###########################################################################
# dbc_tool_build_ascii.tcl -
#  Tool build procedures for tool classes as defined in dbc_tool_ascii.def
###########################################################################
###########################################################################
#
#
#  End Mill Non-Indexable
#  End Mill Indexable
#  Ball Mill Non-Indexable
#  Face Mill Indexable
#  Chamfer Mill Non-Indexable
#  Spherical Mill Non-Indexable
proc ASC_build_end_mill_with_type {libtype} \
{
    global dbc_libref
    global new_tool_record
    global dbc_template_aliases
    global dbc_template_attributes

    global asc_lib_subtype
    global asc_nx_subtype
    global asc_alias_index
    global asc_lookup_alias
    global dbc_tool_chamfer_length

#  Initialize the record with its libref
    set new_tool_record "DATA | $dbc_libref"

#  Add the library and UG type and subtype fields
    append new_tool_record " | $libtype | $asc_lib_subtype | 01 | $asc_nx_subtype"

#  Now the description
    ASC_append_tool_description

#  Tool material and material description
    ASC_append_material_and_description

#  Tool number, adjust and cutcom registers
    ASC_append_tool_number

    ASC_append_tool_length_adjust_register

    ASC_append_cutcom_register

#  Holding system and description
    ASC_append_holding_system

#  diameter, number of flutes, length and Z offset
    if {$asc_lib_subtype == 12} \
    {
        #convert the chamfer mill parameters to face mill parameters first
        ASC_convert_chamfer_mill_to_face_mill
        
        #append the bottom dia
        global bottom_diameter
        append new_tool_record " | $bottom_diameter"
    } else \
    {
        ASC_append_tool_diameter
    }

    ASC_append_flutes_number

    ASC_append_tool_length

    ASC_append_tool_zoffset

#  direction, flute length, taper, corner radius
    ASC_append_tool_direction

    ASC_append_tool_flute_length

    if {$asc_lib_subtype == 6} {
        ASC_append_neck_diameter
    }

    if {$asc_lib_subtype != 6} {
        #  Face Mill doesn't use taper angle, but it does have a
        #    second diameter
        if { $asc_lib_subtype == 12} {
            ASC_append_tool_diameter
        } else {
            ASC_append_taper_angle

            # Output tip angle for end mill
            if {$asc_lib_subtype == 1 || $asc_lib_subtype == 2} {
                ASC_append_tip_angle false
            }
        }

        if {$asc_lib_subtype == 5} \
        {
            set tmp [format " | %.5f" $dbc_tool_chamfer_length]
            append new_tool_record $tmp
        }

        ASC_append_corner1_radius
    }

    ASC_append_coolant_through

#  Holder offset and rigidity
    ASC_append_holder_offset

    ASC_append_z_mount

    ASC_append_rigidity
    
    ASC_append_shank_record

    ASC_append_milling_machining_parameters

    ASC_append_holder_libref

#  Append trackpoint libref
    ASC_append_tp_libref

#  Append helix angle only if tools are non-robotic
    if {$libtype != 7} \
    {
        ASC_append_tool_helix_angle
    }
}

proc ASC_build_end_mill { } \
{
    ASC_build_end_mill_with_type 02
}

#
#
#  T Cutter
proc ASC_build_t_cutter { } \
{
    global dbc_libref
    global new_tool_record

    global asc_lib_subtype

#  Initialize the record with its libref
    set new_tool_record "DATA | $dbc_libref"

#  Add the library and UG type and subtype fields
    append new_tool_record " | 02 | 21 | 08 | 00"

#  Now the description
    ASC_append_tool_description

#  Tool material and material description
    ASC_append_material_and_description

#  Tool number, adjust and cutcom registers
    ASC_append_tool_number

    ASC_append_tool_length_adjust_register

    ASC_append_cutcom_register

#  Holding system and description
     ASC_append_holding_system

#  diameter, number of flutes, length and Z offset
    ASC_append_tool_diameter

    ASC_append_flutes_number

    ASC_append_tool_length

    ASC_append_tool_zoffset

#  direction, flute length, shank diameter
    ASC_append_tool_direction

    ASC_append_tool_flute_length

    ASC_append_neck_diameter

#  lower and upper corner radii
    ASC_append_lower_and_upper_corner_radius

    ASC_append_coolant_through

#  Holder offset and rigidity
    ASC_append_holder_offset

    ASC_append_z_mount

    ASC_append_rigidity
    
    ASC_append_shank_record

    ASC_append_milling_machining_parameters

    ASC_append_holder_libref

#  Append trackpoint libref
    ASC_append_tp_libref

    ASC_append_tool_helix_angle
}
#
#
#  Barrel Cutter
proc ASC_build_barrel_mill { } \
{
    global dbc_libref
    global dbc_tool_barrel_radius
    global dbc_tool_barrel_center_y
    global new_tool_record
    global asc_lib_subtype

#  Initialize the record with its libref
    set new_tool_record "DATA | $dbc_libref"

#  Add the library fields
    append new_tool_record " | 02 | 93 "

#  Now the description
    ASC_append_tool_description

#  Tool material and material description
    ASC_append_material_and_description

#  Tool number, adjust and cutcom registers
    ASC_append_tool_number

    ASC_append_tool_length_adjust_register

    ASC_append_cutcom_register

#  Holding system and description
    ASC_append_holding_system

#  diameter, number of flutes, length and Z offset
    ASC_append_tool_diameter

    ASC_append_flutes_number

    ASC_append_tool_length

    ASC_append_tool_zoffset

#  direction, flute length, shank diameter
    ASC_append_tool_direction

    ASC_append_tool_flute_length

    ASC_append_neck_diameter

#  lower and upper corner radii
    ASC_append_lower_and_upper_corner_radius

#  Barrel radius and Y center
    if {[info exists dbc_tool_barrel_radius]} \
    {
        set tmp [format " | %.5f" $dbc_tool_barrel_radius]
        append new_tool_record $tmp
    } else \
    {
        append new_tool_record " |"
    }
    if {[info exists dbc_tool_barrel_center_y]} \
    {
        set tmp [format " | %.5f" $dbc_tool_barrel_center_y]
        append new_tool_record $tmp
    } else \
    {
        append new_tool_record " |"
    }

    ASC_append_coolant_through

#  Holder offset and rigidity
    ASC_append_holder_offset

    ASC_append_z_mount

    ASC_append_rigidity

    ASC_append_shank_record

    ASC_append_milling_machining_parameters

    ASC_append_holder_libref

#  Append trackpoint libref
    ASC_append_tp_libref

    ASC_append_tool_helix_angle
}
#
#  NX 5 Parameter Cutter
#  NX 7 Parameter Cutter
#  NX 10 Parameter Cutter
proc ASC_build_ug_cutter { } \
{
    global dbc_libref
    global dbc_tool_corner1_radius
    global dbc_tool_corner1_center_x
    global dbc_tool_corner1_center_y
    global dbc_tool_corner2_radius
    global dbc_tool_corner2_center_x
    global dbc_tool_corner2_center_y

    global new_tool_record
    global asc_lib_subtype

#  Initialize the record with its libref
    set new_tool_record "DATA | $dbc_libref"

#  Add the library fields and NX type/subtype as needed
    append new_tool_record " | 02 | $asc_lib_subtype "
    if { $asc_lib_subtype == 91 } \
    {
        append new_tool_record " | 01 | 02"
    } elseif { $asc_lib_subtype == 92 } \
    {
        append new_tool_record " | 01 | 03"
    }

#  Now the description
    ASC_append_tool_description

#  Tool material and material description
    ASC_append_material_and_description

#  Tool number, adjust and cutcom registers
    ASC_append_tool_number

    ASC_append_tool_length_adjust_register

    ASC_append_cutcom_register

#  Holding system and description for 7 and 10 param cutters
    if { $asc_lib_subtype == 91 || $asc_lib_subtype == 92} \
    {
       ASC_append_holding_system 
    }

#  diameter, number of flutes, length and Z offset
    ASC_append_tool_diameter

    ASC_append_flutes_number

    ASC_append_tool_length

    ASC_append_tool_zoffset

#  direction, flute length
    ASC_append_tool_direction

    ASC_append_tool_flute_length

#  Tip and Taper Angles for 5 param
    if { $asc_lib_subtype == 90} \
    {
        ASC_append_tip_angle false

        ASC_append_taper_angle
    } else \
    {
#  Reverse them for 7 and 10 param cutters
        ASC_append_taper_angle

        ASC_append_tip_angle false
    }

#  Corner radius and center X and Y for 7 Param and 10 Param
    if {[info exists dbc_tool_corner1_radius]} {
        ASC_append_value_without_right_zeros $dbc_tool_corner1_radius
    } else {
        append new_tool_record " |"
    }

    if { $asc_lib_subtype == 91 || $asc_lib_subtype == 92} \
    {
        if {[info exists dbc_tool_corner1_center_x]} \
        {
            ASC_append_value_without_right_zeros $dbc_tool_corner1_center_x 
        } else \
        {
            append new_tool_record " |"
        }
        if {[info exists dbc_tool_corner1_center_y]} \
        {
            ASC_append_value_without_right_zeros $dbc_tool_corner1_center_y 
        } else \
        {
            append new_tool_record " |"
        }
    }

#  Second Corner radius and center X and Y for 10 Param
    if { $asc_lib_subtype == 92 } \
    {
        if {[info exists dbc_tool_corner2_radius]} \
        {
            ASC_append_value_without_right_zeros $dbc_tool_corner2_radius 
        } else \
        {
            append new_tool_record " |"
        }
        if {[info exists dbc_tool_corner2_center_x]} \
        {
            ASC_append_value_without_right_zeros $dbc_tool_corner2_center_x 
        } else \
        {
            append new_tool_record " |"
        }
        if {[info exists dbc_tool_corner2_center_y]} \
        {
            ASC_append_value_without_right_zeros $dbc_tool_corner2_center_y 
        } else \
        {
            append new_tool_record " |"
        }
    }

    ASC_append_coolant_through

#  Holder offset and rigidity
    ASC_append_holder_offset

    ASC_append_z_mount

    ASC_append_rigidity

    ASC_append_shank_record

    ASC_append_milling_machining_parameters

    ASC_append_holder_libref

#  Append trackpoint libref
    ASC_append_tp_libref

# Relief Length and Relief Diameter for  UG 5 Parameter Mill
    if { $asc_lib_subtype == 90} \
    {
        ASC_append_relief_diameter

        ASC_append_relief_length
    }

    ASC_append_tool_helix_angle
}
#
#
#  Thread Mill
proc ASC_build_thread_mill { } \
{
    global dbc_libref
    global dbc_option_value
    global new_tool_record
    global dbc_template_attributes

    global asc_lib_subtype
    global asc_alias_index
    global asc_lookup_alias

#  Initialize the record with its libref
    set new_tool_record "DATA | $dbc_libref"

#  Add the library and UG type and subtype fields
    append new_tool_record " | 02 | 31 | 02 | 10"

#  Now the description
    ASC_append_tool_description

#  Tool material and material description
    ASC_append_material_and_description

#  Tool number, adjust and cutcom registers
    ASC_append_tool_number

    ASC_append_tool_length_adjust_register

    ASC_append_cutcom_register

#  Holding system and description
    ASC_append_holding_system

#  diameter, number of flutes, length and Z offset
    ASC_append_tool_diameter

    ASC_append_flutes_number

    ASC_append_tool_length

    ASC_append_tool_zoffset

#  direction, Thread shape and Description and pitch
    ASC_append_tool_direction

    set asc_lookup_alias "ThreadShapeDrill"
    ASC_find_template_alias

#   add form type.
    append new_tool_record " | $::dbc_tool_form_type |"

    ASC_append_tool_pitch

#  flute length, taper angle, corner radius and shank diameter
    ASC_append_tool_flute_length

    ASC_append_taper_angle

    ASC_append_corner1_radius

    ASC_append_neck_diameter

    ASC_append_coolant_through

#  Holder offset and rigidity
    ASC_append_holder_offset

    ASC_append_z_mount

    ASC_append_rigidity
    
    ASC_append_shank_record

    ASC_append_milling_machining_parameters

    ASC_append_holder_libref

#  Append trackpoint libref
    ASC_append_tp_libref

#  Append tool designation
    ASC_append_designation
}
#
#
#  Twist Drill
#  Index Insert Drill
#  Core Drill (indexable)
#  Core Drill (non indexable)
#  Insert Drill
#  Gun Drill
#  Spot Drill
#  UG Drill
#  Spot Facing
proc ASC_build_drill { } \
{
    global dbc_libref
    global new_tool_record

    global asc_lib_subtype
    global asc_nx_subtype

#  Initialize the record with its libref
    set new_tool_record "DATA | $dbc_libref"

#  Add the library type and subtype fields
    append new_tool_record " | 03 | $asc_lib_subtype"

#  For all but UG Drill, add the UG type and subtype fields
    if {$asc_lib_subtype != 90} \
    {
        append new_tool_record " | 02 | $asc_nx_subtype"
    }

#  Now the description
    ASC_append_tool_description

#  Tool material and material description
    ASC_append_material_and_description

#  Tool number, adjust and cutcom registers
    ASC_append_tool_number

    ASC_append_tool_length_adjust_register

    ASC_append_cutcom_register

#  For all but UG Drill, add the Holding system and description
    if {$asc_lib_subtype != 90} \
    {
       ASC_append_holding_system 
    }

#  diameter, number of flutes, length and Z offset
    ASC_append_tool_diameter

    ASC_append_flutes_number

    ASC_append_tool_length

    ASC_append_tool_zoffset

#  direction
    ASC_append_tool_direction

#  flute length, point angle and point length (except spot facing)
    ASC_append_tool_flute_length

    if { $asc_lib_subtype != 12} \
    {
        ASC_append_point_angle
        ASC_append_point_length
    }

#  corner radius
    if { $asc_lib_subtype != 21} \
    {
        ASC_append_corner1_radius
    }

    ASC_append_coolant_through

#  Holder offset and rigidity
    ASC_append_holder_offset

    ASC_append_z_mount

    ASC_append_rigidity

    ASC_append_shank_record

    ASC_append_holder_libref

#  Append trackpoint libref
    ASC_append_tp_libref
}
#
#
#  Center Drill
proc ASC_build_center_drill { } \
{
    global dbc_libref
    global new_tool_record

    global asc_lib_subtype

    global dbc_tool_bell_diameter
    global dbc_tool_bell_angle

#  Initialize the record with its libref
    set new_tool_record "DATA | $dbc_libref"

#  Add the library and UG type and subtype fields
    append new_tool_record " | 03 | 22 | 02 | 01"

#  Now the description
    ASC_append_tool_description

#  Tool material and material description
    ASC_append_material_and_description

#  Tool number, adjust and cutcom registers
    ASC_append_tool_number

    ASC_append_tool_length_adjust_register

    ASC_append_cutcom_register

#  Holding system and description
    ASC_append_holding_system

#  diameter (tip diameter), number of flutes, length and Z offset
    ASC_append_tool_tip_diameter

    ASC_append_flutes_number

    ASC_append_tool_length

    ASC_append_tool_zoffset

#  direction
    ASC_append_tool_direction

#  flute length, point angle
    ASC_append_tool_flute_length
    
    ASC_append_tool_tip_length

    ASC_append_point_angle

    ASC_append_point_length

#  Second diameter and Included angle
    ASC_append_tool_diameter

    ASC_append_included_angle

    #Bell angle and bell diameter
    if {[info exists dbc_tool_bell_angle]} {
        set tmp_angle [UGLIB_convert_rad_to_deg $dbc_tool_bell_angle]
        append new_tool_record [format " | %.5f" $tmp_angle]
    } else {
        append new_tool_record " |"
    }

    if {[info exists dbc_tool_bell_diameter]} {
        append new_tool_record [format " | %.5f" $dbc_tool_bell_diameter]
    } else {
        append new_tool_record " |"
    }

    ASC_append_coolant_through

#  Holder offset and rigidity
    ASC_append_holder_offset

    ASC_append_z_mount

    ASC_append_rigidity

    ASC_append_shank_record

    ASC_append_holder_libref

#  Append trackpoint libref
    ASC_append_tp_libref

#  Append tool designation
    ASC_append_designation
}
#
#
#  Bore - Fixed Diameter
proc ASC_build_bore { } \
{
    global dbc_libref
    global new_tool_record

    global asc_lib_subtype

#  Initialize the record with its libref
    set new_tool_record "DATA | $dbc_libref"

#  Add the library and UG type and subtype fields
    append new_tool_record " | 03 | 32 | 02 | 05"

#  Now the description
    ASC_append_tool_description

#  Tool material and material description
    ASC_append_material_and_description

#  Tool number, adjust and cutcom registers
    ASC_append_tool_number

    ASC_append_tool_length_adjust_register

    ASC_append_cutcom_register

#  Holding system and description
    ASC_append_holding_system

#  diameter, number of flutes, length and Z offset
    ASC_append_tool_diameter

    ASC_append_flutes_number

    ASC_append_tool_length

    ASC_append_tool_zoffset

#  direction and corner radius
    ASC_append_tool_direction

    ASC_append_corner1_radius

#  flute length, shank diameter
    ASC_append_tool_flute_length

    ASC_append_neck_diameter

    ASC_append_coolant_through

#  Holder offset and rigidity
    ASC_append_holder_offset

    ASC_append_z_mount

    ASC_append_rigidity

    ASC_append_shank_record

    ASC_append_holder_libref

#  Append trackpoint libref
    ASC_append_tp_libref
}
#
#
#  Counter Bore - Non-Indexable
proc ASC_build_counter_bore { } \
{
    global dbc_libref
    global new_tool_record

    global asc_lib_subtype

#  Initialize the record with its libref
    set new_tool_record "DATA | $dbc_libref"

#  Add the library and UG type and subtype fields
    append new_tool_record " | 03 | 51 | 02 | 07"

#  Now the description
    ASC_append_tool_description

#  Tool material and material description
    ASC_append_material_and_description

#  Tool number, adjust and cutcom registers
    ASC_append_tool_number

    ASC_append_tool_length_adjust_register

    ASC_append_cutcom_register

#  Holding system and description
    ASC_append_holding_system

#  diameter, pilot diameter and length
    ASC_append_tool_diameter

    ASC_append_pilot_diameter_and_length

#  flute length, number of flutes, length and Z offset
    ASC_append_tool_flute_length

    ASC_append_flutes_number

    ASC_append_tool_length

    ASC_append_tool_zoffset

#  direction
    ASC_append_tool_direction

    # corner radius
    ASC_append_corner1_radius

    ASC_append_coolant_through

#  Holder offset and rigidity
    ASC_append_holder_offset

    ASC_append_z_mount

    ASC_append_rigidity

    ASC_append_shank_record

    ASC_append_holder_libref

#  Append trackpoint libref
    ASC_append_tp_libref
}

proc ASC_append_front_insert_length {} {
    global new_tool_record
    global dbc_front_insert_length

    if {[info exists dbc_front_insert_length]} {
        append new_tool_record [format " | %.5f" $dbc_front_insert_length]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_lead_angle {} {
    global new_tool_record
    global dbc_tool_lead_angle

    if {[info exists dbc_tool_lead_angle]} {
        set tmp_angle [UGLIB_convert_rad_to_deg $dbc_tool_lead_angle]
        append new_tool_record [format " | %.5f" $tmp_angle]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_insert_angle {} {
    global new_tool_record
    global dbc_tool_insert_angle

    if {[info exists dbc_tool_insert_angle]} {
        set tmp_angle [UGLIB_convert_rad_to_deg $dbc_tool_insert_angle]
        append new_tool_record [format " | %.5f" $tmp_angle]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_back_insert_length {} {
    global new_tool_record
    global dbc_back_insert_length

    if {[info exists dbc_back_insert_length]} {
        append new_tool_record [format " | %.5f" $dbc_back_insert_length]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_relief_length {} {
    global new_tool_record
    global dbc_relief_length

    if {[info exists dbc_relief_length]} {
        append new_tool_record [format " | %.5f" $dbc_relief_length]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_relief_width {} {
    global new_tool_record
    global dbc_relief_width

    if {[info exists dbc_relief_width]} {
        append new_tool_record [format " | %.5f" $dbc_relief_width]
    } else {
        append new_tool_record " |"
    }
}

#
#
#  Boring Bar
proc ASC_build_boring_bar { } \
{
    global dbc_libref
    global new_tool_record

    global asc_lib_subtype

#  Initialize the record with its libref
    set new_tool_record "DATA | $dbc_libref"

#  Add the library and UG type and subtype fields
    append new_tool_record " | 03 | 33 | 02 | 15"

#  Now the description
    ASC_append_tool_description

#  Tool material and material description
    ASC_append_material_and_description

#  Tool number and adjust registers
    ASC_append_tool_number

    ASC_append_tool_length_adjust_register

#  diameter, neck diameter, tool length, tip length and tip diameter
    ASC_append_tool_diameter

    ASC_append_neck_diameter

    ASC_append_tool_length

    ASC_append_pilot_diameter_and_length

#  front insert length, lead angle, corner1 radius, insert angle, back insert length, back angle and relief length
    ASC_append_front_insert_length

    ASC_append_lead_angle

    ASC_append_corner1_radius

    ASC_append_insert_angle

    ASC_append_back_insert_length

    ASC_append_relief_length

    ASC_append_relief_width

    ASC_append_shank_record

#  Holding system and description
    ASC_append_holding_system

    ASC_append_holder_libref

#  Append trackpoint libref
    ASC_append_tp_libref
}

proc ASC_append_corner2_radius {} {
    global new_tool_record
    global dbc_tool_corner2_radius

    if {[info exists dbc_tool_corner2_radius]} {
        append new_tool_record [format " | %.5f" $dbc_tool_corner2_radius]
    } else {
        append new_tool_record " |"
    }
}

#
#
#  Chamfer Boring Bar
proc ASC_build_chamfer_boring_bar { } \
{
    global dbc_libref
    global new_tool_record

    global asc_lib_subtype

#  Initialize the record with its libref
    set new_tool_record "DATA | $dbc_libref"

#  Add the library and UG type and subtype fields
    append new_tool_record " | 03 | 34 | 02 | 16"

#  Now the description
    ASC_append_tool_description

#  Tool material and material description
    ASC_append_material_and_description

#  Tool number and adjust registers
    ASC_append_tool_number

    ASC_append_tool_length_adjust_register

#  diameter, neck diameter, tool length, tip length and tip diameter
    ASC_append_tool_diameter

    ASC_append_neck_diameter

    ASC_append_tool_length

    ASC_append_pilot_diameter_and_length

#  lower corner radius, front insert length, lead angle, corner1 radius, insert angle, back insert length, back angle and relief length
    ASC_append_corner1_radius

    ASC_append_front_insert_length

    ASC_append_lead_angle

    ASC_append_corner2_radius

    ASC_append_insert_angle

    ASC_append_back_insert_length

    ASC_append_relief_length

    ASC_append_relief_width

    ASC_append_shank_record

#  Holding system and description
    ASC_append_holding_system

    ASC_append_holder_libref

#  Append trackpoint libref
    ASC_append_tp_libref
}

#
#
#  Counter Sink - Non-Indexable
proc ASC_build_counter_sink { } \
{
    global dbc_libref
    global new_tool_record

    global asc_lib_subtype

#  Initialize the record with its libref
    set new_tool_record "DATA | $dbc_libref"

#  Add the library and UG type and subtype fields
    append new_tool_record " | 03 | 61 | 02 | 02"

#  Now the description
    ASC_append_tool_description

#  Tool material and material description
    ASC_append_material_and_description

#  Tool number, adjust and cutcom registers
    ASC_append_tool_number

    ASC_append_tool_length_adjust_register

    ASC_append_cutcom_register

#  Holding system and description
    ASC_append_holding_system

#  diameter, tip diameter and point angle
    ASC_append_tool_diameter

    ASC_append_tool_tip_diameter

    ASC_append_included_angle

#  flute length, number of flutes, length and Z offset
    ASC_append_flutes_number

    ASC_append_tool_length

    ASC_append_tool_zoffset

#  direction
    ASC_append_tool_direction
    
#  flute length
    ASC_append_tool_flute_length

    ASC_append_coolant_through

#  Holder offset and rigidity
    ASC_append_holder_offset

    ASC_append_z_mount

    ASC_append_rigidity

    ASC_append_shank_record

    ASC_append_holder_libref

#  Append trackpoint libref
    ASC_append_tp_libref
}

proc ASC_append_min_hole_diameter {} {
    global new_tool_record
    global dbc_tool_min_hole_diameter

    if {[info exists dbc_tool_min_hole_diameter]} {
        append new_tool_record [format " | %.5f" $dbc_tool_min_hole_diameter]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_insert_size {} {
    global new_tool_record
    global dbc_tool_insert_size

    if {[info exists dbc_tool_insert_size]} {
        append new_tool_record [format " | %.5f" $dbc_tool_insert_size]
    } else {
        append new_tool_record " |"
    }
}

#
#
#  Back Counter Sink
proc ASC_build_back_counter_sink { } \
{
    global dbc_libref
    global new_tool_record

    global asc_lib_subtype

#  Initialize the record with its libref
    set new_tool_record "DATA | $dbc_libref"

#  Add the library and UG type and subtype fields
    append new_tool_record " | 03 | 63 | 02 | 14"

#  Now the description
    ASC_append_tool_description

#  Tool material and material description
    ASC_append_material_and_description

#  Tool number, adjust and cutcom registers
    ASC_append_tool_number

    ASC_append_tool_length_adjust_register

#  diameter, neck diameter, min hole diameter and insert size
    ASC_append_tool_diameter

    ASC_append_neck_diameter

    ASC_append_tool_length

    ASC_append_min_hole_diameter

    ASC_append_insert_size

    ASC_append_corner1_radius

    ASC_append_shank_record

#  Holding system and description
    ASC_append_holding_system

    ASC_append_holder_libref

#  Append trackpoint libref
    ASC_append_tp_libref
}
#
#
#  Tap
proc ASC_build_tap { } \
{
    global dbc_libref
    global dbc_option_value
    global new_tool_record
    global dbc_template_attributes

    global asc_lib_subtype
    global asc_alias_index
    global asc_lookup_alias

#  Initialize the record with its libref
    set new_tool_record "DATA | $dbc_libref"

#  Add the library and UG type and subtype fields
    append new_tool_record " | 03 | 71 | 02 | 08"

#  Now the description
    ASC_append_tool_description

#  Tool material and material description
    ASC_append_material_and_description

#  Tool number, adjust and cutcom registers
    ASC_append_tool_number

    ASC_append_tool_length_adjust_register

    ASC_append_cutcom_register

#  Holding system and description
    ASC_append_holding_system

#  diameter, thread shape and description
    ASC_append_tool_diameter

    set asc_lookup_alias "ThreadShapeDrill"
    ASC_find_template_alias
    if {$asc_alias_index > -1 } \
    {
        set option_id "$dbc_template_attributes($asc_alias_index)"
        DBC_ask_option_value "ThreadShapeDrill" $option_id
        append new_tool_record " | $dbc_template_attributes($asc_alias_index)"
        append new_tool_record " | $dbc_option_value"
    } else \
    {
        append new_tool_record " | |"
    }

#  pitch, flute length, tip length
    ASC_append_tool_pitch

    ASC_append_tool_flute_length

    ASC_append_tool_tip_length

#  tool height and z-offset
    ASC_append_tool_length

    ASC_append_tool_zoffset

#  direction
    ASC_append_tool_direction

    # Neck Diameter
    # Taper Angle
    # Taper Diameter Distance
    ASC_append_neck_diameter

    ASC_append_taper_angle

    ASC_append_taper_diameter_distance

    ASC_append_included_angle

    ASC_append_tool_tip_diameter

    ASC_append_coolant_through

#  Holder offset and rigidity
    ASC_append_holder_offset

    ASC_append_z_mount

    ASC_append_rigidity

    ASC_append_shank_record

    ASC_append_holder_libref

#  Append trackpoint libref
    ASC_append_tp_libref

#  Append tool designation
    ASC_append_designation

#  Append number of flutes. New in NX12
	ASC_append_flutes_number
}
#
#
#  Chucking Reamer
#  Taper Reamer
proc ASC_build_reamer { } \
{
    global dbc_libref
    global new_tool_record

    global asc_lib_subtype
    global asc_nx_subtype

#  Initialize the record with its libref
    set new_tool_record "DATA | $dbc_libref"

#  Add the library and UG type and subtype fields
    append new_tool_record " | 03 | $asc_lib_subtype | 02 | 06"

#  Now the description
    ASC_append_tool_description

#  Tool material and material description
    ASC_append_material_and_description

#  Tool number, adjust and cutcom registers
    ASC_append_tool_number

    ASC_append_tool_length_adjust_register

    ASC_append_cutcom_register

#  Holding system and description
    ASC_append_holding_system

#  diameter, number of flutes, length and Z offset
    ASC_append_tool_diameter

    ASC_append_flutes_number

    ASC_append_tool_length

    ASC_append_tool_zoffset

#  direction, flute length, tip length
    ASC_append_tool_direction

    ASC_append_tool_flute_length

    ASC_append_tool_tip_length

    # Neck Diameter
    # Taper Angle
    # Taper Diameter Distance
    ASC_append_neck_diameter

    ASC_append_taper_angle

    ASC_append_taper_diameter_distance

    ASC_append_coolant_through

#  Holder offset and rigidity
    ASC_append_holder_offset

    ASC_append_z_mount

    ASC_append_rigidity

    ASC_append_shank_record

    ASC_append_holder_libref

#  Append trackpoint libref
    ASC_append_tp_libref
}

#
#
#  OD Turning
#  ID Turning
#  UG Turning Standard
#  UG Turning Button
proc ASC_build_turning { } \
{
    global dbc_libref
    global dbc_tool_insert_type
    global dbc_tool_nose_angle
    global dbc_tool_cut_edge_length
    global dbc_tool_size_o
    global dbc_tool_thickness_o
    global dbc_tool_relief_angle_o
    global new_tool_record
    global dbc_tool_button_diameter
    global dbc_tool_holder_angle
    global dbc_tool_holder_width

    global asc_lib_subtype
    global asc_nx_subtype

#  Initialize the record with its libref
    set new_tool_record "DATA | $dbc_libref"

#  Add the library type and subtype fields
    append new_tool_record " | 01 | $asc_lib_subtype"

#  for OD,ID Turning Tools and Button, put UG internal type and subtypes
    if {$asc_lib_subtype == 1 || $asc_lib_subtype == 2} \
    {
        append new_tool_record " | 03 | 01"
    } elseif {$asc_lib_subtype == 91} {
        append new_tool_record " | 03 | 02"
    }

#  Now the description
    ASC_append_tool_description

#  Tool material and material description
    ASC_append_material_and_description

#  Tool number, adjust and cutcom registers
    ASC_append_tool_number

    ASC_append_tool_length_adjust_register

    ASC_append_cutcom_register

#  for OD and ID Turning Tools, put Holding system and description
    if {$asc_lib_subtype == 1 || $asc_lib_subtype == 2 } \
    {
        ASC_append_holding_system
    }

#  Insert type, orientation angle
    if {[info exists dbc_tool_insert_type]} \
    {
        set tmp [UGLIB_unconvert_inserttype $dbc_tool_insert_type]
        append new_tool_record " | $tmp"
    } else \
    {
        append new_tool_record " |"
    }

    ASC_append_turning_tool_orientation

#  For Button tools, add button diameter, holder angle and width
    if { $asc_lib_subtype == 91 } \
    {
        if {[info exists dbc_tool_button_diameter]} \
        {
            set tmp [format " | %.5f" $dbc_tool_button_diameter]
            append new_tool_record $tmp
        } else \
        {
            append new_tool_record " |"
        }
        if {[info exists dbc_tool_holder_angle]} \
        {
            set tmp_angle [UGLIB_convert_rad_to_deg $dbc_tool_holder_angle]
            set tmp [format " | %.5f" $tmp_angle]
            append new_tool_record $tmp
        } else \
        {
            append new_tool_record " |"
        }
        if {[info exists dbc_tool_holder_width]} \
        {
            set tmp [format " | %.5f" $dbc_tool_holder_width]
            append new_tool_record $tmp
        } else \
        {
            append new_tool_record " |"
        }
    } else \
    {
#  For others, add the next block of fields
#  nose angle and nose radius
        if {[info exists dbc_tool_nose_angle]} \
        {
            set tmp_angle [UGLIB_convert_rad_to_deg $dbc_tool_nose_angle]
            set tmp [format " | %.5f" $tmp_angle]
            append new_tool_record $tmp
        } else \
        {
            append new_tool_record " |"
        }

        ASC_append_turning_nose_radius

#  Cut edge length and inscribed circle
        if {[info exists dbc_tool_cut_edge_length]} \
        {
            set tmp [format " | %.5f" $dbc_tool_cut_edge_length]
            append new_tool_record $tmp

#  The Cut edge length may have been computed from inscribed circle.
#    Check tool size option
            if {$dbc_tool_size_o == 0} \
            {
#  cut edge length specified directly.  Set Inscribed circle to 0.
                append new_tool_record " | "
            } else \
            {
#  cut edge length was computed from inscribed circle.  Reverse
#    the computation and save it.
                set ic_diam [UGLIB_convert_cut_edge_length_to_ic \
                    $dbc_tool_insert_type $dbc_tool_nose_angle \
                    $dbc_tool_cut_edge_length]
                set tmp [format " | %.5f" $ic_diam]
                append new_tool_record $tmp
            }
        } else \
        {
            append new_tool_record " |  |"
        }
    }

#  Tool thickness and type
    ASC_append_turning_tool_thickness

    if {[info exists dbc_tool_thickness_o]} \
    {
        set tmp [UGLIB_unconvert_thickness_type $dbc_tool_thickness_o]
        append new_tool_record " | $tmp"
    } else \
    {
        append new_tool_record " | "
    }

#  Relief angle and type
    ASC_append_turning_relief_angle

    if {[info exists dbc_tool_relief_angle_o]} \
    {
        set tmp [UGLIB_unconvert_relief_angle_type $dbc_tool_relief_angle_o]
        append new_tool_record " | $tmp"
    } else \
    {
        append new_tool_record " | "
    }

#  Max depth, X offset, Y offset
    ASC_append_max_depth

    ASC_append_turning_x_y_offset

#  Tracking point and insert position
    ASC_append_turning_append_tracking_point

    ASC_append_turning_insert_position

    ASC_append_min_boring_dia false

    ASC_append_max_toolreach false

    ASC_append_x_and_y_mount

    ASC_append_holder_angle

#  Rigidity
    ASC_append_rigidity

    ASC_append_holder_libref

#  Append trackpoint libref
    ASC_append_tp_libref

#  Append index notch and turret rotation angle
    ASC_append_index_notch_and_turret_rot_angle
}

#
#  OD Grooving
#  ID Grooving
#  Face Grooving
#  Parting
#  UG Grooving Standard
#  UG Grooving Ring
#  UG Grooving User
proc ASC_build_grooving { } \
{
    global dbc_libref
    global dbc_tool_size_o
    global dbc_tool_side_angle
    global dbc_tool_preset_cutter
    global new_tool_record

    global asc_lib_subtype
    global asc_nx_subtype

#  Initialize the record with its libref
    set new_tool_record "DATA | $dbc_libref"

#  Add the library type and subtype fields
    append new_tool_record " | 01 | $asc_lib_subtype"

#  For OD, ID and Parting add the UG type and subtype fields
    if { $asc_lib_subtype == 11 || $asc_lib_subtype == 12 || \
        $asc_lib_subtype == 14 || $asc_lib_subtype == 13 } \
    {
        append new_tool_record " | 04 | 01"
    }

#  Now the description
    ASC_append_tool_description

#  Tool material and material description
    ASC_append_material_and_description

#  Tool number, adjust and cutcom registers
    ASC_append_tool_number

    ASC_append_tool_length_adjust_register

    ASC_append_cutcom_register

#  Holding system and description for OD, ID and Parting
    if { $asc_lib_subtype == 11 || $asc_lib_subtype == 12 || \
        $asc_lib_subtype == 14 || $asc_lib_subtype == 13 } \
    {
        ASC_append_holding_system
    }

#  orientation angle, insert width and length
    ASC_append_turning_tool_orientation

#  For Ring cutter, store nose width, otherwise insert width
    if { $asc_lib_subtype == 94} {
        ASC_append_turning_nose_width
    } else {
        ASC_append_turning_insert_width 1.0
    }

    ASC_append_turning_insert_length

#  Radii, thickness, max depth
#    Skip radius for User Defined and Ring
    if { $asc_lib_subtype != 95 && $asc_lib_subtype != 94 } \
    {
        ASC_append_grooving_tool_radius

        if { $asc_lib_subtype == 92 } \
        {
            ASC_append_grooving_tool_radius
        }
    }

    ASC_append_turning_tool_thickness

    ASC_append_max_depth

#  User defined and Ring --  Left and Right side angles
    if { $asc_lib_subtype == 95 || $asc_lib_subtype == 94 } \
    {
        ASC_append_turning_left_and_right_angle

#   User Defined:  tip angle and two corner radii next
        if { $asc_lib_subtype == 95 } \
        {
            ASC_append_tip_angle false

            ASC_append_grooving_left_and_right_corner_radius
        }
    } else \
    {
#  Left and Right side angles -- OD and ID only have one, so put
#    side angle in both fields.  For Standard, check tip angle.
        if {[info exists dbc_tool_side_angle]} \
        {
            set tmp [ASC_append_side_angle]
            if { $asc_lib_subtype == 92 } \
            {
                ASC_append_tip_angle false

            } else \
            {
                append new_tool_record $tmp
            }
        } else \
        {
            append new_tool_record " | | "
        }
    }

#  Tracking point and insert position
    ASC_append_tracking_point

    ASC_append_turning_insert_position

#  For ID Grooving, load Minimum Boring Diameter and 
#    Max Toolreach go here
    if {$asc_lib_subtype == 12 } \
    {
        ASC_append_min_boring_dia false

        ASC_append_max_toolreach false
    }

#  For Parting, load Tip angle, X and Y offset and preset
    if { $asc_lib_subtype == 14 } \
    {
#  For Left cutter, the angle is negated, and the offsets are
#    in right offset
        if { $dbc_tool_preset_cutter == 2 } \
        {
            ASC_append_tip_angle true

            ASC_append_turning_right_x_offset

            ASC_append_turning_right_y_offset

            append new_tool_record " | L"
        } else \
        {
            ASC_append_tip_angle false

            ASC_append_turning_left_x_offset

            ASC_append_turning_left_y_offset

            append new_tool_record " | R"
        }
    } else \
    {
# Append tip angle for OD Grooving, ID Grooving and Face Grooving
        if { $asc_lib_subtype == 11 || $asc_lib_subtype == 12 || $asc_lib_subtype == 13 } \
        {
            ASC_append_tip_angle false
        }

# Left and right side X and Y offsets for all but Parting
        ASC_append_turning_left_x_offset

        ASC_append_turning_left_y_offset

        ASC_append_turning_right_x_offset

        ASC_append_turning_right_y_offset
    }

#  For Standard, User and Ring Grooving, and Parting, OD Grooving, Face Grooving 
#  load Minimum Boring Diameter and  Max Toolreach go here
    if {$asc_lib_subtype == 92 || $asc_lib_subtype == 95 || \
        $asc_lib_subtype == 94 || $asc_lib_subtype == 11 || \
        $asc_lib_subtype == 14 || $asc_lib_subtype == 13 } \
    {
        ASC_append_min_boring_dia false

        ASC_append_max_toolreach false
    }

    #For Face Grooving, append min/max face diameter
    if {$asc_lib_subtype == 13} {
        ASC_append_max_and_min_facing_diameter
    }

    ASC_append_x_and_y_mount

    ASC_append_holder_angle

#  Rigidity
    ASC_append_rigidity

    ASC_append_holder_libref

#  Append trackpoint libref
    ASC_append_tp_libref


#  Append index notch and turret rotation angle
    ASC_append_index_notch_and_turret_rot_angle

}

#
#  UG Grooving Full Nose Radius
proc ASC_build_grooving_fnr { } \
{
    global dbc_libref
    global dbc_tool_size_o
    global new_tool_record

    global asc_lib_subtype
    global asc_nx_subtype

#  Initialize the record with its libref
    set new_tool_record "DATA | $dbc_libref"

#  Add the library type and subtype fields
    append new_tool_record " | 01 | $asc_lib_subtype"

#  Now the description
    ASC_append_tool_description

#  Tool material and material description
    ASC_append_material_and_description

#  Tool number, adjust and cutcom registers
    ASC_append_tool_number

    ASC_append_tool_length_adjust_register

    ASC_append_cutcom_register

#  orientation angle, insert width, left side angle and length
    ASC_append_turning_tool_orientation

    ASC_append_turning_insert_width 1.0

    ASC_append_side_angle

    ASC_append_turning_insert_length

#  thickness, relief angle, max depth
    ASC_append_turning_tool_thickness

    ASC_append_turning_relief_angle
    
    ASC_append_max_depth

#  X and Y offsets
    ASC_append_turning_left_x_offset

    ASC_append_turning_left_y_offset

#  Tracking point and insert position
    ASC_append_tracking_point

    ASC_append_turning_insert_position

#  load Minimum Boring Diameter and Max Toolreach
    ASC_append_min_boring_dia false

    ASC_append_max_toolreach false

    ASC_append_x_and_y_mount

    ASC_append_holder_angle

#  Rigidity
    ASC_append_rigidity

    ASC_append_holder_libref

#  Append trackpoint libref
    ASC_append_tp_libref


#  Append index notch and turret rotation angle
    ASC_append_index_notch_and_turret_rot_angle


}
#
#  OD Profiling
#  ID Profiling
proc ASC_build_turn_profiling { } \
{
    global dbc_libref
    global dbc_tool_insert_length
    global dbc_tool_size_o
    global dbc_tool_left_tracking_point
    global new_tool_record

    global asc_lib_subtype
    global asc_nx_subtype

#  Initialize the record with its libref
    set new_tool_record "DATA | $dbc_libref"

#  Add the library type and subtype fields
    append new_tool_record " | 01 | $asc_lib_subtype"

#  add the UG type and subtype fields
    append new_tool_record " | 04 | 03"

#  Now the description
    ASC_append_tool_description

#  Tool material and material description
    ASC_append_material_and_description

#  Tool number, adjust and cutcom registers
    ASC_append_tool_number

    ASC_append_tool_length_adjust_register

    ASC_append_cutcom_register

#  Holding system and description for other than Turning Standard
    ASC_append_holding_system

#  orientation angle, radius, side angle, insert length
    ASC_append_turning_tool_orientation

    ASC_append_turning_insert_width 0.5

    ASC_append_side_angle

    ASC_append_turning_insert_length

#  Thickness, relief angle, max depth
    ASC_append_turning_tool_thickness

    ASC_append_turning_relief_angle

    ASC_append_max_depth

#  X and Y Offsets
#    For OD Profiling tools, the single offset values are stored in both
#    left and right offset variables, so we will use the left ones here.

    ASC_append_turning_left_x_offset

    ASC_append_turning_left_y_offset

#  Tracking point and insert position
#    For OD Profiling tools, the single tracking point value is stored
#    in both the left and right variables, so we will use the left one here.
    if {[info exists dbc_tool_left_tracking_point]} \
    {
        append new_tool_record " | $dbc_tool_left_tracking_point"
    } else \
    {
        append new_tool_record " | "
    }

    ASC_append_turning_insert_position

    ASC_append_min_boring_dia false

    ASC_append_max_toolreach false

    ASC_append_x_and_y_mount

    ASC_append_holder_angle

#  Rigidity
    ASC_append_rigidity

    ASC_append_holder_libref

#  Append trackpoint libref
    ASC_append_tp_libref

#  Append index notch and turret rotation angle
    ASC_append_index_notch_and_turret_rot_angle

}

#
#  OD Threading
#  ID Threading
#  UG Threading
#  UG Trapeziodal Threading
proc ASC_build_thread { } \
{
    global dbc_libref
    global dbc_option_value
    global dbc_tool_insert_width
    global dbc_tool_insert_length
    global dbc_tool_nose_width
    global dbc_tool_size_o
    global dbc_tool_tip_offset
    global dbc_tool_left_angle
    global dbc_tool_right_angle
    global new_tool_record
    global dbc_template_attributes

    global asc_lib_subtype
    global asc_nx_subtype
    global asc_alias_index
    global asc_lookup_alias

#  Initialize the record with its libref
    set new_tool_record "DATA | $dbc_libref"

#  Add the library type and subtype fields
    append new_tool_record " | 01 | $asc_lib_subtype"

#  add the UG type and subtype fields for OD and ID threads
    if { $asc_lib_subtype == 31 || $asc_lib_subtype == 32 } \
    {
        append new_tool_record " | 05 | $asc_nx_subtype"
    }

#  Now the description
    ASC_append_tool_description

#  Tool material and material description
    ASC_append_material_and_description

#  Tool number, adjust and cutcom registers
    ASC_append_tool_number

    ASC_append_tool_length_adjust_register

    ASC_append_cutcom_register

#  Holding system and description for OD and ID Threading
    if { $asc_lib_subtype == 31 || $asc_lib_subtype == 32 } \
    {
        ASC_append_holding_system
    }

#  Thread form, description and pitch for OD and ID
    if { $asc_lib_subtype == 31 || $asc_lib_subtype == 32 } \
    {
        set asc_lookup_alias "ThreadShapeTurn"
        ASC_find_template_alias
        if {$asc_alias_index > -1 } \
        {
            set option_id "$dbc_template_attributes($asc_alias_index)"
            DBC_ask_option_value "ThreadShapeTurn" $option_id
            append new_tool_record " | $dbc_template_attributes($asc_alias_index)"
            append new_tool_record " | $dbc_option_value"
        } else \
        {
            append new_tool_record " | |"
        }

#  Get pitch
        UGLIB_calc_pitch $dbc_tool_left_angle $dbc_tool_right_angle \
            $dbc_tool_tip_offset $dbc_tool_insert_width $dbc_tool_nose_width \
            $dbc_tool_insert_length tmp_pitch
        set tmp [format " | %.5f" $tmp_pitch]
        append new_tool_record $tmp
    }

#  orientation angle
    ASC_append_turning_tool_orientation

#  Nose Width for Trapezoidal, nose radius for all others
    if { $asc_lib_subtype == 97 } {
        ASC_append_turning_nose_width
    } else {
        ASC_append_turning_nose_radius
    }

#  For Trapeziodal and Standard, Left and right side angles,
#    Tool tip offset, insert width and length
    if { $asc_lib_subtype == 96 || $asc_lib_subtype == 97} \
    {
        ASC_append_turning_left_and_right_angle

        ASC_append_turning_tip_offset

        ASC_append_turning_insert_width 1.0

        ASC_append_turning_insert_length
    }

#  For OD and ID Threading, Cut Edge Length
    if { $asc_lib_subtype == 31 || $asc_lib_subtype == 32} \
    {
        ASC_append_turning_cut_edge_length
    }

#  Thickness, max depth
    ASC_append_turning_tool_thickness

    ASC_append_max_depth

#  X and Y Offsets
    ASC_append_turning_x_y_offset

#  Tracking point and insert position
    ASC_append_turning_append_tracking_point

    ASC_append_turning_insert_position

    set asc_lookup_alias "MinBoringDia"
    ASC_find_template_alias
    
    ASC_append_min_boring_dia true

    set asc_lookup_alias "MaxToolReach"
    ASC_find_template_alias
    ASC_append_max_toolreach true

    ASC_append_x_and_y_mount

    ASC_append_holder_angle

#  Rigidity
    ASC_append_rigidity

#  Append trackpoint libref
    ASC_append_tp_libref

#  Append index notch and turret rotation angle
    ASC_append_index_notch_and_turret_rot_angle

}
#
#
#  Mill Form tool
proc ASC_build_mill_form { } \
{
    global dbc_libref
    global new_tool_record


#  Initialize the record with its libref
    set new_tool_record "DATA | $dbc_libref"

#  Add the library type and subtype fields
    append new_tool_record " | 02 | 51"

#  Now the description
    ASC_append_tool_description

#  Tool material and material description
    ASC_append_material_and_description

#  Tool number, adjust and cutcom registers
    ASC_append_tool_number

    ASC_append_tool_length_adjust_register

    ASC_append_cutcom_register

#  Holding system and description
    ASC_append_holding_system

#  number of flutes and Z offset
    ASC_append_flutes_number

    ASC_append_tool_zoffset

#  direction
    ASC_append_tool_direction

    #flute length
    ASC_append_tool_flute_length

    ASC_append_coolant_through

#  Holder offset, rigidity and holder library reference
    ASC_append_holder_offset

    ASC_append_z_mount

    ASC_append_rigidity

    ASC_append_shank_record

    ASC_append_milling_machining_parameters

    ASC_append_holder_libref

#  Append trackpoint libref
    ASC_append_tp_libref
}
#
#
#  Step Drill
proc ASC_build_step_drill { } \
{
    global dbc_libref
    global dbc_tool_tip_diameter
    global dbc_tool_point_angle
    global dbc_tool_tip_length
    global new_tool_record


#  Initialize the record with its libref
    set new_tool_record "DATA | $dbc_libref"

#  Add the library type and subtype fields
    append new_tool_record " | 03 | 04"

#  Add the NX type and subtype fields
    append new_tool_record " | 02 | 12"

#  Now the description
    ASC_append_tool_description

#  Tool material and material description
    ASC_append_material_and_description

#  Tool number, adjust and cutcom registers
    ASC_append_tool_number

    ASC_append_tool_length_adjust_register

    ASC_append_cutcom_register

#  Holding system and description
   ASC_append_holding_system

#  Diameter, point angle, tip length and corner radius
    ASC_append_tool_tip_diameter

    ASC_append_point_angle

    ASC_append_point_length

    if {[info exists dbc_tool_tip_length]} \
    {
##  Library value of tip length does not contain the tip height, which
##  is included in the NX value, so we need to subract it.
        UGLIB_calc_chamfer_step 0.0 $dbc_tool_tip_diameter \
            $dbc_tool_point_angle tip_height
        set tiplen [expr $dbc_tool_tip_length - $tip_height]
        set tmp [format " | %.5f" $tiplen]
        append new_tool_record $tmp
    } else \
    {
        append new_tool_record " |"
    }

    ASC_append_corner1_radius

#  Flute length, number of flutes and tool height
    ASC_append_tool_flute_length

    ASC_append_flutes_number

    ASC_append_tool_length

#  Shoulder Distance, Z-offset and direction
    ASC_append_shoulder_distance

    ASC_append_tool_zoffset

    ASC_append_tool_direction

    ASC_append_coolant_through

#  Holder offset, rigidity and holder library reference
    ASC_append_holder_offset

    ASC_append_z_mount

    ASC_append_rigidity

    ASC_append_shank_record

    ASC_append_holder_libref

#  Append trackpoint libref
    ASC_append_tp_libref
}
#
#
#  Turn Form
proc ASC_build_turn_form { } \
{
    global dbc_libref
    global new_tool_record


#  Initialize the record with its libref
    set new_tool_record "DATA | $dbc_libref"

#  Add the library type and subtype fields
    append new_tool_record " | 01 | 51"

#  Now the description
    ASC_append_tool_description

#  Tool material and material description
    ASC_append_material_and_description

#  Tool number
    ASC_append_tool_number

#  orientation angle, thickness and initial edge angle
    ASC_append_turning_tool_orientation

    ASC_append_turning_tool_thickness

    ASC_append_turn_form_insert_angle

#  Initial edge length, insert position
    ASC_append_turning_cut_edge_length

    ASC_append_turning_insert_position

#  Max depth, Min facing diameter and Max facing diameter
    ASC_append_max_depth

    ASC_append_max_and_min_facing_diameter

#  Min boring diameter and max toolreach
    ASC_append_min_boring_dia false

    ASC_append_max_toolreach false

    ASC_append_x_and_y_mount

    ASC_append_holder_angle

#  rigidity and trackpoint libref
    ASC_append_rigidity

    ASC_append_tp_libref

#  Append index notch and turret rotation angle
    ASC_append_index_notch_and_turret_rot_angle

}

#
#  Tool build utilities
#
proc ASC_find_template_alias { } \
{
    global dbc_template_aliases
    global dbc_att_count
    global asc_lookup_alias
    global asc_alias_index

    set asc_alias_index -1

    if { [info exists dbc_att_count ] } \
    {
        set local_alias [string trimright $asc_lookup_alias]
        for { set inx 0 } {$inx < $dbc_att_count } { incr inx } \
        {
            set test_alias [string trimright $dbc_template_aliases($inx)]
            set cmp [string compare $local_alias $test_alias ]
            if { $cmp == 0 } \
            {
                set asc_alias_index $inx
            }
        }
    }
}
#
#
#  Solid Generic
proc ASC_build_solid_generic { } \
{
    global dbc_libref
    global new_tool_record


#  Initialize the record with its libref
    set new_tool_record "DATA | $dbc_libref"

#  Add the library type and subtype fields
    append new_tool_record " | 04 | 01"

#  Now the description
    ASC_append_tool_description

#  Tool material and material description
    ASC_append_material_and_description

#  Tool number
    ASC_append_tool_number

#  Holding system and description
    ASC_append_holding_system

#  Rigidity
    ASC_append_rigidity
}
#
#
#  Wire
proc ASC_build_wire { } \
{
    global dbc_libref
    global new_tool_record

#  Initialize the record with its libref
    set new_tool_record "DATA | $dbc_libref"

#  Add the library type and subtype fields
    append new_tool_record " | 06 | 01| 06| 00"

#  The description
    ASC_append_tool_description

#  Diameter
    ASC_append_tool_diameter

#  Tool number, adjust and cutcom registers
    ASC_append_tool_number

    ASC_append_tool_length_adjust_register

    ASC_append_cutcom_register

#  Tool material and material description
    ASC_append_material_and_description

#  Holding system and description
    ASC_append_holding_system

    ASC_append_holder_libref

}
#
#
#  Solid Probe
proc ASC_build_solid_probe { } \
{
    global dbc_libref
    global new_tool_record


#  Initialize the record with its libref
    set new_tool_record "DATA | $dbc_libref"

#  Add the library type and subtype fields
    append new_tool_record " | 04 | 02"

#  Now the description
    ASC_append_tool_description

#  Tool material and material description
    ASC_append_material_and_description

#  Tool number
    ASC_append_tool_number

#  Holding system and description
    ASC_append_holding_system

#  Rigidity
   ASC_append_rigidity
}

#
#
#  Hardening Laser
proc ASC_build_hardening_laser { } \
{
    global dbc_libref
    global new_tool_record


#  Initialize the record with its libref
    set new_tool_record "DATA | $dbc_libref"

#  Add the library type and subtype fields
    append new_tool_record " | 05 | 03 | 11 | 02"

#  Now the description
    ASC_append_tool_description

#  Tool number
    ASC_append_tool_number

    ASC_append_tool_length_adjust_register

    ASC_append_tool_length

    ASC_append_tool_flute_length
    
    ASC_append_tool_diameter
    
#  Holding system and description
    ASC_append_holding_system
}

#
#
#  Stamping tool
proc ASC_build_stamping { } \
{
    global dbc_libref
    global new_tool_record


#  Initialize the record with its libref
    set new_tool_record "DATA | $dbc_libref"

#  Add the library type and subtype fields
    append new_tool_record " | 04 | 04 | 11 | 03"

#  Now the description
    ASC_append_tool_description

#  Tool number
    ASC_append_tool_number
}

#
#
#  Multitool
proc ASC_build_multitool { } \
{
    global dbc_libref
    global new_tool_record

    global asc_lib_subtype
    global uglib_tl_type

#  Initialize the record with its libref
    set new_tool_record "DATA | $dbc_libref"

#  Add the library type and subtype fields
    append new_tool_record " | $uglib_tl_type(MULTITOOL) | $asc_lib_subtype"

#  Now the description
    ASC_append_multitool_description

#  Holding system and description
    ASC_append_holding_system

}





#
#
#  Soft Laser
proc ASC_build_soft_laser { } \
{
    global dbc_libref
    global asc_lib_subtype
    global asc_nx_subtype
    global new_tool_record


#  Initialize the record with its libref
    set new_tool_record "DATA | $dbc_libref"

#  Add the library type and subtype fields and the NX mapping
    append new_tool_record " | 05 | $asc_lib_subtype | 12 | $asc_nx_subtype"

#  Now the description
    ASC_append_tool_description

#  Nozzle Diameter
    ASC_append_nozzle_diameter

#  Nozzle Length
    ASC_append_nozzle_length

#  Nozzle Tip Diameter
    ASC_append_nozzle_tip_diameter

#  Nozzle Taper Length
    ASC_append_nozzle_taper_length

    if {$asc_lib_subtype == 2 } \
    {
#       For Deposition laser
#       Focal Distance
		ASC_append_focal_distance

#       Focal Diameter
		ASC_append_focal_diameter
	} else {
#       For Standard Laser
#       The focal distance is the tool length
		ASC_append_tool_length
#       The focal diameter is the tool diameter
		ASC_append_tool_diameter
	}
#  Minimum Power
    ASC_append_minimum_power

#  Maximum Power
    ASC_append_maximum_power

#  Holding system and description
    ASC_append_holding_system

#  Holder offset
#    ASC_append_holder_offset

#  Add Deposition laser fields
    if { $asc_lib_subtype == 2 } \
    {
        ASC_append_standoff_distance
        ASC_append_working_diameter
        ASC_append_working_range
    }
    ASC_append_holder_libref
	
#  Add Tool number, adjust and cutcom registers fields
    ASC_append_tool_number

    ASC_append_tool_length_adjust_register

    ASC_append_cutcom_register
}

proc ASC_append_shank_record {} {
    global new_tool_record
    global dbc_tool_use_tapered_shank
    global dbc_tool_tapered_shank_diameter
    global dbc_tool_tapered_shank_length
    global dbc_tool_tapered_shank_taper_length

    if {[info exists dbc_tool_use_tapered_shank] && \
        $dbc_tool_use_tapered_shank == "Yes"} {
        set local_record [format " | %.5f" $dbc_tool_tapered_shank_diameter]
        append local_record [format " | %.5f" $dbc_tool_tapered_shank_length]
        append local_record [format " | %.5f" $dbc_tool_tapered_shank_taper_length]

        append new_tool_record $local_record
    } else {
        append new_tool_record " |  |  |  "
    }
}

proc ASC_append_holding_system {} {
    global asc_alias_index
    global asc_lookup_alias
    global dbc_option_value
    global dbc_template_attributes
    global dbc_tool_holding_system
    global new_tool_record

    set asc_lookup_alias "Holder"
    ASC_find_template_alias
    if {$asc_alias_index > -1 } { 
        set option_id "$dbc_template_attributes($asc_alias_index)"
        DBC_ask_option_value "Holder" $option_id
        if  {[string trim $option_id]  ==  "<none>"} {
              set option_id " "
              set dbc_option_value " "
        }

        append new_tool_record " | $option_id"
        append new_tool_record " | $dbc_option_value"
    } elseif {[info exists dbc_tool_holding_system]} {
        DBC_ask_option_value "Holder" $dbc_tool_holding_system
        append new_tool_record " | $dbc_tool_holding_system"
        append new_tool_record " | $dbc_option_value"
    } else {
        append new_tool_record " | |"
    }
}

proc ASC_append_coolant_through {} {
    global dbc_tool_coolant_through
    global new_tool_record

    set value 0
    if {[info exists dbc_tool_coolant_through] && \
        $dbc_tool_coolant_through == "Yes"} {
        set value 1
    }

    append new_tool_record " | $value"
}

proc ASC_append_z_mount {} {
    global new_tool_record
    global dbc_tool_zmount

    if [info exists dbc_tool_zmount] {
        append new_tool_record [format " | %.5f" $dbc_tool_zmount]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_x_and_y_mount {} {
    global new_tool_record
    global dbc_tool_xmount
    global dbc_tool_ymount

    if [info exists dbc_tool_xmount] {
        append new_tool_record [format " | %.5f" $dbc_tool_xmount]
    } else {
        append new_tool_record " |"
    }

    if [info exists dbc_tool_ymount] {
        append new_tool_record [format " | %.5f" $dbc_tool_ymount]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_max_toolreach {check_alias_index} {
    global dbc_tool_max_toolreach
    global dbc_tool_max_toolreach_toggle
    global new_tool_record
    global dbc_template_attributes
    global asc_alias_index

    if {[info exists dbc_tool_max_toolreach_toggle] && $dbc_tool_max_toolreach_toggle == 1} {
        if {[info exists dbc_tool_max_toolreach]} \
        {
            set tmp [format " | %.5f" $dbc_tool_max_toolreach]
            append new_tool_record $tmp
        } elseif {$check_alias_index == "true" && $asc_alias_index > -1} {
            append new_tool_record " | $dbc_template_attributes($asc_alias_index)"
        } else {
            append new_tool_record " | "
        }
    } else {
        append new_tool_record " | "
    }
}

proc ASC_append_min_boring_dia {check_alias_index} {
    global dbc_tool_min_boring_diameter
    global dbc_tool_min_boring_diameter_toggle
    global new_tool_record
    global dbc_template_attributes
    global asc_alias_index

    if {[info exists dbc_tool_min_boring_diameter_toggle] && $dbc_tool_min_boring_diameter_toggle == 1} {
        if {[info exists dbc_tool_min_boring_diameter]} \
        {
            set tmp [format " | %.5f" $dbc_tool_min_boring_diameter]
            append new_tool_record $tmp
        } elseif {$check_alias_index == "true" && $asc_alias_index > -1} {
            append new_tool_record " | $dbc_template_attributes($asc_alias_index)"
        } else {
            append new_tool_record " | "
        }
    } else {
        append new_tool_record " | "
    }

}

proc ASC_append_max_depth {} {
    global dbc_tool_max_depth
    global dbc_tool_max_depth_toggle
    global new_tool_record

    if {[info exists dbc_tool_max_depth_toggle] && $dbc_tool_max_depth_toggle == 1} {
        if {[info exists dbc_tool_max_depth]} \
        {
            set tmp [format " | %.5f" $dbc_tool_max_depth]
            append new_tool_record $tmp
        } else \
        {
            append new_tool_record " | "
        }
    } else {
        append new_tool_record " | "
    }

}

proc ASC_append_max_and_min_facing_diameter {} {
    global new_tool_record
    global dbc_tool_min_facing_diameter
    global dbc_tool_min_facing_diameter_t
    global dbc_tool_max_facing_diameter
    global dbc_tool_max_facing_diameter_t

    if {[info exists dbc_tool_min_facing_diameter_t] && $dbc_tool_min_facing_diameter_t == 1} {
        if {[info exists dbc_tool_min_facing_diameter]} {
            set tmp [format " | %.5f" $dbc_tool_min_facing_diameter]
            append new_tool_record $tmp
        } else {
            append new_tool_record " | "
        }
    } else {
        append new_tool_record " | "
    }


    if {[info exists dbc_tool_max_facing_diameter_t] && $dbc_tool_max_facing_diameter_t == 1} {
        if {[info exists dbc_tool_max_facing_diameter]} {
            set tmp [format " | %.5f" $dbc_tool_max_facing_diameter]
            append new_tool_record $tmp
        } else {
            append new_tool_record " | "
        }
    } else {
        append new_tool_record " | "
    }
}

proc ASC_append_rigidity {} {
    global new_tool_record
    global dbc_cutter_rigidity

    if {[info exists dbc_cutter_rigidity]} {
        set tmp [format " | %.5f" $dbc_cutter_rigidity]
        append new_tool_record $tmp
    } else {
        append new_tool_record " | 1.0"
    }
}

proc ASC_append_tp_libref {} {
    global new_tool_record
    global dbc_cutter_trackpoint_libref

    if {[info exists dbc_cutter_trackpoint_libref]} {
        append new_tool_record " | $dbc_cutter_trackpoint_libref"
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_holder_libref {} {
    global new_tool_record
    global dbc_cutter_holder_libref

    if {[info exists dbc_cutter_holder_libref]} {
        append new_tool_record " | $dbc_cutter_holder_libref"
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_material_and_description {} {
    global new_tool_record
    global dbc_tool_material_libref
    global dbc_tool_material_description

    if {[info exists dbc_tool_material_libref]} {
        append new_tool_record " | $dbc_tool_material_libref | $dbc_tool_material_description"
    } else {
        append new_tool_record " | |"
    }
}

proc ASC_append_holder_offset {} {
    global new_tool_record
    global dbc_tool_holder_offset

    if {[info exists dbc_tool_holder_offset]} {
        append new_tool_record [format " | %.5f" $dbc_tool_holder_offset]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_tool_direction {} {
    global new_tool_record
    global dbc_tool_direction

    if {[info exists dbc_tool_direction]} {
        if { $dbc_tool_direction == 1} {
            append new_tool_record " | 3"
        } elseif { $dbc_tool_direction == 2} {
            append new_tool_record " | 4"
        } else {
            append new_tool_record " |"
        }
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_tool_flute_length {} {
    global new_tool_record
    global dbc_tool_flute_length

    if {[info exists dbc_tool_flute_length]} {
        append new_tool_record [format " | %.5f" $dbc_tool_flute_length]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_tool_diameter {} {
    global new_tool_record
    global dbc_tool_diameter

    if {[info exists dbc_tool_diameter]} {
        append new_tool_record [format " | %.5f" $dbc_tool_diameter]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_tool_length {} {
    global new_tool_record
    global dbc_tool_length

    if {[info exists dbc_tool_length]} {
        append new_tool_record [format " | %.5f" $dbc_tool_length]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_tool_zoffset {} {
    global new_tool_record
    global dbc_tool_z_offset

    if {[info exists dbc_tool_z_offset]} {
        append new_tool_record [format " | %.5f" $dbc_tool_z_offset]
    } else { 
        append new_tool_record " |"
    }
}

proc ASC_append_flutes_number {} {
    global new_tool_record
    global dbc_tool_flutes_number

    if {[info exists dbc_tool_flutes_number]} {
        append new_tool_record " | $dbc_tool_flutes_number"
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_tool_number {} {
    global new_tool_record
    global dbc_tool_number

    if {[info exists dbc_tool_number]} {
        append new_tool_record " | $dbc_tool_number"
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_tool_length_adjust_register {} {
    global new_tool_record
    global dbc_tool_length_adjust_register

    if {[info exists dbc_tool_length_adjust_register]} {
        append new_tool_record " | $dbc_tool_length_adjust_register"
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_cutcom_register {} {
    global new_tool_record
    global dbc_tool_cutcom_register

    if {[info exists dbc_tool_cutcom_register]} {
        append new_tool_record " | $dbc_tool_cutcom_register"
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_tool_tip_diameter {} {
    global new_tool_record
    global dbc_tool_tip_diameter

    if {[info exists dbc_tool_tip_diameter]} {
        append new_tool_record [format " | %.5f" $dbc_tool_tip_diameter]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_tool_tip_length {} {
    global new_tool_record
    global dbc_tool_tip_length

    if {[info exists dbc_tool_tip_length]} {
        append new_tool_record [format " | %.5f" $dbc_tool_tip_length]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_tool_description {} {
    global new_tool_record
    global dbc_cutter_description

    if {[info exists dbc_cutter_description]} {
        append new_tool_record " | $dbc_cutter_description"
    } else {
        append new_tool_record " |"
    }
}


proc ASC_append_multitool_description {} {
    global new_tool_record
    global dbc_carrier_description

    if {[info exists dbc_carrier_description]} {
        append new_tool_record " | $dbc_carrier_description"
    } else {
        append new_tool_record " |"
    }
}




proc ASC_append_corner1_radius {} {
    global new_tool_record
    global dbc_tool_corner1_radius

    if {[info exists dbc_tool_corner1_radius]} {
        append new_tool_record [format " | %.5f" $dbc_tool_corner1_radius]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_neck_diameter {} {
    global new_tool_record
    global dbc_tool_shank_diameter

    if {[info exists dbc_tool_shank_diameter]} {
        append new_tool_record [format " | %.5f" $dbc_tool_shank_diameter]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_tip_angle {be_negated} {
    global new_tool_record
    global dbc_tool_tip_angle

    if {[info exists dbc_tool_tip_angle]} {
        set angle $dbc_tool_tip_angle
        if {$be_negated == "true"} {
            set angle [expr $angle * (-1)]
        }
        set tmp_angle [UGLIB_convert_rad_to_deg $angle]
        append new_tool_record [format " | %.5f" $tmp_angle]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_taper_angle {} {
    global new_tool_record
    global dbc_tool_taper_angle

    if {[info exists dbc_tool_taper_angle]} {
        set tmp_angle [UGLIB_convert_rad_to_deg $dbc_tool_taper_angle]
        append new_tool_record [format " | %.5f" $tmp_angle]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_relief_diameter {} {
    global new_tool_record
    global dbc_relief_diameter

    if {[info exists dbc_relief_diameter]} {
        append new_tool_record [format " | %.5f" $dbc_relief_diameter]
    } else {
        append new_tool_record " |"
    }    
}

proc ASC_append_tool_helix_angle {} {
    global new_tool_record
    global dbc_tool_helix_angle

    if {[info exists dbc_tool_helix_angle]} {
        set angleInDeg [UGLIB_convert_rad_to_deg $dbc_tool_helix_angle]
        append new_tool_record [format " | %.5f" $angleInDeg]
    } else {
        append new_tool_record " |"
    }    
}

proc ASC_append_taper_diameter_distance {} {
    global new_tool_record
    global dbc_tool_taper_diameter_distance

    if {[info exists dbc_tool_taper_diameter_distance]} {
        append new_tool_record [format " | %.5f" $dbc_tool_taper_diameter_distance]
    } else {
        append new_tool_record " |"
    }    
}

proc ASC_append_side_angle {} {
    global new_tool_record
    global dbc_tool_side_angle

    set local_record " |"
    
    if {[info exists dbc_tool_side_angle]} {
        set tmp_angle [UGLIB_convert_rad_to_deg $dbc_tool_side_angle]
        set local_record [format " | %.5f" $tmp_angle]
    }

    append new_tool_record $local_record

    return $local_record
}

proc ASC_append_lower_and_upper_corner_radius {} {
    global new_tool_record
    global dbc_tool_lower_corner_radius
    global dbc_tool_upper_corner_radius

    if {[info exists dbc_tool_lower_corner_radius]} {
        set tmp [format " | %.5f" $dbc_tool_lower_corner_radius]
        append new_tool_record $tmp
    } else {
        append new_tool_record " |"
    }

    if {[info exists dbc_tool_upper_corner_radius]} {
        set tmp [format " | %.5f" $dbc_tool_upper_corner_radius]
        append new_tool_record $tmp
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_point_angle {} {
    global new_tool_record
    global dbc_tool_point_angle

    if {[info exists dbc_tool_point_angle]} {
        set tmp_angle [UGLIB_convert_rad_to_deg $dbc_tool_point_angle]
        append new_tool_record [format " | %.5f" $tmp_angle]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_point_length {} {
    global new_tool_record
    global dbc_tool_point_length

    if {[info exists dbc_tool_point_length]} {
        append new_tool_record [format " | %.5f" $dbc_tool_point_length]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_included_angle {} {
    global new_tool_record
    global dbc_tool_included_angle

    if {[info exists dbc_tool_included_angle]} {
        set tmp_angle [UGLIB_convert_rad_to_deg $dbc_tool_included_angle]
        append new_tool_record [format " | %.5f" $tmp_angle]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_pilot_diameter_and_length {} {
    global new_tool_record
    global dbc_tool_pilot_diameter
    global dbc_tool_pilot_length

    if {[info exists dbc_tool_pilot_diameter]} {
        append new_tool_record [format " | %.5f" $dbc_tool_pilot_diameter]
    } else {
        append new_tool_record " |"
    }

    if {[info exists dbc_tool_pilot_length]} {
        append new_tool_record [format " | %.5f" $dbc_tool_pilot_length]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_turning_tool_orientation {} {
    global new_tool_record
    global dbc_tool_orientation
    
    if {[info exists dbc_tool_orientation]} {
        set tmp_angle [UGLIB_convert_rad_to_deg $dbc_tool_orientation]
        append new_tool_record [format " | %.5f" $tmp_angle]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_turning_tool_thickness {} {
    global new_tool_record
    global dbc_tool_thickness

    if {[info exists dbc_tool_thickness]} {
        append new_tool_record [format " | %.5f" $dbc_tool_thickness]
    } else {
        append new_tool_record " |"
    }    
}

proc ASC_append_turning_insert_position {} {
    global new_tool_record
    global dbc_tool_insert_position

    if {[info exists dbc_tool_insert_position]} {
        append new_tool_record " | $dbc_tool_insert_position"
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_turning_append_tracking_point {} {
    global new_tool_record
    global dbc_tool_tracking_point

    if {[info exists dbc_tool_tracking_point]} {
        append new_tool_record " | $dbc_tool_tracking_point"
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_turning_x_y_offset {} {
    global new_tool_record
    global dbc_tool_x_offset
    global dbc_tool_y_offset

    if {[info exists dbc_tool_x_offset]} {
        append new_tool_record [format " | %.5f" $dbc_tool_x_offset]
    } else {
        append new_tool_record " |"
    }

    if {[info exists dbc_tool_y_offset]} {
        append new_tool_record [format " | %.5f" $dbc_tool_y_offset]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_turning_relief_angle {} {
    global new_tool_record
    global dbc_tool_relief_angle

    if {[info exists dbc_tool_relief_angle]} {
        set tmp_angle [UGLIB_convert_rad_to_deg $dbc_tool_relief_angle]
        append new_tool_record [format " | %.5f" $tmp_angle]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_turning_insert_width {factor} {
    global new_tool_record
    global dbc_tool_insert_width

    if {[info exists dbc_tool_insert_width]} {
        set tmp [format " | %.5f" [expr $factor * $dbc_tool_insert_width]]
        append new_tool_record $tmp
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_turning_insert_length {} {
    global new_tool_record
    global dbc_tool_insert_length

    if {[info exists dbc_tool_insert_length]} {
        set tmp [format " | %.5f" $dbc_tool_insert_length]
        append new_tool_record $tmp
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_turning_nose_width {} {
    global new_tool_record
    global dbc_tool_nose_width

    if {[info exists dbc_tool_nose_width]} {
        set tmp [format " | %.5f" $dbc_tool_nose_width]
        append new_tool_record $tmp
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_turning_nose_radius {} {
    global new_tool_record
    global dbc_tool_nose_radius

    if {[info exists dbc_tool_nose_radius]} {
        set tmp [format " | %.5f" $dbc_tool_nose_radius]
        append new_tool_record $tmp
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_turning_left_and_right_angle {} {
    global new_tool_record
    global dbc_tool_left_angle
    global dbc_tool_right_angle

    if {[info exists dbc_tool_left_angle]} {
        set tmp_angle [UGLIB_convert_rad_to_deg $dbc_tool_left_angle]
        set tmp [format " | %.5f" $tmp_angle]
        append new_tool_record $tmp
    } else {
        append new_tool_record " |"
    }

    if {[info exists dbc_tool_right_angle]} {
        set tmp_angle [UGLIB_convert_rad_to_deg $dbc_tool_right_angle]
        set tmp [format " | %.5f" $tmp_angle]
        append new_tool_record $tmp
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_turning_tip_offset {} {
    global new_tool_record
    global dbc_tool_tip_offset

    if {[info exists dbc_tool_tip_offset]} {
        set tmp [format " | %.5f" $dbc_tool_tip_offset]
        append new_tool_record $tmp
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_turning_cut_edge_length {} {
    global new_tool_record
    global dbc_tool_cut_edge_length

    if {[info exists dbc_tool_cut_edge_length]} {
        set tmp [format " | %.5f" $dbc_tool_cut_edge_length]
        append new_tool_record $tmp
    } else {
        append new_tool_record " | "
    }
}

proc ASC_append_shoulder_distance {} {
    global new_tool_record
    global dbc_tool_shoulder_distance

    if {[info exists dbc_tool_shoulder_distance]} {
        set tmp [format " | %.5f" $dbc_tool_shoulder_distance]
        append new_tool_record $tmp
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_turn_form_insert_angle {} {
    global new_tool_record
    global dbc_tool_insert_angle

    if {[info exists dbc_tool_insert_angle]} {
        set tmp_angle [UGLIB_convert_rad_to_deg $dbc_tool_insert_angle]
        set tmp [format " | %.5f" $tmp_angle]
        append new_tool_record $tmp
    } else {
        append new_tool_record " | "
    }
}

proc ASC_append_turning_left_x_offset {} {
    global new_tool_record
    global dbc_tool_left_x_offset

    if {[info exists dbc_tool_left_x_offset]} {
        set tmp [format " | %.5f" $dbc_tool_left_x_offset]
        append new_tool_record $tmp
    } else {
        append new_tool_record " | "
    }
}

proc ASC_append_turning_left_y_offset {} {
    global new_tool_record
    global dbc_tool_left_y_offset
    
    if {[info exists dbc_tool_left_y_offset]} {
        set tmp [format " | %.5f" $dbc_tool_left_y_offset]
        append new_tool_record $tmp
    } else {
        append new_tool_record " | "
    }
}

proc ASC_append_turning_right_x_offset {} {
    global new_tool_record
    global dbc_tool_right_x_offset

    if {[info exists dbc_tool_right_x_offset]} {
        set tmp [format " | %.5f" $dbc_tool_right_x_offset]
        append new_tool_record $tmp
    } else {
        append new_tool_record " | "
    }
}

proc ASC_append_turning_right_y_offset {} {
    global new_tool_record
    global dbc_tool_right_y_offset

    if {[info exists dbc_tool_right_y_offset]} {
        set tmp [format " | %.5f" $dbc_tool_right_y_offset]
        append new_tool_record $tmp
    } else {
        append new_tool_record " | "
    }
}

proc ASC_append_milling_machining_parameters {} {
    global new_tool_record
    global dbc_helical_ramp_angle
    global dbc_engage_auto_min_ramp_length
    global dbc_engage_auto_min_ramp_length_source
    global dbc_circle_diameter
    global dbc_circle_diameter_source
    global dbc_max_cut_width_distance
    global dbc_max_cut_width_distance_source

    set percent_string "%T"

    #ramp angle
    if {[info exists dbc_helical_ramp_angle]} {
        append new_tool_record [format  " | %.5f" $dbc_helical_ramp_angle]
    } else {
        append new_tool_record " |"
    }
    
    #helical diameter
    if {[info exists dbc_circle_diameter]} {
        set temp [format " | %.5f" $dbc_circle_diameter]
        if [info exists dbc_circle_diameter_source] {
           append temp $percent_string
        }
        append new_tool_record $temp
    } else {
        append new_tool_record " |"
    }

    #min ramp length
    if {[info exists dbc_engage_auto_min_ramp_length]} {
        set temp [format " | %.5f" $dbc_engage_auto_min_ramp_length]
        if [info exists dbc_engage_auto_min_ramp_length_source] {
           append temp $percent_string
        }
        append new_tool_record $temp
    } else {
        append new_tool_record " |"
    }

    #max cut width
    if {[info exists dbc_max_cut_width_distance]} {
        set temp [format " | %.5f" $dbc_max_cut_width_distance]
        if [info exists dbc_max_cut_width_distance_source] {
           append temp $percent_string
        }
        append new_tool_record $temp
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_grooving_left_and_right_corner_radius {} {
    global new_tool_record
    global dbc_tool_left_corner_radius
    global dbc_tool_right_corner_radius

    if {[info exists dbc_tool_left_corner_radius]} {
        set tmp [format " | %.5f" $dbc_tool_left_corner_radius]
        append new_tool_record $tmp
    } else {
        append new_tool_record " |"
    }

    if {[info exists dbc_tool_right_corner_radius]} {
        set tmp [format " | %.5f" $dbc_tool_right_corner_radius]
        append new_tool_record $tmp
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_grooving_tool_radius {} {
    global new_tool_record
    global dbc_tool_radius

    if {[info exists dbc_tool_radius]}  {
        set tmp [format " | %.5f" $dbc_tool_radius]
        append new_tool_record $tmp
    } else {
        append new_tool_record " | "
    }
}

proc ASC_append_tool_pitch {} {
    global new_tool_record
    global dbc_tool_pitch

    if {[info exists dbc_tool_pitch]} {
        set tmp [format " | %.5f" $dbc_tool_pitch]
        append new_tool_record $tmp
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_tracking_point {} {
    global new_tool_record
    global dbc_tool_left_tracking_point
    global dbc_tool_right_tracking_point
    global dbc_tool_preset_cutter

    if {[info exists dbc_tool_left_tracking_point] && \
        [info exists dbc_tool_right_tracking_point] && \
        [info exists dbc_tool_preset_cutter]} {
        set tmp_tracking [UGLIB_compute_tracking_point $dbc_tool_preset_cutter \
            $dbc_tool_left_tracking_point $dbc_tool_right_tracking_point]
        append new_tool_record " | $tmp_tracking"
    } else {
        append new_tool_record " | "
    }
}

proc ASC_append_value_without_right_zeros {input_value} {
    global new_tool_record

    set value [format "%.10f" [string trim $input_value]]
    set tmp [string trimright $value "0"]
    append new_tool_record " | $tmp"
}

proc ASC_append_holder_angle {} {
    global new_tool_record
    global dbc_tool_holder_orient_angle

    if {[info exists dbc_tool_holder_orient_angle]} {
        set tmp_angle [UGLIB_convert_rad_to_deg $dbc_tool_holder_orient_angle]
        append new_tool_record [format " | %.5f" $tmp_angle]
    } else {
        append new_tool_record " |"
    }
}


proc ASC_append_index_notch_and_turret_rot_angle {} {
    global new_tool_record
    global dbc_tool_index_notch
    global dbc_tool_turret_rotation

    if {[info exists dbc_tool_index_notch]} {
        set tmp_angle [UGLIB_convert_rad_to_deg $dbc_tool_index_notch]
        append new_tool_record [format " | %.5f" $dbc_tool_index_notch]
    } else {
        append new_tool_record " |"
    }

    if {[info exists dbc_tool_turret_rotation]} {
        set tmp_angle [UGLIB_convert_rad_to_deg $dbc_tool_turret_rotation]
        append new_tool_record [format " | %.5f" $dbc_tool_turret_rotation]
    } else {
        append new_tool_record " |"
    }

}


proc ASC_append_nozzle_diameter {} {
    global new_tool_record
    global dbc_tool_tapered_shank_diameter
    if {[info exists dbc_tool_tapered_shank_diameter]} {
        append new_tool_record [format " | %.5f" $dbc_tool_tapered_shank_diameter]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_nozzle_length {} {
    global new_tool_record
    global dbc_tool_tapered_shank_length

    if {[info exists dbc_tool_tapered_shank_length]} {
        append new_tool_record [format " | %.5f" $dbc_tool_tapered_shank_length]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_nozzle_tip_diameter {} {
    global new_tool_record
    global dbc_laser_nozzle_tip_diameter

    if {[info exists dbc_laser_nozzle_tip_diameter]} {
        append new_tool_record [format " | %.5f" $dbc_laser_nozzle_tip_diameter]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_nozzle_taper_length {} {
    global new_tool_record
    global dbc_tool_tapered_shank_taper_length

    if {[info exists dbc_tool_tapered_shank_taper_length]} {
        append new_tool_record [format " | %.5f" $dbc_tool_tapered_shank_taper_length]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_focal_distance {} {
    global new_tool_record
    global dbc_laser_focal_distance
    global dbc_tool_length

    if {[info exists dbc_laser_focal_distance]} {
        append new_tool_record [format " | %.5f" $dbc_laser_focal_distance]
    } elseif {[info exists dbc_tool_length]} {
        append new_tool_record [format " | %.5f" $dbc_tool_length]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_focal_diameter {} {
    global new_tool_record
    global dbc_laser_focal_diameter
    global dbc_tool_diameter

    if {[info exists dbc_laser_focal_diameter]} {
        append new_tool_record [format " | %.5f" $dbc_laser_focal_diameter]
    } elseif {[info exists dbc_tool_diameter]} {
        append new_tool_record [format " | %.5f" $dbc_tool_diameter]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_minimum_power {} {
    global new_tool_record
    global dbc_laser_beam_min_power

    if {[info exists dbc_laser_beam_min_power]} {
        append new_tool_record [format " | %.5f" $dbc_laser_beam_min_power]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_maximum_power {} {
    global new_tool_record
    global dbc_laser_beam_max_power

    if {[info exists dbc_laser_beam_max_power]} {
        append new_tool_record [format " | %.5f" $dbc_laser_beam_max_power]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_standoff_distance {} {
    global new_tool_record
    global dbc_tool_length

    if {[info exists dbc_tool_length]} {
        append new_tool_record [format " | %.5f" $dbc_tool_length]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_working_diameter {} {
    global new_tool_record
    global dbc_tool_diameter

    if {[info exists dbc_tool_diameter]} {
        append new_tool_record [format " | %.5f" $dbc_tool_diameter]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_working_range {} {
    global new_tool_record
    global dbc_laser_working_range

    if {[info exists dbc_laser_working_range]} {
        append new_tool_record [format " | %.5f" $dbc_laser_working_range]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_designation {} {
    global new_tool_record
    global dbc_tool_designation

    if {[info exists dbc_tool_designation]} {
        append new_tool_record " | $dbc_tool_designation"
    } else {
        append new_tool_record " |"
    }
}

proc ASC_convert_chamfer_mill_to_face_mill {} {
    global dbc_tool_diameter
    global dbc_tool_chamfer_length
    global dbc_tool_taper_angle
    global dbc_tool_corner1_radius
    global bottom_diameter
    global dbc_tool_flute_length

    #get the bottom diameter
    set tmp [expr $dbc_tool_diameter - 2.0 * tan($dbc_tool_taper_angle) * $dbc_tool_chamfer_length]
    set bottom_diameter [string trimright [format "%.10f" $tmp] "0"]

    #adjust the flute length
    set dbc_tool_flute_length $dbc_tool_chamfer_length
}

proc ASC_append_lower_corner_radius {} {
    global new_tool_record
    global dbc_tool_lower_corner_radius

    if {[info exists dbc_tool_lower_corner_radius]} {
        set tmp [format " | %.5f" $dbc_tool_lower_corner_radius]
        append new_tool_record $tmp
    } else {
        append new_tool_record " |"
    }
}

#
#
# Tangent Barrel Mill 
proc ASC_build_tangent_barrel_mill { } \
{
    global dbc_libref
    global dbc_tool_barrel_radius
    global dbc_tool_barrel_center_y
    global new_tool_record
    global asc_lib_subtype

#  Initialize the record with its libref
    set new_tool_record "DATA | $dbc_libref"

#  Add the library fields
    append new_tool_record " | 02 | 94 | 07 | 01 "

#  Now the description
    ASC_append_tool_description

#  Tool material and material description
    ASC_append_material_and_description

#  Tool number, adjust and cutcom registers
    ASC_append_tool_number

    ASC_append_tool_length_adjust_register

    ASC_append_cutcom_register

#  Holding system and description
    ASC_append_holding_system

#  diameter, number of flutes, length and Z offset
    ASC_append_tool_diameter

    ASC_append_flutes_number

    ASC_append_tool_length

    ASC_append_tool_zoffset

#  direction, flute length, shank diameter
    ASC_append_tool_direction

#   ASC_append_tool_flute_length

    ASC_append_neck_diameter

#  lower corner radius
    ASC_append_lower_corner_radius

#  Barrel radius and Y center
    if {[info exists dbc_tool_barrel_radius]} \
    {
        set tmp [format " | %.5f" $dbc_tool_barrel_radius]
        append new_tool_record $tmp
    } else \
    {
        append new_tool_record " |"
    }

    ASC_append_coolant_through

#  Holder offset and rigidity
    ASC_append_holder_offset

    ASC_append_z_mount

    ASC_append_rigidity

    ASC_append_shank_record

    ASC_append_milling_machining_parameters

    ASC_append_holder_libref

#  Append trackpoint libref
    ASC_append_tp_libref

# Tool helix angle
    ASC_append_tool_helix_angle
}

proc ASC_append_working_angle {} {
    global new_tool_record
    global dbc_barrel_tool_taper_angle

    if {[info exists dbc_barrel_tool_taper_angle]} {
        set tmp_angle [UGLIB_convert_rad_to_deg $dbc_barrel_tool_taper_angle]
        append new_tool_record [format " | %.5f" $tmp_angle]
    } else {
        append new_tool_record " |"
    }
}

#
#
# Taper Barrel Mill 
proc ASC_build_taper_barrel_mill { } \
{
    global dbc_libref
    global dbc_tool_barrel_radius
    global new_tool_record
    global asc_lib_subtype

#  Initialize the record with its libref
    set new_tool_record "DATA | $dbc_libref"

#  Add the library fields
    append new_tool_record " | 02 | 95 | 07 | 02 "

#  Now the description
    ASC_append_tool_description

#  Tool material and material description
    ASC_append_material_and_description

#  Tool number, adjust and cutcom registers
    ASC_append_tool_number

    ASC_append_tool_length_adjust_register

    ASC_append_cutcom_register

#  Holding system and description
    ASC_append_holding_system

#  diameter, number of flutes, length and Z offset
    ASC_append_tool_diameter

    ASC_append_flutes_number

    ASC_append_tool_length

    ASC_append_tool_zoffset

#  direction, neck diameter
    ASC_append_tool_direction
    
    ASC_append_neck_diameter

#  lower and upper corner radius 
    ASC_append_lower_and_upper_corner_radius

#  Barrel radius
    if {[info exists dbc_tool_barrel_radius]} \
    {
        set tmp [format " | %.5f" $dbc_tool_barrel_radius]
        append new_tool_record $tmp
    } else \
    {
        append new_tool_record " |"
    }

#  Working angle
    ASC_append_working_angle

    ASC_append_coolant_through

#  Holder offset and rigidity
    ASC_append_holder_offset

    ASC_append_z_mount

    ASC_append_rigidity

    ASC_append_shank_record

    ASC_append_milling_machining_parameters

    ASC_append_holder_libref

#  Append trackpoint libref
    ASC_append_tp_libref

# Tool helix angle
    ASC_append_tool_helix_angle
}

proc ASC_append_extrusion_diameter {} {
    global new_tool_record
    global dbc_tool_diameter

    if {[info exists dbc_tool_diameter]} {
        append new_tool_record [format " | %.5f" $dbc_tool_diameter]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_nozzle_orifice_diameter {} {
    global new_tool_record
    global dbc_nozzle_orifice_diameter

    if {[info exists dbc_nozzle_orifice_diameter]} {
        append new_tool_record [format " | %.5f" $dbc_nozzle_orifice_diameter]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_min_bead_width {} {
    global new_tool_record
    global dbc_min_bead_width

    if {[info exists dbc_min_bead_width]} {
        append new_tool_record [format " | %.5f" $dbc_min_bead_width]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_max_bead_width {} {
    global new_tool_record
    global dbc_max_bead_width

    if {[info exists dbc_max_bead_width]} {
        append new_tool_record [format " | %.5f" $dbc_max_bead_width]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_min_bead_height {} {
    global new_tool_record
    global dbc_min_bead_height

    if {[info exists dbc_min_bead_height]} {
        append new_tool_record [format " | %.5f" $dbc_min_bead_height]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_max_bead_height {} {
    global new_tool_record
    global dbc_max_bead_height

    if {[info exists dbc_max_bead_height]} {
        append new_tool_record [format " | %.5f" $dbc_max_bead_height]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_min_extrusion_rate {} {
    global new_tool_record
    global dbc_min_extrusion_rate

    if {[info exists dbc_min_extrusion_rate]} {
        append new_tool_record [format " | %.5f" $dbc_min_extrusion_rate]
    } else {
        append new_tool_record " |"
    }
}

proc ASC_append_max_extrusion_rate {} {
    global new_tool_record
    global dbc_max_extrusion_rate

    if {[info exists dbc_max_extrusion_rate]} {
        append new_tool_record [format " | %.5f" $dbc_max_extrusion_rate]
    } else {
        append new_tool_record " |"
    }
}

#
# Fused Deposition
proc ASC_build_fused_deposition {} \
{
    global dbc_libref
    global new_tool_record

    global asc_lib_subtype
    global uglib_tl_type

    #  Initialize the record with its libref
    set new_tool_record "DATA | $dbc_libref"

#  Add the library type and subtype fields
    append new_tool_record " | 09 | 01 | 17 | 0 "

#  Now the description
    ASC_append_tool_description

# Stand off distance
    ASC_append_standoff_distance

# Extrusion Diameter
    ASC_append_extrusion_diameter

#  Nozzle Diameter
    ASC_append_nozzle_diameter

#  Nozzle Length
    ASC_append_nozzle_length

#  Nozzle Tip Diameter
    ASC_append_nozzle_tip_diameter

#  Nozzle Taper Length
    ASC_append_nozzle_taper_length

#  Nozzle  Orifice Diameter
    ASC_append_nozzle_orifice_diameter

#  Minimum Bead Width
    ASC_append_min_bead_width

#  Maximum Bead Width
    ASC_append_max_bead_width

#  Minimum Bead Height
    ASC_append_min_bead_height

#  Maximum Bead height
    ASC_append_max_bead_height

#  Minimum Extrusion Rate
    ASC_append_min_extrusion_rate

#  Minimum Extrusion Rate
    ASC_append_max_extrusion_rate

#  Holding system and description
    ASC_append_holding_system

#  Holding library reference
    ASC_append_holder_libref

#  Tool number, adjust and cutcom registers
    ASC_append_tool_number

    ASC_append_tool_length_adjust_register

    ASC_append_cutcom_register

}
