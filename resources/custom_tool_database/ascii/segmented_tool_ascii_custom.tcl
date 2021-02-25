###############################################################################
# segmented_tool_ascii_custom.tcl - This is the customization file that will be sourced in
# after the segmented_tool_ascii.tcl is sourced in. This file is supplied as a sample and should be
# copied and modified and placed in a different location than the NX installation and the directory
# should be pointed to by the environment variable UGII_CAM_CUSTOM_LIBRARY_TOOL_ASCII_DIR
###############################################################################


# Global variable override
set ::dbc_segment_angle_decimal_place 8

namespace eval CUSTOM \
{
    # The proc in the CUSTOM namespace will be called instead of the system DBC_retrieve to enable
	# user customization
    proc DBC_retrieve {} \
    {
	    # Take custom action before the system/global namespace DBC_retrieve
	
	    #Call to the system/global DBC_retrieve
	    ::DBC_retrieve

	    # Take custom action after the system/global namespace DBC_retrieve
    }
}
