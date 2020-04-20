
global dyn_string validation_error_list;
global dyn_dyn_bool AETableAlarmEnable;
global dyn_dyn_string AETableAlarmSeverity, AETableAlarmAction;
global dyn_string states;

int sgEditPanel_SaveData(dyn_string data_points, dyn_string data_point_elements, dyn_anytype dpe_values, dyn_bool changed_elements)
{
int x;
dyn_anytype empty;
dyn_dyn_anytype to_write;
to_write[1] = empty;
to_write[2] = empty;

for (int i = 1; i<= dynlen(data_points); i++)
	{
	for (int j = 1; j<= dynlen(data_point_elements); j++)
		{
		if (changed_elements[j])
			{
			dynAppend(to_write[1], (data_points[i] + data_point_elements[j]));
			x = dynlen(to_write[2])+1;
			to_write[2][x] = dpe_values[j];
			}
		}
	}
//DebugN("writing back: ");

//DebugN("to write:", to_write);

dyn_string writenames = to_write[1];

if (dynlen(writenames) > 0)
	{
	//DebugN("dpSetting", writenames, to_write[2]);
  dpSet(writenames, to_write[2]); //set the new data back into the database. 
	}
//else
//	{
//	DebugN("nothing changed so nothing to save");
//	}

return 1;// to force this script to execute on panel terminate - without a return value it doesn't run!
}

dyn_anytype sgEditPanel_LoadData(string data_points, dyn_string data_point_elements)
{
string dp_to_load;
dyn_anytype dp_data;
dyn_string data_points_split = strsplit(data_points, ";");
dyn_string dpe_names;

dp_to_load = data_points_split[1];

for (int i = 1; i<= dynlen(data_point_elements); i++)
	{
	dpe_names[i] = dp_to_load + data_point_elements[i];
	}
//DebugN(dpe_names);
dpGet(dpe_names, dp_data);
//DebugN(dp_data);
return dp_data;

}


void sgEditPanel_SetValidationErrorList(dyn_string error_list)
{
validation_error_list = error_list;
}

dyn_string sgEditPanel_GetValidationErrorList()
{
return validation_error_list;
}

void sgEditPanel_AETable_init_states()
{
states = makeDynString("OPS",
  																"SBY",
																	"INI",
																	"DEG",
																	"U/S",
																	"TEC",
																	"WIP",
																	"ABS",
																	"STP",
																	"UKN"
																 );
}

int state_index(string state)
{
sgEditPanel_AETable_init_states();
return dynContains(states, state);
}


void sgEditPanel_AETableValueSet(string OldState, string NewState, bool Enabled, string Severity, string Action)
{
int x = state_index(OldState);
int y = state_index(NewState);

AETableAlarmEnable[x][y] = Enabled;

if (Enabled)
	{
	AETableAlarmSeverity[x][y] = Severity;
	AETableAlarmAction[x][y] = Action;
	}
else
	{
	AETableAlarmSeverity[x][y] = "";
	AETableAlarmAction[x][y] = "";
	}
}

dyn_string sgEditPanel_AETableValueGet(string OldState, string NewState)
{
dyn_string result;

result[1] = AETableAlarmEnable[state_index(OldState)][state_index(NewState)];
if (result[1])
	{
	result[2] = AETableAlarmSeverity[state_index(OldState)][state_index(NewState)];
	result[3] = AETableAlarmAction[state_index(OldState)][state_index(NewState)];
	}
else
	{
	result[2] = "";
	result[3] = "";
	}
return result;
}



void sgEditPanel_AETableFill(string AETableData)
{
dyn_string transitions = strsplit(AETableData, ";");
sgEditPanel_AETable_init_states();
//DebugN(transitions);
int ActionInt;
string OldState, NewState, Severity, Action;
dyn_string splitValue;
dyn_string Actions = makeDynString("Remove", "Create", "Re-Create");


for (int x = 1; x<=dynlen(states);x++)
	{
	for (int y = 1; y<=dynlen(states);y++)
		{
		AETableAlarmEnable[x][y] = false;
		}
	}	

for (int i = 1; i<=dynlen(transitions);i++)
	{
	splitValue = strsplit(transitions[i], ":");
	OldState = substr(splitValue[1], 0, 3);
	NewState = substr(splitValue[1], 3, 3);
	Severity = splitValue[2];
	ActionInt = substr(splitValue[3], (strlen(splitValue[3])-1), 1);
	Severity = substr(Severity, 0, 1) + strtolower(substr(Severity, 1, (strlen(Severity)-1)));
	Action = Actions[ActionInt+1];
//	DebugN(transitions[i], OldState, NewState, Severity, Action);
	sgEditPanel_AETableValueSet(OldState, NewState, true, Severity, Action);
	}
}

string sgEditPanel_AETableValue()
{
string result, temp_result;
dyn_string Actions = makeDynString("Remove", "Create", "Re-Create");

sgEditPanel_AETable_init_states();

DebugN(states, AEAlarmTableSeverity, Actions, AETableAlarmAction);


for (int x = 1; x<=dynlen(states);x++)
	{
	for (int y = 1; y<=dynlen(states);y++)
		{
		temp_result = "";
		if (AETableAlarmEnable[x][y])
			//if the alarm is enabled, append it to the list of alarms in the correct format
			{
			temp_result = states[x] + states[y] + ":";
			temp_result = temp_result + strformat("\\fill{%9.0}", 9, (strtoupper(AETableAlarmSeverity[x][y])+":") );
			temp_result = temp_result + "-" + (dynContains(Actions, AETableAlarmAction[x][y])-1);
			result = result + temp_result + ";";
			}
		}	
	}

return result;

}

