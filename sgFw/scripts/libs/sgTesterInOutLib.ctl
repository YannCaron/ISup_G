/*
sgTesterInOutLib.ctl
A library of functions for the panels used to create test scripts and interpret their results, respectively LogicGenerator and TestResultsDisplayer

Version History
Created 28/09/2006 by Andrew Burkimsher
*/

//########################## Permutations Of ##########################
dyn_dyn_string sgTester_PermutationsOf(int num_variables, dyn_string &states)
//this returns all the permutations of the supplied 'states', to the number of variables.
//#states P num_variables - evaluated.
//it uses recursion
{
const int MAX_ALLOWED_PERMUTATIONS = 65536; //I chose this number because it is the maximum number of lines Excel can support in a table
																						//this is handy because it will be helpful to sometimes export things to Excel
float num_perms;
dyn_string curr_state_set;
dyn_dyn_string result, sub_states;

//in order that we never overload the computer, I calculate the number of states
// that would be generated if this script were to run
num_perms = pow(dynlen(states), num_variables); 

if (num_perms < MAX_ALLOWED_PERMUTATIONS)
	{
	if (num_variables == 1) //terminating case, when there is only 1 variable left - return all the states it could take
		{
		for (int i = 1; i<= dynlen(states); i++) //fill the first column of the result with the states
			{
			result[i][1] = states[i];
			}
		}
	else //recursive case, append recursed value to each possible state so far
		{
		sub_states = sgTester_PermutationsOf(num_variables-1, states);
		
		for (int i = 1; i <= dynlen(states); i++) //for all the state
			{
			for (int j = 1; j<=dynlen(sub_states); j++) //append each of the sub-states to it
				{
				curr_state_set = sub_states[j];
				dynInsertAt(curr_state_set, states[i], 1);
				result[((i-1)*dynlen(sub_states))+j] = curr_state_set;
				}	
			}
		}
	}
else //there would be too many permutations - probably causing the computer to crawl. but in testing - why do you want this many tests anyway!?!
	{
	DebugN("too large a request for PermuationsOf - there would be " + num_perms + " results!");
	}
return result;
}

//########################## State to color ##########################
string sgTester_StateToColor(string state)
//this takes one of the predefined states and outputs the name of the colour associated with this state
{
string output;

		 if (state == "OPS") output = "sgStdOPSColor";
else if (state == "SBY") output = "sgStdSBYColor";
else if (state == "SSB") output = "sgStdSSBColor";
else if (state == "INI") output = "sgStdINIColor";
else if (state == "DEG") output = "sgStdDEGColor";
else if (state == "U/S") output = "sgStdU/SColor";
else if (state == "TEC") output = "sgStdTECColor";
else if (state == "WIP") output = "sgStdWIPColor";
else if (state == "ABS") output = "sgStdABSColor"; 
else if (state == "STP") output = "sgStdSTPColor"; 
else if (state == "UKN") output = "sgStdUKNColor";
else if ((state == "") || (state == " ")) output = "{240,244,251}";
else if (state == "[undefined]") output = "White";
else output = "_3DFace";

return output;
}

//########################## state to html color ##########################
string sgTester_StateToHTMLColor(string state)
//this takes one of the predefined states and outputs the html representation of the colour associated with this state
{
string output;

		 if (state == "OPS") output = "<bgcolor=#66CC00>";
else if (state == "SBY") output = "<bgcolor=#FFFFFF>";
else if (state == "INI") output = "<bgcolor=#747474>";
else if (state == "DEG") output = "<bgcolor=#66FFFF>";
else if (state == "U/S") output = "<bgcolor=#3333FF>";
else if (state == "TEC") output = "<bgcolor=#99CCFF>";
else if (state == "WIP") output = "<bgcolor=#FF6633>";
else if (state == "ABS") output = "<bgcolor=#C8D0D4>"; 
else if (state == "STP") output = "<bgcolor=#996633>"; 
else if (state == "UKN") output = "<bgcolor=#FFCC66>";
else output = "";

return output;
}


//########################## Handle Patterns in inputs ##########################
void sgTester_HandlePatternsInInputs(shape InputsList, int num_inputs)
//this deals with the slightly complex problem of when there are patterns in inputs
//because patterns often evaluate to a huge number of things
//this would cause the truth table to become impossibly large
//this makes the patterns evaluate to the number of input states selected + 1
//so you have 1 of each possible input state, and all the rest the same.
{
int column_index;
dyn_string input_names, names_expanded, this_pattern_exp;

input_names = InputsList.items; //get the list of input names
input_names = sgTester_columnFromSplitList(input_names, " ", 2);

column_index = 1;
for (int i = 1; i <= dynlen(input_names); i++) //for all the inputs
	{
	if (strpos(input_names[i], "*") >= 0) //if the name contains a '*', hence it is a pattern
		{
		this_pattern_exp = dpNames(input_names[i]); //expand the pattern
		if (dynlen(this_pattern_exp) > num_inputs+1) //if there are more names than the number of inputs, do the special bit
			{
			dynAppend(names_expanded, input_names[i]); //insert only the pattern, without a number or an indent (just a title)
			dynAppend(names_expanded, "  " + column_index + ". " + input_names[i]+ " All other matches"); //insert all other matches as a string
			column_index++;
			for (int j =1 ; j<= num_inputs; j++) //insert the first lot of items 
				{
				dynAppend(names_expanded, "  " + column_index + ". " + sgExporter_trimProjectName(this_pattern_exp[j]));
				column_index++;
				}
			}
		else //the number of units the pattern evaluates to is fewer than the number of states + 1, so treat as normal (all the patterns included)
			{
			for (int j = 1; j<= dynlen(this_pattern_exp); j++) //insert all the patterns into the list, with the column number
				{
				this_pattern_exp[j] = "  " + column_index + ". " + sgExporter_trimProjectName(this_pattern_exp[j]);
				column_index++;
				}
			dynAppend(names_expanded, this_pattern_exp);
			}
		}
	else //the name does not contain a '*'
		{
		dynAppend(names_expanded, "  " + column_index + ". " + input_names[i]);
		column_index++;
		}
	}

InputsList.items = names_expanded;
}


//########################## column from split list ##########################
dyn_string sgTester_columnFromSplitList(dyn_string list, char split_char, int column_number)
//this splits every item in a list, and gets the item number from each split item.
{
dyn_string result, split_line;

for (int i = 1; i<=dynlen(list); i++)
	{
	split_line = strsplit(list[i], split_char);
	dynAppend(result, split_line[column_number]);
	}

return result;
}

//########################## Generate Tester Script ##########################
dyn_string sgTester_GenerateTesterScript(string dp_name, dyn_string logic_points, dyn_dyn_string table_data)
//from the inputs, generates a script to be passed to the TestScript utility
{
const string TIME_FORMAT = "%d/%m/%Y %H:%M";
const string FOR_START = "FOR_EACH";
const string FOR_END = "END_FOR_EACH";
const string DISABLED_CELL_VALUE = "[disabled]";
const string DISABLED_POINT_POSTFIX = ".Disabled";
const string TRUE_STRING = "TRUE";
const string FALSE_STRING = "FALSE";
const string SET_STRING = "SET";
const string CHECK_STRING = "CHECK";
const string STATUS_POSTFIX = ".Status";
const string VERBOSE_SETTING = "VERBOSE = NO_VERBOSE";

dyn_string text_output, spl;
dyn_bool is_logic_pattern;
string curr_time_string, disabled_path;
anytype disabled_state;

curr_time_string = formatTime(TIME_FORMAT, getCurrentTime()); //get the current time

for (int logic_index = 1; logic_index <= dynlen(logic_points); logic_index++)//find which test points are patterns (they are treated differently)
	{
	is_logic_pattern[logic_index] = (strpos(logic_points[logic_index], "*") >= 0);
	}

//append the header part
dynAppend(text_output, makeDynString("//Test script for "+dp_name, "//Generated automatically " + curr_time_string,"", VERBOSE_SETTING, ""));

//for every test line
for (int line_index = 1; line_index <= dynlen(table_data); line_index++)
	{
	dynAppend(text_output, "//Test Line " + line_index); //output a comment saying which line you are testing
	for (int cell_index = 1; cell_index <= dynlen(logic_points); cell_index++) //for each point to export
		{
		if ((is_logic_pattern[cell_index])) //if it is a pattern, put the set inside a for loop
			{
			dynAppend(text_output, FOR_START);
			} 
		
		if (table_data[line_index][cell_index+1] != DISABLED_CELL_VALUE) //if the cell is disabled
			{
			//check if it was disabled last time - if so, re-enable it again
			if (line_index > 1)
				{
				//generate the disabled point name
				spl = strsplit(logic_points[cell_index], ".");
				dynRemove(spl, dynlen(spl));
				disabled_path = ConcatDynStringWithChar(spl, ".") + DISABLED_POINT_POSTFIX;
				//do a reverse search to find its state last time
				disabled_state = sgTester_tableReverseSearch(dynlen(text_output), disabled_path, text_output);
				if (disabled_state == TRUE_STRING) //if it was disabled, enable it again
					{
					dynAppend(text_output, SET_STRING + " " + disabled_path + " " + FALSE_STRING);
					}
				}
			dynAppend(text_output, SET_STRING + " " + logic_points[cell_index] + " " + table_data[line_index][cell_index+1]); //output the set value
			}
		else //its a disabled line - disable the point
			{
			//generate the disabled point name
			spl = strsplit(logic_points[cell_index], ".");
			dynRemove(spl, dynlen(spl));
			disabled_path = ConcatDynStringWithChar(spl, ".") + DISABLED_POINT_POSTFIX;
			//search to see if it is already disabled
			disabled_state = sgTester_tableReverseSearch(dynlen(text_output), disabled_path, text_output);
			if (disabled_state != TRUE_STRING) //if it isn;t already disabled, disable it
				{
				dynAppend(text_output, SET_STRING + " " + disabled_path + " " + TRUE_STRING);
				}
			}
		if ((is_logic_pattern[cell_index]))//if it is a logic point, end the for loop, and indent the previous line
			{
			text_output[dynlen(text_output)] = "\t"+text_output[dynlen(text_output)];
			dynAppend(text_output, FOR_END);
			} 
		}
	//now each of the set points is done, insert the check point
	dynAppend(text_output, CHECK_STRING + " " + dp_name + STATUS_POSTFIX + " " + table_data[line_index][1]); 
	dynAppend(text_output, ""); //insert a blank line, helps readability
	}

return text_output; //output the script
}


//########################## table reverse search ##########################
anytype sgTester_tableReverseSearch(int start_searching_from, string search_string, dyn_string &table_data)
//reverse search the table, used in this panel for searching for whether points are disabled or not
{
const int DP_NAME_INDEX = 2;
const int VALUE_INDEX = 3;

anytype return_value;
int found_line_index = start_searching_from;
bool found = false;
dyn_string split_line;

while ((!found) && (found_line_index > 0))
	{
	split_line = strsplit(table_data[found_line_index], " ");
	if (dynlen(split_line) >=2)
		{
		if (search_string == split_line[DP_NAME_INDEX])
			{
			//line is found, say found + output value
			return_value = split_line[VALUE_INDEX];
			found = true;
			}
		else
			{
			//decrement and continue searching
			found_line_index--;
			}
		}
	else
		{
		//decrement and continue searching
		found_line_index--;
		}
	}
if (!found)
	{
	return_value = "[undefined]";
	}

return return_value;
}



