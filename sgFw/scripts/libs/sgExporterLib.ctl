
/*
A library of functions useful for the Exporter panel
written by Andrew Burkimsher

History
01/09/2006: version 1.0

Function List:
** ed functions are the ones most likely to be called from something external to this library
sgExporter_ElementListForType
sgExporter_EvaluateDependency
sgExporter_ExportFullSystem **
sgExporter_ExportGlobals **
sgExporter_OutputFormatLangString
sgExporter_ParseType2
sgExporter_QueryFormatAndReturnSystemConfValues
sgExporter_RemoveNonLeafElements
sgExporter_UnfoldReferenceTypes
sgExporter_appendPart
sgExporter_attribsListForExportConfig
sgExporter_concatToEveryElement **
sgExporter_convertBit32StrToHexStr
sgExporter_convertDynDynTableToDynString **
sgExporter_dynDynAppend **
sgExporter_formatDPQueryOutput
sgExporter_formatValueForOutput
sgExporter_generateAlertClassValuesForDatabase
sgExporter_generateAlertValuesForSystem
sgExporter_generateAliasesCommentsForSystem
sgExporter_generateArchiveValuesForDatabase
sgExporter_generateCommandConvValuesForSystem
sgExporter_generateDPFunctionValuesForSystem
sgExporter_generateDPNamesOutput
sgExporter_generateDPValuesForSystem
sgExporter_generateDPsForSystem
sgExporter_generateDependenciesForSystem
sgExporter_generateDistribValuesForSystem
sgExporter_generatePeriphAddressValuesForSystem
sgExporter_generateTypeStructureForSystem
sgExporter_generateTypeStructuresForAllTypes
sgExporter_generateValuesForSystemAttributes
sgExporter_getConfigsWithDetailsUnformatted
sgExporter_getDetailNumber
sgExporter_getListOfDPEsForSystem
sgExporter_getListOfDPEsForSystemNew
sgExporter_getListOfSystemsFromDB **
sgExporter_getListOfSystemsFromScan **
sgExporter_getSystemDPsUsingExporterConfig
sgExporter_readTextFileToDynString **
sgExporter_saveCompleteExporterDPEList
sgExporter_transposeDynDyn **
sgExporter_trimProjectName **
sgExporter_writeDynDynStringToTextFile **
sgExporter_writeDynStringToTextFile **
*/

//################################# Attribute list for exportable config #################################
dyn_string sgExporter_attribsListForExportConfig(string config_name, bool include_conf_name, dyn_string &headers)
//all of the export functions export lists of attributes. however, these are not all the attributes,
//that are possible to be exported, neither are they in any particular order
//therefore, constant lists of the attributes that need to be exported for each type are needed
//so there aren't loads of named constants (where you can forget the name)
//i collected all the constant lists into this single function
//the &headers argument, on return, contains the value of the header constants for the given config_name
{
dyn_string attribs;
dyn_string header;
if (config_name == "_dp_fct")
	{
	attribs =  makeDynString(																		 
													"_type",
													"_param",
													"_fct",
													"_global",
													"_stat_type",
													"_interval",
													"_time",
													"_day_of_week",
													"_day",
													"_month",
													"_delay",
													"_read_archive",
													"_inv_func",
													"_inv_limit",
													"_def_func",
													"_def_limit",
													"_user1_func",
													"_user1_limit",
													"_user2_func",
													"_user2_limit",
													"_user3_func",
													"_user3_limit",
													"_user4_func",
													"_user4_limit",
													"_user5_func",
													"_user5_limit",
													"_user6_func",
													"_user6_limit",
													"_user7_func",
													"_user7_limit",
													"_user8_func",
													"_user8_limit",
													"_interm_res",
													"_interm_res_cyc"
													);
	header = "# DpFunction";
	}
else if (config_name == "_original")
	{
	attribs = makeDynString(
													"_value",
													"_status",
													"_stime"
												 );
	header = makeDynString("# DpValue\nElementName","TypeName");
	}
else if (config_name == "_alert_hdl")
	{
	attribs = makeDynString(
													"_type",
													"_l_limit",
													"_u_limit",
													"_l_incl",
													"_u_incl",
													"_panel",
													"_panel_param",
													"_help",
													"_min_prio",
													"_class",
													"_text",
													"_active",
													"_orig_hdl",
													"_ok_range",
													"_hyst_type",
													"_hyst_time",
													"_l_hyst_limit",
													"_u_hyst_limit",
													"_text1",
													"_text0",
													"_ack_has_prio",
													"_order",
													"_dp_pattern",
													"_dp_list",
													"_prio_pattern",
													"_abbr_pattern",
													"_ack_deletes",
													"_non_ack",
													"_came_ack",
													"_pair_ack",
													"_both_ack"
												 );

	header = makeDynString ("# AlertValue\nElementName", "TypeName",	"DetailNr");
	}
else if (config_name == "_distrib")
	{
	attribs = makeDynString(
													"_type",
													"_driver"
												 );
	header = makeDynString("# DistributionInfo");
	}
else if (config_name == "_address")
	{
	attribs = makeDynString(
													"_type",
													"_reference",
													"_poll_group",
													"_offset",
													"_subindex",
													"_direction",
													"_internal",
													"_lowlevel",
													"_active",
													"_start",
													"_interval",
													"_reply",
													"_datatype",
													"_drv_ident"
												 );
																				 
	header = makeDynString("# PeriphAddrMain");
	}
else if (config_name == "_alert_class")
	{
	attribs = makeDynString(
													"_type",
													"_prior",
													"_abbr",
													"_archive",
													"_ack_type",
													"_single_ack",
													"_inact_ack",
													"_color_none",
													"_fore_color_none",
													"_font_style_none",
													"_color_c_nack",
													"_fore_color_c_nack",
													"_font_style_c_nack",
													"_color_c_ack",
													"_fore_color_c_ack",
													"_font_style_c_ack",
													"_color_g_nack",
													"_fore_color_g_nack",
													"_font_style_g_nack",
													"_color_c_g_nack",
													"_fore_color_c_g_nack",
													"_font_style_c_g_nack",
													"_ctrl_none",
													"_ctrl_c_nack",
													"_ctrl_c_ack",
													"_ctrl_g_nack",
													"_ctrl_c_g_nack",
													"_arg_list",
													"_perm"
												 );
	header = makeDynString("# AlertClass");
	}
else if (config_name == "_archive")
	{
	attribs = makeDynString(
													"_type",
													"_archive",
													"_class",
													"_interv",
													"_interv_type",
													"_std_type",
													"_std_tol",
													"_std_time",
													"_round_val",
													"_round_inv"
												 );
	header = makeDynString("# DbArchiveInfo\nElementName", "TypeName", "DetailNr");
	}
else if (config_name == "_cmd_conv")
	{
	attribs = makeDynString(
													"_type",
													"_poly_grade",
													"_poly_a",
													"_poly_b",
													"_poly_c",
													"_poly_d",
													"_poly_e",
													"_linint_num",
													"_linint1_x",
													"_linint1_y",
													"_linint2_x",
													"_linint2_y",
													"_linint3_x",
													"_linint3_y",
													"_linint4_x",
													"_linint4_y",
													"_linint5_x",
													"_linint5_y",
													"_null_from",
													"_null_to",
													"_null_res",
													"_log_base",
													"_round_val",
													"_round_inv",
													"_trig_lim",
													"_trig_up",
													"_imp_edge",
													"_imp_rstval"
												 );
	header = makeDynString("# DpConvIngToRawMain\nElementName", "ElementType", "DetailNr");
	}
else
	{
	DebugN("unknown config supplied to attribsListForExportConfig");
	}

if (include_conf_name)
	{
	for (int i = 1; i<= dynlen(attribs); i++)
		{
		attribs[i] = config_name + ".." + attribs[i];
		}
	}

headers = header;
return attribs;
}



//---------------- database structure section ------------------------
//######################## Get list of DPEs for named system ########################
dyn_string sgExporter_getListOfDPEsForSystem(string system_name)
{
dyn_string all_dpes, dpe_leaves;
string sub_next;

dynClear(dpe_leaves);

all_dpes = dpNames( (system_name + ".**"));

dpe_leaves = sgExporter_RemoveNonLeafElements(all_dpes);

//remove any elements that end in a dot.
for (int x = dynlen(dpe_leaves); x >= 1; x--)
	{
	if (dpe_leaves[x][strlen(dpe_leaves[x])-1] == ".")
		{
		dynRemove(dpe_leaves, x);
		}
	}
return dpe_leaves;
}

//######################## A new version of get DPES for named system ########################
dyn_string sgExporter_getListOfDPEsForSystemNew(string system_name) 
{
dyn_dyn_anytype list;

dpQuery("SELECT '_original.._value' FROM '"+system_name+".**' WHERE _LEAF", list);

list = sgExporter_transposeDynDyn(list);
dyn_string names = list[1];
dynRemove(names, 1);

dynSortAsc(names);

return names;
}


//########################## Element List for Type ##################################
dyn_string sgExporter_ElementListForType(string data_point_type)
{
string dpt;
dyn_dyn_string names;
dyn_dyn_int types;
int struc;
dyn_string dpelist;

struc=dpTypeGet(data_point_type,names,types);

//dpelist = ParseType(names, false);
dpelist = sgExporter_ParseType2(names, false);
//DebugN(dpelist);
return dpelist;

}


//######################## transforms the PVSS returned type structre into something manageable ########################
dyn_string sgExporter_ParseType2(dyn_dyn_string structure, bool ShowRoot) //efficient and works properly unlike ParseType
{
dyn_string result, name_sections;

name_sections[1] = structure[1][1];

for (int i = 1; i<=dynlen(structure); i++)
	{
	int line_items = dynlen(structure[i]);
	string curr_line = "";
	
	if (line_items > 1) //if it's not an empty line or the root line
		{
		if (					//it is a reference type
			 	(structure[i][line_items] != "")
			  &&
			  (structure[i][line_items - 1] != "")
			 )
			{
			name_sections[line_items-1] = structure[i][line_items - 1];
			curr_line = name_sections[2 - ShowRoot];
			for (int s = 3 - ShowRoot; s < line_items ; s++)
				{
				curr_line = curr_line+"."+name_sections[s];				
				}
			curr_line = "Ref:"+structure[i][line_items]+"."+curr_line;			
			dynAppend(result, curr_line);
			}
		else //it is not a reference type
			{
			name_sections[line_items] = structure[i][line_items];
			curr_line = name_sections[2 - ShowRoot];
			for (int s = (3 - ShowRoot); s <= line_items ; s++)
				{
				curr_line = curr_line+"."+name_sections[s];				
				}
			dynAppend(result, curr_line);
			}
		}
//	else //it is an empty line or the root node
//		{
//		  don't do much
//		}
	}
dynSortAsc(result);

result = sgExporter_RemoveNonLeafElements(result);
	
return result;
}

//######################## Remove non-leaf elements from an **already sorted** list ########################
dyn_string sgExporter_RemoveNonLeafElements(dyn_string list)
{
dyn_string leaves_only = list;
for (int line = dynlen(leaves_only); line > 1; line--) //go from the end to the beginning
	{
	if (patternMatch(leaves_only[line-1]+".**", leaves_only[line]))
		{
		dynRemove(leaves_only, (line - 1));
		}
	}
return leaves_only;
}



//---------------- file interfacing section ------------------------

//######################## writes a dyn_string to a text file ########################
int sgExporter_writeDynStringToTextFile(dyn_string data, string textfilename)
{
	file textfile;
	int success_result;
	
	textfile = fopen(textfilename, "w");
	
	success_result = ferror(textfile);
	
	for (int line = 1; line <= dynlen(data); line++)
		{
		fputs((data[line]+"\n"), textfile);	
		}
		
	success_result += fclose(textfile);
	
	if (success_result != 0)
		{
		DebugN("File error in exporting dyn_string to textfile, using file " + textfilename);
		}
return success_result;
} //writeDynStringToTextFile

//######################## writes a dyn_dyn_string to a text file, one element per line ########################
int sgExporter_writeDynDynStringToTextFile(dyn_dyn_string data, string textfilename)
{
	file textfile;
	int success_result;
	
	textfile = fopen(textfilename, "w");
	
	success_result = ferror(textfile);
	
	for (int row = 1; row <= dynlen(data); row++)
		{
		if (dynlen(data[row]) > 0)
			{
			for (int column = 1; column < dynlen(data[row]); column++)
				{
				fputs((data[row][column]+"\t"), textfile);
				}
			fputs((data[row][dynlen(data[row])]+"\n"), textfile);
			}
		}
		
	success_result += fclose(textfile);
	
	if (success_result != 0)
		{
		DebugN("File error in exporting dyn_dyn_string to textfile, using file " + textfilename);
		}
return success_result;
} //writeDynDynDynStringToTextFile


//######################## converts a dyn_dyn_string to a dyn_string, tab delimited ########################
dyn_string sgExporter_convertDynDynTableToDynString(dyn_dyn_string data)
{
dyn_string result_lines;
string single_line = "";

for (int row = 1; row <= dynlen(data); row++)
		{
		for (int column = 1; column < dynlen(data[row]); column++)
			{
			single_line += (data[row][column]+"\t");
			}
		single_line += (data[row][dynlen(data[row])]);
		result_lines[row] = single_line;
		single_line = "";
		}
return result_lines;
}


//######################## saves a fresh copy of the exporter config file, with everything enabled ########################
dyn_string sgExporter_saveCompleteExporterDPEList(string file_name)
{
dyn_string full_type_list, clean_type_list, type_elements, all_types_elements;

//get list of types
full_type_list = dpTypes();
//remove internal types
for (int type_index = 1; type_index <= dynlen(full_type_list); type_index++)
	{
	if (full_type_list[type_index][0] != '_')
		{
		dynAppend(clean_type_list, full_type_list[type_index]);
		}	
	}

//build list of all types and their immediate elements (not reference elements)
//in format [typename]:[DPE]

for (int t = 1; t <= dynlen(clean_type_list); t++) //for every type
	{
	type_elements = sgExporter_ElementListForType(clean_type_list[t]); //get its list of elements

	for (int p = 1; p <= dynlen(type_elements); p++) //for every element
		{
		if ( (!patternMatch("Ref:*", type_elements[p])) && (strlen(type_elements[p]) > 0) ) //if the element is not a ref type, and the element name isn't 0 length (the element has a name)
			{
			dynAppend(all_types_elements, clean_type_list[t]+":"+type_elements[p]);  //append the type:element to the list
			}
		}
	}

if (file_name != "")
	{
	sgExporter_writeDynStringToTextFile(all_types_elements, file_name); //save the list to the named file
	}

return all_types_elements;	//return the data for use elsewhere

}

//######################## reads a text file to a dyn_string - one line per element ########################
dyn_string sgExporter_readTextFileToDynString(string FileName)
{
file file_ptr;
dyn_string file_contents;

if (fexist(FileName))
	{
	file_ptr = fopen(FileName, "r");
	int lineno = 1;
	 
	while (feof(file_ptr)==0) // if not at end of file
		{
		fgets(file_contents[lineno],1024,file_ptr); // reads from the file
		file_contents[lineno] = strrtrim(file_contents[lineno], "\n"); //removes newline char from end of line
		lineno++;
		}
	fclose(file_ptr);
	dynRemove(file_contents, dynlen(file_contents)); //remove the empty line at the end
	}
return file_contents;
}

//---------------- string formatting section ------------------------
//######################## transpose the elements of a dyn_dyn_ array ########################
dyn_dyn_anytype sgExporter_transposeDynDyn(dyn_dyn_anytype data)
{
dyn_dyn_anytype data2;
for (int x = 1; x <= dynlen(data); x++)
	{
	for (int y = 1; y <= dynlen(data[x]); y++)
		{
		data2[y][x] = data[x][y];
		}	
	}
return data2;
}

//######################## concatenate 2 dyn_dyns ########################
void sgExporter_dynDynAppend(dyn_dyn_string &table1, dyn_dyn_string table2)
{
int table1length = dynlen(table1);

for (int i = 1; i <= dynlen(table2); i++)
	{
	table1[table1length + i] = table2[i];	
	}

}


//######################## concatenate to every element ########################
dyn_string sgExporter_concatToEveryElement(dyn_string FirstList, dyn_string SecondList)
{
//FirstList[x]+SecondList[y]
//for every x and y.
dyn_string result;
for (int x = 1; x <= dynlen(FirstList); x++)
	{
	for (int y = 1; y <= dynlen(SecondList); y++)
		{
		dynAppend(result, FirstList[x]+SecondList[y]);
		}
	}
return result;
}

//######################## format anytype values for output ########################
string sgExporter_formatValueForOutput(anytype value)
{
const string LANG_STRING = 2621440;

string type = getType(value);	//get the type of this value to enable type-specific handling
string dp_value_contents = "";	//reset the output string
if ((type == BOOL_VAR) || (type == INT_VAR) || (type == UINT_VAR)) //if the value is a bool or an int, write it straight out as an int
	{
	int b = value;
	dp_value_contents = b;
	return dp_value_contents;
	}
else if (type == ANYTYPE_VAR)
	{
	if (value != 0)
		{
		DebugN("anytype with non-nil value... huh?", type, value);
		}	
	return dp_value_contents;
	}
else if (type == FLOAT_VAR)
	{
	dp_value_contents = (string) value;
	return dp_value_contents;
	}
else if (type == DYN_STRING_VAR) //if it's a dyn string of non-zero length, write out a list enclosing each item in "" separated by commas
	{
	if  (dynlen(value) > 0)
		{	
		for (int s = 1; s < dynlen(value); s++)
			{
			dp_value_contents = dp_value_contents + '"'+value[s]+'"'+", ";
			}
		dp_value_contents = dp_value_contents + '"'+value[dynlen(value)]+'"';
		}
	return dp_value_contents;
	}	
else if (type == STRING_VAR) //if it's a string, output the value in ""
	{
	dp_value_contents = '"'+value+'"';
	return dp_value_contents;
	}
else if (type == DYN_INT_VAR) //if it's a dyn int, output as for dyn string, but without the ""
	{
	if (dynlen (value) > 0)
		{	
		for (int s = 1; s < dynlen(value); s++)
			{
			dp_value_contents = dp_value_contents + value[s]+", ";
			}
		dp_value_contents = dp_value_contents + value[dynlen(value)];
		}
	return dp_value_contents;
	}
else if (type == LANG_STRING) //if it's a lang string, output the constants before it
	{
	dp_value_contents = sgExporter_OutputFormatLangString() + value + '"';
	return dp_value_contents;
	}
else if (type == TIME_VAR) //if it's a time, output the date in the reverse order of fields
	{
	string t = value;
	dyn_string s = strsplit(t, " ");
	dyn_string d = strsplit(s[1], ".");
	dyn_string d1;
	d1[1] = d[3];
	d1[2] = d[2];
	d1[3] = d[1];
	dp_value_contents = ConcatDynStringWithChar(d1, ".") + " " + s[2];
	return dp_value_contents;
	}
else if (type == CHAR_VAR)
	{
	int charval = value;
	char backslash = 92;
	if (charval == 0)
		{
		dp_value_contents = backslash + "0";
		}
	else
		{
		dp_value_contents = backslash;
		dp_value_contents = dp_value_contents + charval;		
		}
	return dp_value_contents;
	}
else if (type == BIT32_VAR)
	{
	dp_value_contents = sgExporter_convertBit32StrToHexStr(value);
	}
else if (type == DPIDENTIFIER_VAR)
	{	
	dp_value_contents = sgExporter_trimProjectName((string) value);
	return dp_value_contents;
	}
else if (type == DYN_DPIDENTIFIER_VAR)
	{
	dp_value_contents = "";
	if (dynlen(value) > 0)
		{
		dp_value_contents = value[1];
		for (int j = 2; j<=dynlen(value); j++)
			{
			dp_value_contents = dp_value_contents + ", " + value[j];
			}
		}
	return dp_value_contents;
	}
else //otherwise, just write the value straight out. if more data types are added to PVSS in the future, or the ascii manager output format changes, this could need to be changed.
	{
	DebugN("in formatValueForOutput, default out because unknown type as yet, ID:", type, value);		
	dp_value_contents = value;
	return dp_value_contents;
	}

return dp_value_contents;

}

//######################## Convert a Bit32 into a hex string 0xNNN ########################
string sgExporter_convertBit32StrToHexStr(string b32str)
{
string result = "0x";
mapping NibbleToHex;
NibbleToHex["0000"]="0";
NibbleToHex["0001"]="1";
NibbleToHex["0010"]="2";
NibbleToHex["0011"]="3";
NibbleToHex["0100"]="4";
NibbleToHex["0101"]="5";
NibbleToHex["0110"]="6";
NibbleToHex["0111"]="7";
NibbleToHex["1000"]="8";
NibbleToHex["1001"]="9";
NibbleToHex["1010"]="a";
NibbleToHex["1011"]="b";
NibbleToHex["1100"]="c";
NibbleToHex["1101"]="d";
NibbleToHex["1110"]="e";
NibbleToHex["1111"]="f";

string inter_str;

for (int i = 6; i <= 8; i++) //this is becasue pvss output only uses 3 hex chars, even though many more are specified
	{
	inter_str = "";
	
	inter_str = inter_str + b32str[((i-1)*4)];
	inter_str = inter_str + b32str[((i-1)*4)+1];
	inter_str = inter_str + b32str[((i-1)*4)+2];
	inter_str = inter_str + b32str[((i-1)*4)+3];
	result = result + NibbleToHex[inter_str];
	
	}

return result;

}


//######################## Output the Format prefix for LangString type ########################
string sgExporter_OutputFormatLangString()
//the LangString type needs a starting format - this generates this format.
{
int num_langs = getNoOfLangs();	//get the number of languages
int curr_lang_id = getGlobalLangId(getLocale(0));	//get the id of the language currently in use
string result = "lt:"+num_langs+" LANG:"+curr_lang_id+" "+'"';	 //make the language text string (same for all points).
return result;
}


// -------------------------- database access section ---------------------

//######################## Get List of systems from DB ########################
dyn_string sgExporter_getListOfSystemsFromDB()
{
//this is a fixed dp that contains a list of systems:
const string SG_SYSTEMS_LIST_DP = "SystemStatus.GlobalStatus.LogicConfig.Inputs";

dyn_string result;
int good_str_len = 0;
int del_len = 13; //strlen(".GlobalStatus");

dpGet(SG_SYSTEMS_LIST_DP, result); 

//remove the ".GlobalStatus" from the end of every string
for (int count = 1; count <= dynlen(result); count++)
	{
	good_str_len = strlen(result[count]) - del_len;
	result[count] = substr(result[count], 0, good_str_len);
	}
dynSortAsc(result); //sort it
return result; //return
}


//######################## Get list of systems from scan ########################
dyn_string sgExporter_getListOfSystemsFromScan()
{
//instead of relying on the datapoint that has to be filled in manually with a list of systems
//this scans the database for all top-level, non-internal datapoints
dyn_string all_systems = dpNames("*");//get all top level points
dyn_string useful_systems;

for (int i = 1; i<=dynlen(all_systems); i++) //for every point
	{
	string dpname_trim = sgExporter_trimProjectName(all_systems[i]);
	string this_pts_type = dpTypeName(dpname_trim); //find the point's type
	
	if (!patternMatch("_*", this_pts_type)) //if the point's type is not an internal one
		{
		dynAppend(useful_systems, dpname_trim); //add the point to the list
		}
	}
return useful_systems;
}


//######################## Generate Type Structure For System ########################
dyn_dyn_string sgExporter_generateTypeStructureForSystem(string system_name, string type_name = "empty")
//for a given system name, output the type structure, formatted like the ascii manager output
//is possible to just supply a type name, if that is the case then the system name is ignored
{
dyn_dyn_string type_struct_names;
dyn_dyn_int type_struct_ids;
string system_type;
const dyn_string TYPE_STRUCT_HEADER = makeDynString("# DpType\nTypeName");
dyn_dyn_string intermediate_result;
int dpe_index = 1;
int inter_res_index = 1;
dyn_dyn_string result;

//find out the type of the given system
if (type_name == "empty")
	{
	system_type = dpTypeName(system_name);
	}
else
	{
	system_type = type_name;
	}	

//ask pvss for the structure of the system
dpTypeGet(system_type, type_struct_names, type_struct_ids);
//this structure is what i'm wanting to export. it's just not in the right format.

/*
formatting section
format of type structure output is: 
Header
	#DpType
	TypeName
system_type_name.system_type_name (don't know why it's repeated but it is)
then struct:
	(->)* dpe_name -> element_type_number#element_index_number
element_type_number is found from "type_struct_ids"
element_index_number is simply unique for each node and is assigned when that node is created.
if the type is edited, these nodes become no longer sequential. I believe that it's ok to make 
them sequential again, because I can't find anywhere to access these node index numbers through CTRL. (they are not the elemID from dpGetId - i've checked!)
*/

for (int line = 1; line <= dynlen(type_struct_names); line++) //traverse the entire list of type lines
	{
	if (dynlen(type_struct_names[line]) > 0) //if it isn't an empty line
		{
		int type_ref_number = type_struct_ids[line][dynlen(type_struct_ids[line])];
		int line_length = dynlen(type_struct_names[line]);
		
		if (line_length > 1) //if it's not a root node which wouldn't have a ref type anyway
			{
			if (type_struct_names[line][line_length-1] != "")  //if it does have a ref type associated
				{
				//insert the type number before the ref type
				type_struct_names[line][line_length] = type_ref_number + "#"+dpe_index+":" + type_struct_names[line][line_length];
  			dpe_index++;
				}
			else //it isn't a ref type, so insert the type number at the end of the line
				{
				type_struct_names[line][line_length + 1] = type_ref_number + "#"+dpe_index;
				dpe_index++;
				}
			}
		else //it is the root node which isn't a ref type, so insert the type number at the end of the line and double up the name
			{
			type_struct_names[line][line_length] = type_struct_names[line][line_length] + "." + type_struct_names[line][line_length];
			type_struct_names[line][line_length + 1] = type_ref_number + "#"+dpe_index;
			dpe_index++;
			}
		}
	}

//remove empty lines
for (int line = 1; line <= dynlen(type_struct_names); line++)
	{
	if (dynlen(type_struct_names[line]) > 0)
		{
		intermediate_result[inter_res_index] = type_struct_names[line];
		inter_res_index++;
		}
	}

//concatenate the data with the header, but only if you are outputting a system

if (type_name == "empty")
	{
	result[1] = TYPE_STRUCT_HEADER;
	}

sgExporter_dynDynAppend(result, intermediate_result);

return result;
}

//######################## Generate datapoints for system ########################
dyn_dyn_string sgExporter_generateDPsForSystem(string system_name, dyn_string extra_dps = makeDynString("empty"))
{
//takes a system name and outputs the formatted data points names as like the ascii manager
//also has the possibility of taking 'extra' datapoints and listing them too
if ((dynlen(extra_dps) == 0) || (extra_dps[1] == "empty"))
	{
	extra_dps = makeDynString(system_name);
	}
else
	{
	dynInsertAt(extra_dps, system_name, 1);
	}

return sgExporter_generateDPNamesOutput(extra_dps); //use the function that generates the output from a list of dps
}

//######################## generate DP names output ########################
dyn_dyn_string sgExporter_generateDPNamesOutput(dyn_string dp_names)
//takes a list of DPs, gets their IDs and formats them like the ascii manager
{
const dyn_string DP_HEADER = makeDynString("# Datapoint/DpId\nDpName","TypeName","ID");
dyn_dyn_string output;
unsigned dpid;
int elid;

output[1] = DP_HEADER;

for (int i = 1; i<= dynlen(dp_names); i++)
	{
	output[i+1][1] = sgExporter_trimProjectName(dp_names[i]); //first column is the name
	output[i+1][2] = dpTypeName(dp_names[i]);	//second column is the type
	dpGetId(dp_names[i], dpid, elid);
	output[i+1][3] = dpid;	//third column is the datapoint id
	}
return output;
}

//######################## Generate aliases and comments output for system ########################
dyn_dyn_string sgExporter_generateAliasesCommentsForSystem(string system_name)
{
/*
outputs as a dyn_string the Aliases/Comments section of an ascii manager output file for a given named system.
currently does not output the lines in the same order as the ascii manager itself. I believe this does not matter.
in format:
# Aliases/Comments
AliasId	AliasName	CommentName
[point name]	"[alias if exists]"	lt:[num langs] LANG:[curr lang id] "[comment]@[dp format]@"
*/
const string ALIASES_COMMENTS_HEADER1 = "# Aliases/Comments";
const dyn_string ALIASES_COMMENTS_HEADER2 = makeDynString("AliasId", "AliasName", "CommentName");

string lang_text, num_langs, curr_lang_id;
dyn_string dps;
dyn_dyn_string dps_with_comments;

dyn_string local_dp_names = dpNames(system_name+".**"); //get the names of all dps/dpes in this system
dyn_langString descriptions = dpGetDescription(local_dp_names, -2); //get all their descriptions
dyn_string aliases = dpGetAlias(local_dp_names);	//get all their aliases
int dwc_index = 1;

string dp_format = "";

lang_text = sgExporter_OutputFormatLangString();	 

//fill the dyn_dyn - traverse the list of dps
for (int i = 1; i <= dynlen(local_dp_names); i++)
	{
	if ((descriptions[i] != "") || (aliases[i] != "")) //if there is either a comment or an alias for a given point, store this.
		{
		dp_format = dpGetFormat(local_dp_names[i]); //get the format of the DP
		
		dps_with_comments[dwc_index][1] = local_dp_names[i];	//insert dp name
		dps_with_comments[dwc_index][2] = '"'+aliases[i]+'"';	//insert dp alias
		dps_with_comments[dwc_index][3] = lang_text+descriptions[i]+"@"+dp_format+"@"+'"'; //insert dp description
		dwc_index++; //increment the index in the array
		}
	}

//remove the system name from the beginning of the names of all the data points
int sys_name_length = strlen(getSystemName());

for (int x = 1; x<= dynlen(dps_with_comments); x++)
	{
	dps_with_comments[x][1] = substr (dps_with_comments[x][1], sys_name_length, strlen(dps_with_comments[x][1])-sys_name_length);
	}

//insert headers
dynInsertAt(dps_with_comments, ALIASES_COMMENTS_HEADER1, 1);
dynInsertAt(dps_with_comments, ALIASES_COMMENTS_HEADER1, 2);
dps_with_comments[2] = ALIASES_COMMENTS_HEADER2;

return dps_with_comments;
}

//######################## Unfold Reference Types ########################
dyn_string sgExporter_UnfoldReferenceTypes(string parent_path, string curr_type)
// from a starting path, this returns all datapoint element names for the current type
//it also recurses into the reference types to obtain their datapoint element names
//it recurses until there are no more dpes to be found.
{
dyn_string this_types_refs;
dyn_string el_list = sgExporter_ElementListForType(curr_type); //get a list of the elements in the current type

//output current reference type
dynAppend(this_types_refs, curr_type+":"+parent_path);

//recurse
for (int i = 1; i<=dynlen(el_list); i++)
	{
	if (patternMatch("Ref:*", el_list[i]))
		{
		dyn_string cut;
		cut = strsplit(el_list[i], ":"); //remove the "Ref:" from the beginning
		cut = strsplit(cut[2], ".");	
		
		//create the string representing the DP path
		string joined = parent_path;

		for (int s = 2; s<=dynlen(cut); s++)
			{
			joined = joined + "." + cut[s];
			}
		
		//recurse into the type, in case the specified type itself contains reference types
		dynAppend(this_types_refs, sgExporter_UnfoldReferenceTypes(joined, cut[1]));
		}	
	}
return this_types_refs;
}

//######################## Get System DPs using exporter config ########################
dyn_string sgExporter_getSystemDPsUsingExporterConfig(string system_name, string export_conf_filename, mapping &dpname_to_index, dyn_dyn_anytype &dep_res)
{
/*
this generates a list of the DP names to be exported for a given system
it does this by:
- traversing the system type structure recursively to find all the possible sub-types (reference elements)
- using the configuration for each of those types to create a list of dpes.
*/

string line_type, line_name;
string system_type = dpTypeName(system_name);
bool use_this_point;
dyn_string matches, single_match, line_split, all_dpes_desired, dep_dyn, attrib_names;
//dyn_dyn_anytype dep_res;
dyn_dyn_anytype points_with_values;
//mapping dpname_to_index;

dyn_string config_file_contents = sgExporter_readTextFileToDynString(export_conf_filename);	//load the details of the config file
dyn_string type_struct_with_refs = sgExporter_UnfoldReferenceTypes(system_name, system_type);//generate the list of sub-types


//get all the possible dp values for the system name so that the dependencies can be evaluated
//dpQuery("SELECT '_online.._value' FROM '" + system_name + ".**' WHERE \"TRUE\"", dep_res);
for (int i = 2; i<=dynlen(dep_res); i++)
	{
	dpname_to_index[sgExporter_trimProjectName(dep_res[i][1])] = i;	
	}

/*merge these two lists
a sub-type has a set of dpe names associated with it in the config file.
the config file is stored in the format [type]:[dpe name]

i then use the path of the sub-type to generate a list of all the dpe names for each sub-type
and then concatenate all these lists.

format:
[sub-type path].[dpe name from config file] == a DPE path
*/

for (int struct_index = 1; struct_index <= dynlen(type_struct_with_refs); struct_index++) //loop through each subtype
	{
  line_split = strsplit(type_struct_with_refs[struct_index], ":"); //split to identify the parts of each line of conf file
	line_type = line_split[1];
	line_name = line_split[2];
	
	for (int conf_index = 1; conf_index <= dynlen(config_file_contents); conf_index++) //loop through the config file
		{
		use_this_point = false;
		if (patternMatch(line_type+":*", config_file_contents[conf_index])) //if the type matches,...
			{
			single_match = strsplit(config_file_contents[conf_index], ":"); //generate the string representing a datapoint
			
			//check dependencies
			if (dynlen(single_match) < 3) //it isn't dependent
				{
				use_this_point = true;
				}
			else //if there are dependencies, evaluate the dependency
				{
				dep_dyn = strsplit(single_match[3], ";"); //split up the semicolon delimeted dependency into its constituent parts
				attrib_names = strsplit(dep_dyn[1], ","); //split up the comma delimited list of dependent points
				//fill the points_with_values array with the attrib names, and their values for this specific element
				dynClear(points_with_values);
				for (int attrib_index = 1; attrib_index <= dynlen(attrib_names); attrib_index++)
					{
					points_with_values[attrib_index][1] = attrib_names[attrib_index];
					points_with_values[attrib_index][2] = dep_res[dpname_to_index[line_name + "." + attrib_names[attrib_index]]][2];
					}
				//evaluate the dependency using this data
			//	DebugTN(line_name, points_with_values[1][1]);//, dep_dyn[2], points_with_values);
				use_this_point = sgExporter_EvaluateDependency(line_name, dep_dyn[2], points_with_values);
				}
			if (use_this_point)
				{
				dynAppend(all_dpes_desired, line_name+"."+single_match[2]);	//append the dpe name to the dpe list
				}
			}
		}
	}

//DebugN(all_dpes_desired);

dynSortAsc(all_dpes_desired); //sort the dpe list (necessary so that the non-leaf elements can be removed

all_dpes_desired = sgExporter_RemoveNonLeafElements(all_dpes_desired); //remove all non-leaf elements. (sometimes non-leaves can be included as an artifact of the way i've done it - don't think this applies anymore, bug fixed :))

return all_dpes_desired; //return the list of dpe paths
}

//############################### Evaluate Single Dependency ##############################
bool sgExporter_EvaluateDependency(string point_name, string boolean_expression, dyn_dyn_anytype attrib_list_with_values)
//uses EvalScript to evaluate a boolean expression containing attributes. the attribute names and values are passed in
{
const string dollar_start = "$Var";

bool bool_result;
int eval_success;
dyn_string dollar_params;
string little_script, this_dollar_id, this_dynlen_str;

//substitute in the actual values
for (int i = 1; i<= dynlen(attrib_list_with_values); i++)
	{
	this_dollar_id = dollar_start + i;
	this_dynlen_str = "dynlen(" + attrib_list_with_values[i][1] + ")";
	if ( 0 <= strpos(boolean_expression, this_dynlen_str)) //because you can't pass dyn-s through a string with the dollar variables, treat dynlen requests differently
		{
		strreplace(boolean_expression, this_dynlen_str, dynlen(attrib_list_with_values[i][2]));
		}
	else
		{
		strreplace(boolean_expression, attrib_list_with_values[i][1], this_dollar_id );
		dynAppend(dollar_params, this_dollar_id + ":" + attrib_list_with_values[i][2]);
		}
	}

//DebugN(boolean_expression);

//generate the script to run
little_script =
								"bool main() " +
								"{" +
								"return (" + boolean_expression +");" +
								"}";

//evaluate the value of the script
eval_success = evalScript(bool_result, little_script, dollar_params);

//return the value
if (eval_success == 0)
	{
	return bool_result;	
	}
else
	{
	DebugN("error in evaluating " + boolean_expression + "in EvaluateDependency");
	return true; //had been false, but safer to return true - meaning if it cannot evaluate the dependency, default to ouputting the string
	}
}



//######################## generate DP values for system  ########################
dyn_dyn_string sgExporter_generateDPValuesForSystem(string system_name, string export_conf_filename)
{
const string PVSS_BASE_TIME = "01.01.1970 00:00:00.000";
dyn_string export_dp_list, dpget_list, single_get_list, DPValuesHead, DPValuesAttribs;
dyn_anytype dpget_result;
dyn_dyn_string dps_to_export;
string curr_dp_name, get_data, system_type, attribs_string_list, query_string;
dyn_dyn_anytype all_points_result;
mapping all_points_name_to_index;


DPValuesAttribs = sgExporter_attribsListForExportConfig("_original", true, DPValuesHead);//makeDynString("_original.._value","_original.._status","_original.._stime");
system_type = dpTypeName(system_name);

attribs_string_list = "'" + DPValuesAttribs[1] + "'";
for (int p = 2; p <= dynlen(DPValuesAttribs); p++)
	{
	attribs_string_list = attribs_string_list + ", '" + DPValuesAttribs[p] + "'";
	}

query_string = "SELECT "+ attribs_string_list + " FROM '" + system_name + ".**' WHERE \"TRUE\"";

dpQuery(query_string, all_points_result);

for (int point_index = 2; point_index <= dynlen(all_points_result); point_index++)
	{
	all_points_name_to_index[sgExporter_trimProjectName(all_points_result[point_index][1])] = point_index;	
	}

//get the list of DPs to export using the exporter config file
export_dp_list = sgExporter_getSystemDPsUsingExporterConfig(system_name, export_conf_filename, all_points_name_to_index, all_points_result);

//-- data formatting section --
//fill the results table with what's inside in the right format
for (int dp_index = 1; dp_index <= dynlen(export_dp_list); dp_index++)
	{
	dps_to_export[dp_index+1][1] = export_dp_list[dp_index];
	dps_to_export[dp_index+1][2] = system_type;
	
	for (int x = 1; x<=dynlen(DPValuesAttribs); x++)
		{
		anytype single_output = all_points_result[all_points_name_to_index[export_dp_list[dp_index]]][x+1];
		dps_to_export[dp_index+1][x+2] = sgExporter_formatValueForOutput(single_output);
		}
	}
//remove all points that only have default values (this is what the ascii manager does)
//you can tell the default values because their "_original.._stime" is 1970.01.01 00:00:00.000
int time_index = dynContains(DPValuesAttribs, "_original.._stime")+2;
for (int dp_index = dynlen(dps_to_export); dp_index > 1; dp_index--)
	{
	if (dps_to_export[dp_index][time_index] == PVSS_BASE_TIME)
		{
		dynRemove(dps_to_export, dp_index);
		}
	}	
//insert headers
dynAppend(DPValuesHead, DPValuesAttribs);
dps_to_export[1] = DPValuesHead;


//return complete list

return dps_to_export;
}

/*
//######################## Get archive detail number ########################
string getArchiveDetailNumber(string archive_path)
//using the archive constants, find out how many details a point has
{
return getDetailNumber(archive_path, "_archive", "type", makeDynAnytype(DPCONFIG_DB_ARCHIVEINFO), makeDynAnytype(DPATTR_ARCH_PROC_SIMPLESM, DPATTR_ARCH_PROC_VALARCH));
}

//######################## get alert handling detail number ########################
string getAlertHdlDetailNumber(string alert_hdl_path)
//using the constants for alert handling, find out how many details a point has
{
return getDetailNumber(alert_hdl_path, "_alert_hdl", "type", makeDynAnytype(DPCONFIG_ALERT_NONBINARYSIGNAL), makeDynAnytype(DPDETAIL_RANGETYPE_MINMAX));
}
*/


//######################## get detail number ########################
string sgExporter_getDetailNumber(string dpe_path, string config_name, string config_attribute, dyn_anytype base_constant, dyn_anytype detail_constant)
//find out how many details a point has by scanning down until a detail is empty
{
string result = "";
int DetNum = 0;
mixed dpres;

dpGet(dpe_path + ":"+config_name+"." + DetNum + "."+ config_attribute, dpres);

if (dynContains(base_constant, dpres))// if the point contains details
	{
	do
		{
		result = DetNum;
		DetNum++;
		dpGet(dpe_path + ":"+config_name+"." + DetNum + "."+ config_attribute, dpres);
		}
	while (dynContains(detail_constant, dpres)); // while the point still contains details
	}	
return result;
}

//######################## generate alert values for system ########################
dyn_dyn_string sgExporter_generateAlertValuesForSystem(string system_name)
//this outputs the alert handling section of the output file, formatted like the ascii manager does
{
const string alert_prefix = "_alert_hdl";
dyn_string alert_attribs, AlertHeaders;
alert_attribs = sgExporter_attribsListForExportConfig(alert_prefix, true, AlertHeaders);

dyn_string sysdpe_list = sgExporter_getListOfDPEsForSystem(system_name);

dyn_string dpes_with_alerts;
dyn_anytype alertdata1;
dyn_dyn_anytype uf_config_data;
dyn_dyn_string out_format;

for (int i = 1; i<= dynlen(sysdpe_list); i++) //make a big list of elements to get the alert data for
	{
	sysdpe_list[i] = sysdpe_list[i]+":"+alert_prefix+".._type";
	}

dpGet(sysdpe_list, alertdata1); //get alert data for each point

for (int i = 1; i<= dynlen(sysdpe_list); i++) //find the points that actually have alerts enabled on them
	{
	if (alertdata1[i] != 0) //if alerts enabled
		{	
		dynAppend(dpes_with_alerts, sgExporter_trimProjectName(sysdpe_list[i])); //put the point name in a list
		}
	}

uf_config_data = sgExporter_getConfigsWithDetailsUnformatted(dpes_with_alerts, alert_attribs, alert_prefix); //get the values for the alert handling points, using the generic function that handles details

for (int x = 1; x <= dynlen(uf_config_data); x++) //for each point with data
	{	
	for (int y = 1; y <= (dynlen(alert_attribs)+3); y++) //for each attribute
		{
		if (y > 3) //if it's an attribute it will need to be formatted
			{
			//very wierd, but the ascii manager doesn't export the _text attribute even though it has a value!
			//even wierder, when you try to import with the _text attribue specified, it fails...!
			//therefore, remove it if necessary
			if (alert_attribs[y-3] == alert_prefix+".._text")	
				{
				out_format[x+1][y] = "";
				}
			else
				{
				out_format[x+1][y] = sgExporter_formatValueForOutput(uf_config_data[x][y]); //output the formatted attributes
				}
			}
		else
			{
			out_format[x+1][y] = uf_config_data[x][y]; //output the unformatted names, types and detail numbers
			}
		}
	}

//insert the headers
dynAppend(AlertHeaders, alert_attribs);
out_format[1] = AlertHeaders; 

return out_format; //return the filled, formatted output table
}

//######################## format DP query output ########################
dyn_dyn_string sgExporter_formatDPQueryOutput(dyn_dyn_anytype output)
//this takes the raw output generated by a dpQuery on a set of points, and formats it using the formatting output routine
{
dyn_dyn_string output_formatted;
for (int i = 2; i <= dynlen(output); i++) //for all but the first line which is always empty coming from a DPQuery
	{
	if (dynlen(output[i]) != 0) //if the line is not empty
		{
		output_formatted[i][1] = sgExporter_trimProjectName(output[i][1]);
		for (int p = 2; p <= dynlen(output[i]); p++)
			{
			output_formatted[i][p] = sgExporter_formatValueForOutput(output[i][p]);
			}
		}
	}
return output_formatted;
}

//######################## generate distribution table for system ########################
dyn_dyn_string sgExporter_generateDistribValuesForSystem(string system_name)
//using constants, use the generic procedure to get the distribution table formatted like the ascii manager
{
dyn_string distrib_attribs, distrib_headers;
distrib_attribs = sgExporter_attribsListForExportConfig("_distrib", false, distrib_headers);

return sgExporter_QueryFormatAndReturnSystemConfValues(system_name, "_distrib", distrib_headers, distrib_attribs);
}

//######################## query, format and return configuration values for a given system ########################
dyn_dyn_string sgExporter_QueryFormatAndReturnSystemConfValues(string system_name, string config_name, string header_comment, dyn_string attribs = makeDynString("empty"), string condition = "empty")
//this takes a lot of parameters so that the values for a given system's configs can be obtained easily.
//attributes and the testing condition for the dpQuery are optional parameters
//a dpQuery can only handle certain configs. it is tested that the config supplied is one of these
//where these configs are available, use this function because it is Much quicker than "generateValuesForSystemAttributes"
{
dyn_dyn_string formatted_out;
dyn_string valid_configs = makeDynString(
																				"_alert_class",
																				"_alert_hdl",
																				"_auth",
																				"_default",
																				"_distrib",
																				"_dp_fct", 
																				"_lock",
																				"_offline",
																				"_online",
																				"_original",
																				"_pv_range",
																				"_u_range"
																				);

if (dynContains(valid_configs, config_name) > 0)
	{
	string config_list_str, conf_temp_str;
	dyn_string config_list_dyn, all_atts, headers;
	dyn_dyn_anytype output;
	
	if (condition == "empty")
		{
		condition = "('"+config_name+".._type' != 0)";
		}
/*	else
		{
		condition = condition;
		}
*/	
	if (dynlen(attribs) == 0)
		{
		all_atts = dpGetAllAttributes(config_name); 
		}
	else
		{
		all_atts = attribs;
		}

	//make a list of all configs in a single string
	//this is for the SELECT part of the dpQuery
	//config_list_str accumulates this
	//config_list_dyn accumulates the attributes, and is used for the header output at the end
	conf_temp_str = config_name + ".." + all_atts[1];
	config_list_str = "'" + conf_temp_str + "'";
	config_list_dyn[1] = conf_temp_str;
	for (int att_index = 2; att_index <= dynlen(all_atts); att_index++)
		{
		conf_temp_str = config_name + ".." + all_atts[att_index];
		config_list_str = config_list_str + ", '" + conf_temp_str + "'";
		dynAppend(config_list_dyn, conf_temp_str);
		}
	
	//if the system name isn't empty, append .** so all it's sub-points will be accessed
	if (system_name != "*")
		{
		system_name = system_name + ".**";
		}
	
	//generate the query string
	string query_string = "SELECT " + config_list_str + " FROM '" + system_name + "' WHERE " + condition;

	//perform the dpQuery
	dpQuery(query_string, output);

	//format the output
	formatted_out = sgExporter_formatDPQueryOutput(output);

	//insert the type names in the correct location
	for (int i = 2; i <= dynlen(output); i++)
		{
		dynInsertAt(formatted_out[i], dpTypeName(formatted_out[i][1]), 2);	
		}

	//insert the headers
	headers[1] = header_comment + "\nElementName";
	headers[2] = "TypeName";
	dynAppend(headers, config_list_dyn);
	formatted_out[1] = headers;

	return formatted_out;
	}
else
	{
	DebugN("invalid config supplied");
	return formatted_out;
	}
}

//######################## Generate values for system attributes ########################
dyn_dyn_string sgExporter_generateValuesForSystemAttributes(string system_name, dyn_string attributes, string header_comment, dyn_string dpelist = makeDynString("empty"), bool test_empty = true)
//this does basically the same thing as "QueryFormatAndReturnSystemConfValues", but
//it can handle the configs that the dpQuery cannot. However, it is much slower because of a repeated dpGet.
{
dyn_string full_get_list, get_list, heads;
dyn_anytype getres;
dyn_dyn_string output_table;

if ((system_name == "*") && (dynlen(dpelist) == 0))//if the system name is the whole database and there are no dpes specified
	{
	dpelist = dpNames("*");//the dpelist is all the primary dp-names
	}
else if ((dynlen(dpelist) == 0) || (dpelist[1] == "empty")) //if there are just no dpes specified
	{
	dpelist = sgExporter_getListOfDPEsForSystem(system_name); //get the dpe list for the system
	}
/*else
	{
	dpelist = dpelist;
	}
*/

if (test_empty) //if testing for empty attributes is enabled
	{
	dyn_string item_list = sgExporter_concatToEveryElement(dpelist, makeDynString(":"+attributes[1])); //make a list of points with attributes to check
	
	dpGet(item_list, getres); //get the values for these points
	
	//append only those points where the attribute selected is non-null
	for (int i = 1; i <= dynlen(item_list); i++)
		{
		if (getres[i] != 0)
			{
			dynAppend(full_get_list, dpelist[i]);
			}
		}
	}
else	//otherwise accept all dpes
	{
	for (int i = 1; i <= dynlen(dpelist); i++)
		{
		dynAppend(full_get_list, dpelist[i]);
		}
	}
//here, full_get_list contains a list of dps that we are interested in

get_list = sgExporter_concatToEveryElement(sgExporter_concatToEveryElement(full_get_list, makeDynString(":")), attributes); //get a list containing attributes too

if (test_empty) //if test-empty is enabled, we know that all the dps are valid, so we can go get them all in 1 go (faster)
	{
	dpGet(get_list, getres);
	}
else //otherwise we have to get them individually (rather slow, but works every time- dpQuery does not work with all attributes, dpGet does not work on multiple get when attributes are specified).
	{
	for (int n = 1; n <= dynlen(get_list); n++)
		{
		anytype blah;
		dpGet(get_list[n], blah);
		getres[n] = blah;		
		}
	}

for (int x = 1; x <= dynlen(full_get_list); x++) //for every dp
	{
	//insert the name and type data
	output_table[x+1][1] = sgExporter_trimProjectName(full_get_list[x]);
	output_table[x+1][2] = dpTypeName(full_get_list[x]);	
	for (int y = 1; y <= dynlen(attributes); y++) //and for every attribute, insert its data
		{
		output_table[x+1][y+2] = sgExporter_formatValueForOutput(getres[((x-1)*(dynlen(attributes))) + y]);
		}
	}

//insert headers
heads = makeDynString(header_comment+"\nElementName", "TypeName");
dynAppend(heads, attributes);
output_table[1] = heads;

return output_table;
}


//######################## generate peripheral address values for system ########################
dyn_dyn_string sgExporter_generatePeriphAddressValuesForSystem(string system_name)
//uses the generic generate values with the constants to get the peripheral address values
{
dyn_string periph_heads;
dyn_string address_fields = sgExporter_attribsListForExportConfig("_address", true, periph_heads);
																			 
return sgExporter_generateValuesForSystemAttributes(system_name, address_fields, periph_heads);
}

//######################## generate datapoint function values for system ########################
dyn_dyn_string sgExporter_generateDPFunctionValuesForSystem(string system_name)
//uses the generic dpquery to get the values for the dpfunction attributes
{
const string dp_function_prefix = "_dp_fct";
dyn_string fct_heads;
dyn_string fct_attribs = sgExporter_attribsListForExportConfig(dp_function_prefix, false, fct_heads);													 
return sgExporter_QueryFormatAndReturnSystemConfValues(system_name, dp_function_prefix, fct_heads, fct_attribs);

}
//######################## generate alert class values for database ########################
dyn_dyn_string sgExporter_generateAlertClassValuesForDatabase()
//uses the dpquery to get alert class values for the whole database
{
const string alert_class_prefix = "_alert_class";
dyn_string al_heads;
dyn_string al_class_attribs = sgExporter_attribsListForExportConfig(dp_function_prefix, true, al_heads);		
																					 
return sgExporter_QueryFormatAndReturnSystemConfValues("*", alert_class_prefix, al_heads, al_class_attribs, "_DPT= \"_AlertClass\"");
}

//######################## generate the archive settings values for database ########################
dyn_dyn_string sgExporter_generateArchiveValuesForDatabase(float progress_low, float progress_high, shape progress_bar)
{
//the parameters are for implementation of a progress bar. this helps visibility because it's so slow
//without a progress bar it could look as if this export had crashed

//something that should be easy, but isn't at all - because of _archive not being available in dpQuery
//and elements having details.
//this procedure is quite slow to execute.

/*
there seems to be no easy way to get the list of data-points with archive information
from the database quickly. Therefore, I generate a list of all the points in the DB,
scan through every DPE seeing if it has an archive value set. It is impossible to do 
a dpGet on all the elements (>49,000) in one go, it is also impractically slow 
(~2 1/2 hours) to do a dpGet on each point individually. For speed therefore, I do a dpGet
on 1000 elements at a time, which takes a relatively resonable (<1 min) length of time.
*/
const string ARCHIVE_CONFIG_NAME = "_archive";
string levelstring = "*";
int pnum = 1;
int getcount = 0;
int end_num = 0;
int increment_stage = 1000; //quick tests of this value between 500 and 2000 shows 1000 is Markedly quicker than any of the others!
float progress_step = (progress_high - progress_low)/dynlen(all_dpes);

dyn_string all_dpes, single_level_dpes, arc_dps, header_line;
dyn_anytype get_result;
dyn_dyn_string out_format;
dyn_dyn_anytype uf_config_data;

dyn_string arch_attribs = sgExporter_attribsListForExportConfig(ARCHIVE_CONFIG_NAME, true, header_line);		

//iterate through each level of the db (*, *.*, *.*.* ...) getting all the points there
do
	{
	single_level_dpes = dpNames(levelstring);
	pnum = dynlen(single_level_dpes);
	dynAppend(all_dpes, single_level_dpes);	
	levelstring = levelstring + ".*";
	}
while (pnum > 0);

//select 1000 of the elements, do a dpGet, and see if those elements have an archive config
do
	{
	dyn_string lil_get; //lil_get is the list of 1000 dpes to get at once (littler than 49k!)
	
	//what is the last number to get (last time through test, because last time through will not be exactly 1000
	if ((getcount < dynlen(all_dpes)) && ((getcount+increment_stage) < dynlen(all_dpes)))
		{
		end_num = increment_stage-1;
		}
	else
		{
		end_num = dynlen(all_dpes) - getcount;
		}
	
	//make the list of dpes to get
	for (int q = 1; q <= end_num; q++)
		{
		if (dpExists(all_dpes[getcount + q]+":"+arch_attribs[1]))
			{
			dynAppend(lil_get, all_dpes[getcount + q]+":"+arch_attribs[1]);
			}
		}	

	//do the dpGet on at most 1000 elements
	dpGet(lil_get, get_result);
	
	//update the progress bar, have to do it here because its so slow it would look as if it had crashed!
	progress_bar.Value = progress_low + (progress_step * getcount);
	
	//scan through the result and see if any have archive configs
	for (int x = 1; x <= dynlen(lil_get); x++)
		{
		if (get_result[x] != 0) //if there are any, append them to a list
			{
			dynAppend(arc_dps, lil_get[x]);
			}
		}
	getcount = getcount + increment_stage; //increment 'get-count', the base counter
	}
while (getcount <= dynlen(all_dpes)); //loop. using a do-while so it does it once at least, and becase a for too inflexible

//with the resulting points, they have system:dpname:configname, so need to strip out just the dpname
for (int i = 1; i<= dynlen(arc_dps); i++)
	{
	dyn_string tempstr = strsplit(arc_dps[i], ":");
	arc_dps[i] = tempstr[2];
	}

//here, arc_dps contains the list of points that have archive configs! now to go get them.
uf_config_data = sgExporter_getConfigsWithDetailsUnformatted(arc_dps, arch_attribs, ARCHIVE_CONFIG_NAME);

for (int x = 1; x <= dynlen(uf_config_data); x++) //for every bit of data
	{	
	for (int y = 1; y <= (dynlen(arch_attribs)+3); y++)  //for every attribute
		{
		if (y > 3)
			{
			out_format[x+1][y] = sgExporter_formatValueForOutput(uf_config_data[x][y]); //format the attribute data
			}
		else
			{
			out_format[x+1][y] = uf_config_data[x][y]; //just copy the element name and type data
			}
		}
	}

//attach headers
//header_line = makeDynString("# DbArchiveInfo\nElementName", "TypeName", "DetailNr");
dynAppend(header_line, arch_attribs);
out_format[1] = header_line;

return out_format;
}


//######################## Append Part ########################
void sgExporter_appendPart(dyn_dyn_string &SysAcc, dyn_dyn_string single_part_export, bool add_empty_line = true)
//this attaches the exports of each different part together
//if there are only headers output (so no useful information), nothing is appended
//the bool defines whether to insert an empty line or not
{
if (dynlen(single_part_export) > 1) //if there are only headers
	{
	if (add_empty_line)
		{
		dyn_dyn_string empty_line;
		empty_line[1] = makeDynString("");
		sgExporter_dynDynAppend(SysAcc, empty_line);
		}
	sgExporter_dynDynAppend(SysAcc, single_part_export);
	}
}

//######################## get configs with details unformatted ########################
dyn_dyn_anytype sgExporter_getConfigsWithDetailsUnformatted(dyn_string dpe_list, dyn_string attribs, string config_name)
{
/*
generic for getting configs with details. a little complicated because each type with details has different consts.
takes a list of dpes that have details associated with them,
a list of configs to get
and the config name (to decide which consts to use);
*/
dyn_dyn_anytype output_table;

if (dynlen(dpe_list) > 0)
{
	dyn_anytype detail_base_constant, detail_constant;
	string config_attribute;		
	dyn_string get_list;
	dyn_anytype result_list;
	
	int dpe_index = 1;
	int to_get_index = 1;
	const int dpe_name_column = 1;
	const int dpe_type_column = 2;
	const int detail_num_column = 3;
	
	if (config_name == "_alert_hdl")
		{
		detail_base_constant = makeDynAnytype(DPCONFIG_ALERT_NONBINARYSIGNAL);
		detail_constant = makeDynAnytype(DPDETAIL_RANGETYPE_MINMAX);
		config_attribute = "type";
		}
	else if (config_name == "_archive")
		{
		detail_base_constant = makeDynAnytype(DPCONFIG_DB_ARCHIVEINFO);
		detail_constant = makeDynAnytype(DPATTR_ARCH_PROC_SIMPLESM, DPATTR_ARCH_PROC_VALARCH);
		config_attribute = "type";
		}
	else if (config_name == "_cmd_conv")
		{
		detail_base_constant = makeDynAnytype(DPCONFIG_CONVERSION_ING_TO_RAW_MAIN, DPCONFIG_CONVERSION_ENG_TO_RAW_MAIN);
		detail_constant = makeDynAnytype(
																 		 DPDETAIL_CONV_LIN_INT,
																 		 DPDETAIL_CONV_LOG,
																 		 DPDETAIL_CONV_POLY,
																 		 DPDETAIL_CONV_PREC,
																 		 DPDETAIL_CONV_NULL_SUPP,
																 		 DPDETAIL_CONV_TRIGGER,
																 		 DPDETAIL_CONV_COUNTER,
																 		 DPDETAIL_CONV_INVERT	
																 		);
		config_attribute = "type";
		}
	else
		{
		DebugN("in getConfigsWithDetailsUnformatted, unrecognised config type supplied:", config_name);
		}

	//here, dpe_list contains the list of points that have configs. now to go get them.

	//because elements can have details, find details if any
	do //using a do-while loop because a for loop is too inflexible, as the number of output items is unknown
		{
		dyn_string dpnamespl = strsplit(sgExporter_trimProjectName(dpe_list[dpe_index]), ":");
		string dpname = dpnamespl[1];
		output_table[to_get_index][dpe_name_column] = dpname;
		output_table[to_get_index][dpe_type_column] = dpTypeName(dpname);	//system type
		output_table[to_get_index][detail_num_column] = ""; //if it isnt a detail, it won't have a detail num		
		int DetNumInt = sgExporter_getDetailNumber(dpname, config_name, config_attribute, detail_base_constant, detail_constant); //get the number of details for this point
		
		if (DetNumInt != 0)	//if this point has details
			{
			for (int p = 1; p <= DetNumInt; p++)	//loop through adding all the info necessary
				{
				to_get_index++;
				output_table[to_get_index][dpe_name_column] = sgExporter_trimProjectName(dpe_list[dpe_index]);
				output_table[to_get_index][dpe_type_column] = dpTypeName(dpe_list[dpe_index]);
				output_table[to_get_index][detail_num_column] = p; //especially the index number of the detail
				}
			}
		to_get_index++;
		dpe_index++;
		}
	while (dpe_index <= dynlen(dpe_list));//end of the do-while loop

	for (int x = 1; x <= dynlen(output_table); x++)
		{
		for (int y = 1; y <= dynlen(attribs); y++)
			{			
			dyn_string split_attrib = strsplit(attribs[y], ".");
			string get_string = output_table[x][dpe_name_column]+":"+split_attrib[1]+"."+output_table[x][detail_num_column]+"."+split_attrib[3];
			anytype getres;
			
			dpGet(get_string, getres); //can't do a multi-get for details :( - so this bit is slow
			
			output_table[x][y+detail_num_column] = getres;
			}
		}	
	}

//headers are inserted in the calling function

return output_table;

}
//######################## generate command conversion values for system ########################
dyn_dyn_string sgExporter_generateCommandConvValuesForSystem(string system_name)
//gets the command conversion values for a named system, outputs formatted like the ascii manager
{
string com_conv_config_name = "_cmd_conv";
dyn_string dpelist, full_get_list, item_list, headers;
dyn_anytype getres;
dyn_dyn_string format_out;
dyn_dyn_anytype data;
dyn_string command_conv_attribs = sgExporter_attribsListForExportConfig(com_conv_config_name, true, headers);

//check to see if any are empty - getConfigsWithDetailsUnformatted does not
dpelist = sgExporter_getListOfDPEsForSystem(system_name); //get list of dpes
item_list = sgExporter_concatToEveryElement(dpelist, makeDynString(":"+command_conv_attribs[1])); //make multi-get list
//headers = makeDynString("# DpConvIngToRawMain\nElementName", "ElementType", "DetailNr");


dpGet(item_list, getres);

for (int i = 1; i <= dynlen(item_list); i++) //traverse the list appending those that are not empty
	{
	if (getres[i] != 0)
		{
		dynAppend(full_get_list, dpelist[i]);
		}
	}
//get the details and their data
data = sgExporter_getConfigsWithDetailsUnformatted(full_get_list, command_conv_attribs, com_conv_config_name);

//format the attribute output, just copy the dpnames and types
for (int x = 1; x <= dynlen(data); x++)
	{	
	for (int y = 1; y <= (dynlen(command_conv_attribs)+3); y++)
		{
		if (y > 3)
			{
			format_out[x+1][y] = sgExporter_formatValueForOutput(data[x][y]);
			}
		else
			{
			format_out[x+1][y] = data[x][y];
			}
		}
	}

//insert headers
dynAppend(headers, command_conv_attribs);
format_out[1] = headers;

return format_out;
}

//######################## export full system ########################
void sgExporter_ExportFullSystem(string system_name, string export_folder_path, string export_config_file_path, dyn_string parts_to_export, shape ProgressBar, shape StatusText, mapping export_kinds_map)
//this calls all the routines necessary to export a complete system
{
const string SNMP_DEP_NAME = "SNMP";
const string OPC_CLIENT_DEP_NAME = "OPCCLIENT";
const string OUTPUT_FILE_EXTENSTION = ".dpl";
const string exporting_text_prefix = "Exporting ";
const string EXPORT_FILE_HEADER = "# ascii dump of database";

string kind_string;
bool exporting_dependencies;
dyn_string dependent_dp_names, names2;
dyn_dyn_string full_system_export, single_part_export, dependent_dp_values, values2;

ProgressBar.Value = 0.0;
full_system_export[1] = makeDynString(EXPORT_FILE_HEADER); //insert the first line

//decide if dependencies are being exported, if so, get the points concerned for SNMP and OPCCLIENT types
kind_string = mappingGetKey(export_kinds_map,5);
exporting_dependencies = dynContains(parts_to_export, kind_string);
if (exporting_dependencies)
	{
	ProgressBar.Value = 5.0;
	StatusText.text = "Scanning " + system_name +" for "+ kind_string;
	dependent_dp_values = sgExporter_generateDependenciesForSystem(system_name, SNMP_DEP_NAME, dependent_dp_names);
	ProgressBar.Value = 7.5;
	values2 = sgExporter_generateDependenciesForSystem(system_name, OPC_CLIENT_DEP_NAME, names2);
	sgExporter_dynDynAppend(dependent_dp_values, values2);
	dynAppend(dependent_dp_names, names2);
	}

	kind_string = mappingGetKey(export_kinds_map,1); //export type structure
if (dynContains(parts_to_export, kind_string))
	{
	ProgressBar.Value = 10.0;
	StatusText.text = exporting_text_prefix + system_name +" "+ kind_string;
	sgExporter_appendPart(full_system_export, sgExporter_generateTypeStructureForSystem(system_name));
	}
kind_string = mappingGetKey(export_kinds_map,2); //dp names
if (dynContains(parts_to_export,kind_string))
	{
	ProgressBar.Value = 20.0;
	StatusText.text = exporting_text_prefix + system_name +" "+ kind_string;
	sgExporter_appendPart(full_system_export, sgExporter_generateDPsForSystem(system_name, dependent_dp_names));
	}
kind_string = mappingGetKey(export_kinds_map,3); //aliases and comments
if (dynContains(parts_to_export, kind_string))
	{
	ProgressBar.Value = 30.0;
	StatusText.text = exporting_text_prefix + system_name +" "+ kind_string;
	sgExporter_appendPart(full_system_export, sgExporter_generateAliasesCommentsForSystem(system_name));
	}
kind_string = mappingGetKey(export_kinds_map,4); //dp values (adding in the dependent names calculated above
if (dynContains(parts_to_export, kind_string))
	{
	ProgressBar.Value = 40.0;
	StatusText.text = exporting_text_prefix + system_name +" "+ kind_string;
	sgExporter_appendPart(full_system_export, sgExporter_generateDPValuesForSystem(system_name, export_config_file_path));
	sgExporter_appendPart(full_system_export, dependent_dp_values, false);
	}
kind_string = mappingGetKey(export_kinds_map,6); //alert handling configs
if (dynContains(parts_to_export, kind_string))
	{
	ProgressBar.Value = 50.0; 
	StatusText.text = exporting_text_prefix + system_name +" "+ kind_string;
	sgExporter_appendPart(full_system_export, sgExporter_generateAlertValuesForSystem(system_name));
	}
kind_string = mappingGetKey(export_kinds_map,7); //distribution configs
if (dynContains(parts_to_export, kind_string))
	{
	ProgressBar.Value = 60.0;
	StatusText.text = exporting_text_prefix + system_name +" "+ kind_string;
	sgExporter_appendPart(full_system_export, sgExporter_generateDistribValuesForSystem(system_name));
	}
kind_string = mappingGetKey(export_kinds_map,8); //dp function configs
if (dynContains(parts_to_export, kind_string))
	{
	ProgressBar.Value = 70.0; 
	StatusText.text = exporting_text_prefix + system_name +" "+ kind_string;
	sgExporter_appendPart(full_system_export, sgExporter_generateDPFunctionValuesForSystem(system_name));
	}
kind_string = mappingGetKey(export_kinds_map,9); //perpheral address configs
if (dynContains(parts_to_export, kind_string))
	{
	ProgressBar.Value = 80.0; 
	StatusText.text = exporting_text_prefix + system_name +" "+ kind_string;
	sgExporter_appendPart(full_system_export, sgExporter_generatePeriphAddressValuesForSystem(system_name));
	}
kind_string = mappingGetKey(export_kinds_map,10); //command conversion configs
if (dynContains(parts_to_export, kind_string))
	{
	ProgressBar.Value = 90.0; 
	StatusText.text = exporting_text_prefix + system_name +" "+ kind_string;
	sgExporter_appendPart(full_system_export, sgExporter_generateCommandConvValuesForSystem(system_name));
	}

sgExporter_writeDynDynStringToTextFile(full_system_export, export_folder_path + "/" + system_name + OUTPUT_FILE_EXTENSTION);
StatusText.text = "";
ProgressBar.Value = 100.0;
}

//######################## generate dependencies for system ########################
dyn_dyn_string sgExporter_generateDependenciesForSystem(string system_name, string DependencyName, dyn_string &dp_names)
//this generates the values for dependent points, currently only SNMP and OPCCLIENT kinds
{
const string PVSS_BASE_TIME = "01.01.1970 00:00:00.000";
const string SNMP_DP_PREFIX = "_1_SNMPAgent_";
const string OPC_DP_PREFIX = "_";
const string SNMP_DEP_NAME = "SNMP";
const string OPC_CLIENT_DEP_NAME = "OPCCLIENT";

string dp_prefix, stripped, ref_str, this_type_name;
int drv_id_index, ref_index;
mapping scanned_types;
dyn_string points, dep_dp_names, address_attribs, dp_paths, dp_elements, dpvattribs, null_headers;
dyn_dyn_string dependent_dp_data, final_data, type_elements, ad_out, temporary;

dpvattribs = sgExporter_attribsListForExportConfig("_original", true, null_headers);

//create the list of attributes to get
address_attribs = sgExporter_attribsListForExportConfig("_address", true, null_headers);

//get the values for all these attributes
ad_out = sgExporter_generateValuesForSystemAttributes(system_name, address_attribs, "");

//find which column corresponds to the attributes desired
drv_id_index = dynContains(ad_out[1], "_address.._drv_ident");
ref_index = dynContains(ad_out[1], "_address.._reference");

// loop through the output values, ignoring the first (comments) line
for (int data_index = 1; data_index < dynlen(ad_out); data_index++)
	{
	stripped = ad_out[data_index+1][drv_id_index];
	strreplace(stripped, "\"", "");//remove the quotes from the formatted string
	ref_str = ad_out[data_index+1][ref_index];
	strreplace(ref_str, "\"", "");//remove quotes
 	if ((stripped == SNMP_DEP_NAME) && (DependencyName == SNMP_DEP_NAME)) //if the driver identifier is SNMP
		{
		dyn_string agent_id_dyn = strsplit(ref_str, "_");//format is agentID_address, just want ID.
		dynAppend(points, agent_id_dyn[1]); //add the snmp agent id to a list
		}
	else if ((stripped == OPC_CLIENT_DEP_NAME) && (DependencyName == OPC_CLIENT_DEP_NAME))
		{
		dyn_string client_name_dyn = strsplit(ref_str, "$");
		dynAppend(points, client_name_dyn[1]);
		dynAppend(points, client_name_dyn[2]);
		}
	}

dynSortAsc(points); //sort this list
dynUnique(points);	//remove any duplicate elements

if (dynlen(points) > 0)
	{
	//prepend the data point prefix corresponding to the type
	if (DependencyName == SNMP_DEP_NAME)
		{
		dp_prefix = SNMP_DP_PREFIX;
		}
	else if (DependencyName == OPC_CLIENT_DEP_NAME)
		{
		dp_prefix = OPC_DP_PREFIX;
		}
	for (int p = 1; p<= dynlen(points); p++)
		{
		dep_dp_names[p] = dp_prefix + points[p];	
		}
	
	dp_names = dep_dp_names; //this returns the dp_names calculated through thr reference variable
	
	//we now have the list of datapoints to get data for
	//so we need to get the data
	
	//in case there is more than one type to get - i don't want to getting the type structure for each point,
	//which would be very innefficient - use a mapping scheme to speed it up
	//generate the mapping
	for (int k = 1; k<=dynlen(dep_dp_names); k++)
		{
		string this_type_name = dpTypeName(dep_dp_names[k]);
		if (!(dynContains(mappingKeys(scanned_types), this_type_name)))
			{
			scanned_types[this_type_name] = dynlen(mappingKeys(scanned_types))+1;
			type_elements[scanned_types[this_type_name]] = sgExporter_ElementListForType(this_type_name);			
			}
		}

	//make a list of dp elements for the snmp type	
	for (int i = 1; i<= dynlen(dep_dp_names); i++)
		{
		dp_elements = type_elements[scanned_types[dpTypeName(dep_dp_names[i])]];
		for (int j = 1; j<= dynlen(dp_elements); j++)
			{
			dynAppend(dp_paths, dep_dp_names[i]+"."+dp_elements[j]);		
			}	
		}
	
	//create a list of all full DPE paths
	//use the generic getting and formatting procedure
	dependent_dp_data = sgExporter_generateValuesForSystemAttributes(system_name, dpvattribs, "", dp_paths, false);
	
	//ignore the first comment line, then take only the points that have been modified (remove points with date changed 1970)
	for (int line = 2; line <= dynlen(dependent_dp_data); line++)
		{
		if (dependent_dp_data[line][5] != PVSS_BASE_TIME)
			{
			temporary[1] = dependent_dp_data[line];		
			sgExporter_dynDynAppend(final_data, temporary);
			}
		}
	return final_data;	
	}
else //there are no points to export - so return empty values
	{
	dyn_string empty1;
	dyn_dyn_string empty2;
	dp_names = empty1;
	return empty2;
	}
}


//######################## generate type structures for all types ########################
dyn_dyn_string sgExporter_generateTypeStructuresForAllTypes()
//when doing a globals export, all type structures need to be exported.
// this returns all the type structures like the ascii manager
{
const string PVSS_INTERNAL_TYPE_PATTERN = "_*";
const string TYPE_STRUCT_HEADER = "# DpType\nTypeName";

dyn_string type_list = dpTypes();
dyn_dyn_string all_types_structures;

all_types_structures[1] = makeDynString(TYPE_STRUCT_HEADER); //insert header

for (int i = 1; i <= dynlen(type_list); i++) //for every type
	{
	if (!(patternMatch(PVSS_INTERNAL_TYPE_PATTERN, type_list[i]))) //only export non-internal types - pvss knows about its own types!
		{
		sgExporter_appendPart(all_types_structures, sgExporter_generateTypeStructureForSystem("", type_list[i]), false);		
		}
	}
return all_types_structures;
}

//######################## export globals ########################
void sgExporter_ExportGlobals(dyn_string global_names, string output_folder_path, shape ProgressBar, shape StatusText, mapping global_kinds_map)
{
const string export_global_prefix_text = "Exporting Global ";
const string EXPORT_FILE_HEADER = "# ascii dump of database";
const string SNMP_MANAGER_TYPE_NAME = "_SNMPManager";
const string UI_TYPE_NAME = "_Ui";
const string GLOBALS_OUT_FILE_NAME = "Globals";
const string OUTPUT_FILE_EXTENSTION = ".dpl";

string kind_string;
dyn_dyn_string globals_export;
dyn_string dpnames_list;



globals_export[1] = makeDynString(EXPORT_FILE_HEADER); //insert topmost header line

kind_string = mappingGetKey(global_kinds_map,1); //type structures
if (dynContains(global_names, kind_string))
	{
	ProgressBar.Value = 2.0; 
	StatusText.text = export_global_prefix_text + kind_string;
	sgExporter_appendPart(globals_export, sgExporter_generateTypeStructuresForAllTypes());
	}
kind_string = mappingGetKey(global_kinds_map,2); //dependent SNMP managers
if (dynContains(global_names, kind_string))
	{
	ProgressBar.Value = 4.0; 
	StatusText.text = export_global_prefix_text + kind_string;
	dynAppend(dpnames_list, dpNames("*", SNMP_MANAGER_TYPE_NAME));
	}
kind_string = mappingGetKey(global_kinds_map,3); //dependent UI points
if (dynContains(global_names, kind_string))
	{
	ProgressBar.Value = 6.0; 
	StatusText.text = export_global_prefix_text + kind_string;
	dynAppend(dpnames_list, dpNames("*", UI_TYPE_NAME));
	}
if (dynlen(dpnames_list) > 0)
	{
	sgExporter_appendPart(globals_export, sgExporter_generateDPNamesOutput(dpnames_list));	//SNMP and UI merge points
	}	
	
kind_string = mappingGetKey(global_kinds_map,4); // alert class values
if (dynContains(global_names, kind_string))
	{
	ProgressBar.Value = 8.0; 
	StatusText.text = export_global_prefix_text + kind_string;
	sgExporter_appendPart(globals_export, sgExporter_generateAlertClassValuesForDatabase());
	}
kind_string = mappingGetKey(global_kinds_map,5); //archive values
if (dynContains(global_names, kind_string))
	{
	ProgressBar.Value = 10.0; 
	StatusText.text = export_global_prefix_text + kind_string;
	sgExporter_appendPart(globals_export, sgExporter_generateArchiveValuesForDatabase(10.0, 98.0, ProgressBar));
	}
sgExporter_writeDynDynStringToTextFile(globals_export,  output_folder_path + "/" + GLOBALS_OUT_FILE_NAME + OUTPUT_FILE_EXTENSTION);
ProgressBar.Value = 100.0;
StatusText.text = "";
}

//######################## trim project name ########################
string sgExporter_trimProjectName(string full_datapoint_name)
//trims the project name off a dp name string that contains it
{
string this_project_name = getSystemName();
if (patternMatch(this_project_name+"*", full_datapoint_name))
	{
	return substr(full_datapoint_name, strlen(this_project_name)); //really strlen(this_project_name+":") -1 == strlen(this_project_name)
	}
else
	{
	return full_datapoint_name;
	}
}



//end sgExporterLib

