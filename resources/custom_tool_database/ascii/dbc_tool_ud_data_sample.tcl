###############################################################################
# dbc_tool_ud_data_sample.tcl - Sample to add user defined tool parameters
###############################################################################
###############################################################################
# REVISIONS
#   Date         Who              Reason
#   27-jan-2014  Gopal Srinath & Mark Rief  Initial
#
###############################################################################
#
#   This is a sample of dbc_tool_ud_data.tcl.
#   To demonstrate, rename this file to dbc_tool_ud_data.tcl and retrieve a mill tool.
# 
#   This is called from dbc_tool_ascii.tcl, and if found, will add user defined
#   tool parameters to a tool during retrieval from the library.
#
#   This sample will add one user parameter for each type available; and add 
#   two user parameters based on tool library fields, if they exist.
#
#   To see the parameters when editing the tool, the customizable item "user parameters"
#   must be added to the tool dialog. To do this for all retrieved tools, add it
#   to the tool dialogs in the library_dialogs template parts.
#
###############################################################################
#

#######
#   Procedure to initialize the variables for parameters of all types except Option ("o") type
#   This procedure will also increment the number of parameters
######
proc SetParameter { name pType value label } {
    global dbc_ud_num_parameters
    global dbc_ud_param_name
    global dbc_ud_param_type
    global dbc_ud_param_value
    global dbc_ud_param_label
    global dbc_ud_grouping_label
   
    set parameterIndex $dbc_ud_num_parameters
    set dbc_ud_param_name($parameterIndex) $name       ;# Name used for mom variable
    set dbc_ud_param_type($parameterIndex) $pType       ;# String 
	set dbc_ud_param_value($parameterIndex) $value
    set dbc_ud_param_label($parameterIndex) $label   ;# Dialog Label
    set dbc_ud_num_parameters [expr $dbc_ud_num_parameters + 1]
}

#######
#   Procedure to initialize the variables for parameters of the Option("o") type
#   This procedure will also increment the number of parameters
######
proc SetOptionParameter { name value values label } {
    global dbc_ud_num_parameters
    global dbc_ud_param_option_count
    global dbc_ud_param_options
   
    set parameterIndex $dbc_ud_num_parameters
    set numOptions [llength $values]
	set dbc_ud_param_option_count($parameterIndex) $numOptions
	for {set indx 0} {$indx < $numOptions} {incr indx} \
	{
		set dbc_ud_param_options($parameterIndex,$indx) [lindex $values $indx]
	}
	SetParameter $name "o" $value $label
}

##############################################
# This procedure will read the data for the libref and find the
# value for a given attribute id (the name of the column) 
# The last argument to this procedure will indicate if the attribute id
# was found or not
# 
# The possible values for this indicator are
#	0	-	The attribute was not found
#	1	-	Attribute was found but the value is "" in the database and so the return value will be set to
#			the input default value
#	2	-	Attribute found and has a value
#################################################

proc AskAttVal { attId dbRow outputFormat defaultValue flagRef } {
   upvar $flagRef flag
   global asc_database

   set cret [catch {set retValue $asc_database($dbRow,$attId)}]
   if { $cret } \
   {   
       set retValue $defaultValue   
       set flag 0
   } \
   else \
   {
       set retValue [string trim $retValue]
       if { $retValue == "" } \
       {
	       set retValue $defaultValue
           set flag 1
       } \
       else \
       {
          set flag 2
       }
   }
   if { $outputFormat != "" } {set retValue [format $outputFormat $retValue] }
   return $retValue
}

###############################################################
# This procedure will read the data array or the data file for the entry
# of the libref and return the row with the data
############################################################
proc FindEntry { } {
	global asc_file_loaded
	global dbc_libref
	
	# This section is reading
    if { $asc_file_loaded == 1 } \
    {
       ASC_array_search_libref $dbc_libref db_row 
    } \
    else \
    {
       ASC_file_search_libref $dbc_libref db_row
    }
	return $db_row
}


####################################################
#  The procedure that adds User Defined Parameters
####################################################
proc DBC_ud_data {} {
   global dbc_ud_num_parameters
   global dbc_ud_param_name
   global dbc_ud_param_type
   global dbc_ud_param_value
   global dbc_ud_param_option_count
   global dbc_ud_param_options
   global dbc_ud_param_label
   global dbc_ud_grouping_label

# Initialize number of parameters
   set dbc_ud_num_parameters 0
   
#  Label for the UI group
   set dbc_ud_grouping_label "User Tool Parameters"	;

# Define some sample parameters directly

#  Define integer parameter 
   SetParameter "sample_int" "i" -1 "Sample Integer"

#  Define double parameter
   SetParameter "sample_dbl" "d" -1 "Sample Double"

#  Define boolean parameter
   SetParameter "sample_bool" "b" "True" "Sample Toggle (Boolean)"

#  Define string parameter
   SetParameter "sample_str" "s" "default text" "Sample Text (String)"

#  Define option list parameter 
   set values { "Yes" "No" "Maybe" }
   set value [lindex $values 0]
   SetOptionParameter "sample_opt" $value $values "Sample Option List"

# Define some sample parameters based on tool database fields
 
#  Read the database to find the data of the libref
	set dbRow [FindEntry]
	
##### 
#   The following is an example of reading 2 Attributes from the database 
#	and then deciding if a parameter has to be added. In order to see the different behavior
#   retrieve tools from the following classes
#
#	Tool->Milling->End Mill 		- 	TAPA and TIPA are both valid and so there will be 2 additional
#	Tool->Milling->Ball Mill		-	TAPA is valid so only 1 additional parameter
#	Tool->Milling->Mill Form Tool	-	Both TAPA and TIPA are not valid so no additional parameters	
#   
######
#	Search for an Attribute TAPA (Taper Angle) for the OOTB database
	set angle [AskAttVal TAPA $dbRow "%g" 0 flag]
#	If this attribute exists for the tool selected then take the value and convert it to degrees
#   and add a parameter called TAPA
	if { $flag == 1 || $flag == 2 } {
		UGLIB_convert_deg_to_rad $angle
		SetParameter "TAPA" "d" $angle "Taper Angle (Library TAPA)"
	}
#	Search for an Attribute TIPA (Tip Angle) for the OOTB database
	set angle [AskAttVal TIPA $dbRow "%g" 0 flag]
#	If this attribute exists for the tool selected then take the value and convert it to degrees
#   and add a parameter called TIPA
	if { $flag == 1 || $flag == 2 } {
		UGLIB_convert_deg_to_rad $angle
		SetParameter "TIPA" "d" $angle "Tip Angle (Library TIPA)"
	}
 }
