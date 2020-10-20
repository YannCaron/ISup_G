
// Modifications;
// 2006-09-14: PW added message initialization at fw restart in sgFwLoadSystems


// Constants
const string DBKEY_STATUS_DELAY    = "STATUS_DELAY";
const string DBKEY_EVENT_TEXT      = "EVENT_TEXT";
const string DBKEY_GENERATE_EVENTS = "GENERATE_EVENTS";
const string DBKEY_GENERATE_ALARMS = "GENERATE_ALARMS";
const string DKBEY_HISTORIES       = "HISTORIES";
const string DBKEY_AETABLE			   = "AETABLE";
const string DBKEY_TRUTH_TABLE     = "TRUTH_TABLE";
const string DBKEY_INPUTS          = "INPUTS";
const string DBKEY_PARENTS         = "PARENTS";

const string DBKEY_AETABLES 		 	 =  "AE_TABLES";
const string DBKEY_TRUTH_TABLES    =  "TRUTH_TABLES";

const string DBKEY_SYSTEMS_LIST      = "SYSTEMS_LIST";
const string DBKEY_PARENTS_LIST      = "PARENTS_LIST";

const string DBKEY_DELAYED_SYSTEMS   = "DELAYED_SYSTEMS";
const string DBKEY_BITSTATES_LIST 	 = "BITSTATES_LIST";
const string DBKEY_BITSTATE_IS_STATE = "IS_STATE";

const string DBKEY_ALARM_POINTS_TABLE = "Acknowledgeable alarm points table";
const string DBKEY_ACK_DATAPOINTS = "Acknowledgeable datapoints";

const string DBKEY_MODIFIED_PARENTS = "ModifiedParents";

// stats
int sgFw2ActualChangeCounter = 0;
int sgFw2SystemChangedCounter = 0;

int sgFw2ActualChangeOld = 0;
int sgFw2SystemChangedOld = 0;

string oldActiveChain;

// Functions

void sgFwStatsDisplay()
{
	int delta;
	DebugTN("==== sgFwStats ====");
	delta = sgFw2ActualChangeCounter - sgFw2ActualChangeOld;
	sgFw2ActualChangeOld = sgFw2ActualChangeCounter;
	DebugTN("  Actual change = " + sgFw2ActualChangeCounter + "(" + delta + ")");
	delta = sgFw2SystemChangedCounter - sgFw2SystemChangedOld;
	sgFw2SystemChangedOld = sgFw2SystemChangedCounter;
	DebugTN("  SystemChanged = " + sgFw2SystemChangedCounter + "(" + delta + ")");
	DebugTN("===================");
}

bool sgAELoadTables()
{
	bool b;
	b = sgDBCreateTable(DBKEY_AETABLES);
	if (!b)
	{
		sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "Unable to create the table 'DBKEY_AETABLES'");
		return false;
	}

	dyn_string tables;
	tables = getPointsOfType("sgAETable");

	for (int cpt = 1; cpt <= dynlen(tables); cpt++)
	{
		string table;
		dpGet(tables[cpt] + ".Table", table);

		b = sgDBSet(DBKEY_AETABLES, tables[cpt], table);
		if (!b)
		{
			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "Unable to create the key: " +  tables[cpt] + " for the table: " + DBKEY_AETABLES);
			return false;
		}
	}

	return true;
} // bool sgAELoadTables()

bool sgTTLoadTables()
{
	bool b;
	b = sgDBCreateTable(DBKEY_TRUTH_TABLES);
	if (!b)
	{
		sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "Unable to create the table " + DBKEY_TRUTH_TABLES);
		return false;
	}

	dyn_string tables;
	tables = getPointsOfType("sgFwTruthTable");

	for (int cpt = 1; cpt <= dynlen(tables); cpt++)
	{
		dyn_string table;
		dpGet(tables[cpt] + ".Table", table);

		b = sgDBSet(DBKEY_TRUTH_TABLES, tables[cpt], table);
		if (!b)
		{
			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "Unable to create the key: " +  tables[cpt] + " for the truth table table: " + DBKEY_AETABLES);
			return false;
		}
	}

	return true;
} // bool sgTTLoadTables()


bool sgFwLoadParams()
{
	bool b;

	dyn_string params;
	params = getPointsOfType("sgParams");

	for (int cpt = 1; cpt <= dynlen(params); cpt++)
	{
		b = sgDBCreateTable(params[cpt]);
		if (!b)
		{
			DebugN("sgFwLoadParams >> sgFwLoadParams >> Unable to create the table: " +  params[cpt]);
			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwLoadParams >> Unable to create the table: " +  params[cpt]);
			return false;
		}

		dyn_string histories;
		string aeTable;
		int delayTime;
		bool generateAlarms, generateEvents;

		dpGet(params[cpt] + ".Histories",     histories,
					params[cpt] + ".AETable",       aeTable,
					params[cpt] + ".Delay",         delayTime,
					params[cpt] + ".GenerateAlarms", generateAlarms,
					params[cpt] + ".GenerateEvents", generateEvents);

		b = sgDBSet(params[cpt], DKBEY_HISTORIES, histories);
		if (!b)
		{
			DebugN("sgFwLoadParams >> Unable to create the key: " +  DKBEY_HISTORIES + " for the table: " + params[cpt]);
			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwLoadParams >> Unable to create the key: " +  DKBEY_HISTORIES + " for the table: " + params[cpt]);
			return false;
		}

		b = sgDBSet(params[cpt], DBKEY_STATUS_DELAY, delayTime);
		if (!b)
		{
			DebugN("sgFwLoadParams >> Unable to create the key: " +  DBKEY_STATUS_DELAY + " for the table: " + params[cpt]);
			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwLoadParams >> Unable to create the key: " +  DBKEY_STATUS_DELAY + " for the table: " + params[cpt]);
			return false;
		}

		b = sgDBSet(params[cpt], DBKEY_GENERATE_ALARMS, generateAlarms);
		if (!b)
		{
			DebugN("sgFwLoadParams >> Unable to create the key: " +  DBKEY_GENERATE_ALARMS + " for the table: " + params[cpt]);
			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwLoadParams >> Unable to create the key: " +  DBKEY_GENERATE_ALARMS + " for the table: " + params[cpt]);
			return false;
		}

		b = sgDBSet(params[cpt], DBKEY_GENERATE_EVENTS, generateEvents);
		if (!b)
		{
			DebugN("sgFwLoadParams >> Unable to create the key: " +  DBKEY_GENERATE_EVENTS + " for the table: " + params[cpt]);
			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwLoadParams >> Unable to create the key: " +  DBKEY_GENERATE_EVENTS + " for the table: " + params[cpt]);
			return false;
		}

		dyn_string aeTableValue;
		aeTableValue = sgDBGet(DBKEY_AETABLES, aeTable);

		if (dynlen(aeTableValue) != 1)
		{
			DebugN("sgFwLoadParams >> AETable: " + aeTable + " not found for params: " + params[cpt]);
			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwLoadParams >> AETable: " + aeTable + " not found for params: " + params[cpt]);
			return false;
		}

		b = sgDBSet(params[cpt], DBKEY_AETABLE, aeTableValue[1]);
		if (!b)
		{
			DebugN("sgFwLoadParams >> Unable to create the key: " +  DBKEY_AETABLE + " for the table: " + params[cpt]);
			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwLoadParams >> Unable to create the key: " +  DBKEY_AETABLE + " for the table: " + params[cpt]);
			return false;
		}
	} // for

	return true;
} // bool sgFwLoadParams()

bool sgFwLoadSystems()
{
	dyn_string systems;
	dyn_string parentsList;
	bool b;

	dyn_string preStatusesNames;
	dyn_string values;

	dyn_string messageDpNames;
	dyn_string messagevalues;

	systems = getPointsOfType("sgFwSystem");
	for(int cpt = 1; cpt <= dynlen(systems); cpt++)
	{
		string paramsName;
		string eventText;
//		string componentText;
		bool generateAlarms;
		bool generateEvents;
		dyn_string histories;
		string aeTable;
		string truthTable;
		dyn_string truthTableValue;
		dyn_string inputs;
		int delayTime;

		dpGet(systems[cpt] + PARAMS_POSTFIX, paramsName,
					systems[cpt] + EVENT_TEXT_POSTFIX, eventText,
					systems[cpt] + GENERATE_ALARMS_POSTFIX, generateAlarms,
					systems[cpt] + GENERATE_EVENTS_POSTFIX, generateEvents,
					systems[cpt] + EVENT_HISTORIES_POSTFIX, histories,
					systems[cpt] + AETABLE_POSTFIX, aeTable,
					systems[cpt] + LOGIC_RULE_POSTFIX, truthTable,
					systems[cpt] + LOGIC_INPUTS_POSTFIX, inputs,
					systems[cpt] + STATUS_DELAY_POSTFIX, delayTime);

		string description;

		description = dpGetDescription(systems[cpt]);

		if(paramsName != "")
		{
			dyn_string tables;
			tables = sgDBTablesNames();

			if(dynContains(tables, paramsName) == 0)
			{
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwLoadSystems: Unable to get params " + paramsName + " for system " + systems[cpt]);
				DebugTN("sgFwLoadSystems: Unable to get params " + paramsName + " for system " + systems[cpt]);
				return false;
			}

			dyn_string ds;

			ds = sgDBGet(paramsName, DBKEY_GENERATE_ALARMS);
			generateAlarms = ds[1];

			ds = sgDBGet(paramsName, DBKEY_GENERATE_EVENTS);
			generateEvents = ds[1];

			histories = sgDBGet(paramsName, DKBEY_HISTORIES);

			ds = sgDBGet(paramsName, DBKEY_STATUS_DELAY);
			delayTime = ds[1];

			aeTable = sgDBGet(paramsName, DBKEY_AETABLE);
		}// params not empty

		if(eventText == "")
			eventText = description;

		if(aeTable != "")
		{
			string table;

			if(paramsName != "") // if filled, table comes from params and is already a value
			{
				table = aeTable;
			}
			else
			{
				table = sgDBGet(DBKEY_AETABLES, aeTable);
			}

			if(table == "")
			{
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwLoadSystems: Unable to get AETable " + table + " for system " + systems[cpt]);
				DebugTN("FwUtils.SystemHistory", "sgFwLoadSystems: Unable to get AETable " + table + " for system " + systems[cpt]);
				return false;
			}

			// replace table name by its value
			aeTable = table;

		}

		if(truthTable != "")
		{
			truthTableValue = sgDBGet(DBKEY_TRUTH_TABLES, truthTable);

			if(dynlen(truthTableValue) == 0)
			{
				DebugTN("sgFWLoadSystem: failed on truth table: " + systems[cpt] + ", table name is " + truthTable);
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwLoadSystems: Unable to load truth table for system " + systems[cpt]);
				return false;
			}
		}

		b = sgDBCreateTable(systems[cpt]);
		if(!b)
		{
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwLoadSystems: Unable to create table for system " + systems[cpt]);
				return false;
		}

		b = sgDBSet(systems[cpt], DBKEY_EVENT_TEXT, eventText);
		if(!b)
		{
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwLoadSystems: Unable to set event text for system " + systems[cpt]);
				return false;
		}

		b = sgDBSet(systems[cpt], DBKEY_STATUS_DELAY, delayTime);
		if(!b)
		{
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwLoadSystems: Unable to set status delay for system " + systems[cpt]);
				return false;
		}

		b = sgDBSet(systems[cpt], DKBEY_HISTORIES, histories);
		if(!b)
		{
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwLoadSystems: Unable to set histories for system " + systems[cpt]);
				return false;
		}

		b = sgDBSet(systems[cpt], DBKEY_GENERATE_ALARMS, generateAlarms);
		if(!b)
		{
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwLoadSystems: Unable to set generate alarms for system " + systems[cpt]);
				return false;
		}

		b = sgDBSet(systems[cpt], DBKEY_GENERATE_EVENTS, generateEvents);
		if(!b)
		{
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwLoadSystems: Unable to set generate events for system " + systems[cpt]);
				return false;
		}

		b = sgDBSet(systems[cpt], DBKEY_AETABLE, aeTable);
		if(!b)
		{
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwLoadSystems: Unable to set aeTable for system " + systems[cpt]);
				return false;
		}

		if(dynlen(truthTableValue) != 0)
		{
			b = sgDBSet(systems[cpt], DBKEY_TRUTH_TABLE, truthTableValue);
			if(!b)
			{
					sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwLoadSystems: Unable to set truth Table for system " + systems[cpt]);
					return false;
			}
		}

		b = sgDBSet(systems[cpt], DBKEY_INPUTS, inputs);
		if(!b)
		{
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwLoadSystems: Unable to set inputs for system " + systems[cpt]);
				return false;
		}

		dyn_string empty;

		b = sgDBSet(systems[cpt], DBKEY_PARENTS, empty);
		if(!b)
		{
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwLoadSystems: Unable to set empty parents for system " + systems[cpt]);
				return false;
		}

		if(dynlen(inputs) != 0)
		{
			dynAppend(parentsList, systems[cpt]);
		}

		dynAppend(preStatusesNames, systems[cpt] + PRE_STATUS_POSTFIX);
		dynAppend(preStatusesNames, systems[cpt] + STATUS_POSTFIX);
		
		// 2006-09-14 PW added message initialization at fw restart
		dynAppend(messageDpNames, systems[cpt] + MESSAGE_POSTFIX);

	} // for each system

	if(isActiveChain())  //new test old was: if(thisChain == activeChain)
	{
		for(int cptSystems = 1; cptSystems <= dynlen(preStatusesNames); cptSystems++)
		{
			dynAppend(values, UKN_STATUS);
		}

		// 2006-09-14 PW added message initialization at fw restart
		for(int cptSystems = 1; cptSystems <= dynlen(messageDpNames); cptSystems++)
		{
			dynAppend(messagevalues, "");
		}
//		DebugTN("sgFw2Lib: sgFwLoadSystems","activeChain=",activeChain,"thisChain=",thisChain,"will set all statuses to UKN " + dynlen(preStatusesNames) + " - " + dynlen(values));
		dpSet(preStatusesNames, values);// two dpSet with dyn_strings!
		dpSet(messageDpNames, messagevalues);

	}

	b = sgDBSet(GLOBAL_TABLE_NAME, DBKEY_SYSTEMS_LIST, systems);
	if(!b)
	{
			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwLoadSystems: Unable to set systems list in global table");
			return false;
	}

	b = sgDBSet(GLOBAL_TABLE_NAME, DBKEY_PARENTS_LIST, parentsList);
	if(!b)
	{
			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwLoadSystems: Unable to set parents list in global table");
			return false;
	}
	return true;
} //bool sgFwLoadSystems()

bool sgFwBuildParentInputLinks()
{
	dyn_string parents;
	bool b;

	b = sgDBCreateTable(DBKEY_MODIFIED_PARENTS);


	// TO DO: add events in histories...
	if(!b)
	{
		DebugTN("sgFwBuildParentInputLinks: unable to create table");
		return false;
	}

	parents = sgDBGet(GLOBAL_TABLE_NAME, DBKEY_PARENTS_LIST);

	for(int cpt = 1; cpt <= dynlen(parents); cpt++)
	{
		dyn_string patterns;
		dyn_string inputs;
		dyn_string ds;

		patterns = sgDBGet(parents[cpt], DBKEY_INPUTS);

		for(int cptPattern = 1; cptPattern <= dynlen(patterns); cptPattern++)
		{
			ds = getPointsFromPattern(patterns[cptPattern]);
			if(dynlen(ds) == 0)
			{
				DebugTN("sgFwBuildParentInputLinks: Invalid pattern " + patterns[cptPattern] + " in system " + parents[cpt]);
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwBuildParentInputLinks: Invalid pattern " + patterns[cptPattern] + " in system " + parents[cpt]);
				return false;
			}
			dynAppend(inputs, ds);
		}
		b = sgDBSet(parents[cpt], DBKEY_INPUTS, inputs);
		if(!b)
		{
			DebugTN("sgFwBuildParentInputLinks: Unable to set expanded inputs list in system " + parents[cpt]);
			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwBuildParentInputLinks: Unable to set expanded inputs list in system " + parents[cpt]);
			return false;
		}

		for(int cptInputs = 1; cptInputs <= dynlen(inputs); cptInputs++)
		{
			b = sgDBAppend(inputs[cptInputs], DBKEY_PARENTS, parents[cpt]);
			if(!b)
			{
				DebugTN("sgFwBuildParentInputLinks: Unable to set " + parents[cpt] + " as parent for input " + inputs[cptInputs]);
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwBuildParentInputLinks: Unable to set " + parents[cpt] + " as parent for input " + inputs[cptInputs]);
				return false;
			}
		}
	}
	return true;
}

bool sgFwLoadBitStates()
{
	dyn_string bitStates;
	bool b;

	bitStates = getPointsOfType("sgFwBitState");
	for(int cpt = 1; cpt <= dynlen(bitStates); cpt++)
	{
		string eventText;
//		string componentText;
		string isState;
		bool generateEvents;
		dyn_string histories;

		dpGet(bitStates[cpt] + EVENT_TEXT_POSTFIX, eventText,
					bitStates[cpt] + IS_STATE_POSTFIX, isState,
					bitStates[cpt] + GENERATE_EVENTS_POSTFIX, generateEvents,
					bitStates[cpt] + EVENT_HISTORIES_POSTFIX, histories);

		string description;

		description = dpGetDescription(bitStates[cpt]);

		if(eventText == "")
			eventText = description;

		b = sgDBCreateTable(bitStates[cpt]);
		if(!b)
		{
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwLoadBitsStates: Unable to create table for bitstate " + systems[cpt]);
				return false;
		}
		b = sgDBSet(bitStates[cpt], DBKEY_EVENT_TEXT, eventText);
		if(!b)
		{
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwLoadBitsStates: Unable to set event text for bitstate " + systems[cpt]);
				return false;
		}

		b = sgDBSet(bitStates[cpt], DBKEY_BITSTATE_IS_STATE, isState);
		if(!b)
		{
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwLoadBitsStates: Unable to set isState for bitstate " + systems[cpt]);
				return false;
		}

		b = sgDBSet(bitStates[cpt], DKBEY_HISTORIES, histories);
		if(!b)
		{
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwLoadBitsStates: Unable to set histories for bitstate " + systems[cpt]);
				return false;
		}

		b = sgDBSet(bitStates[cpt], DBKEY_GENERATE_EVENTS, generateEvents);
		if(!b)
		{
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwLoadBitsStates: Unable to set generate events for bitstate " + systems[cpt]);
				return false;
		}
	} // for each system

	b = sgDBSet(GLOBAL_TABLE_NAME, DBKEY_BITSTATES_LIST, bitStates);
	if(!b)
	{
			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwLoadBitsStates: Unable to set bit states list in global table");
			return false;
	}
	return true;
} //bool sgFwLoadBitStates()



void sgAEExec(string systemName, string oldStatus, string newStatus, string message, bool disabled)
{
	dyn_string ds;
	bool generateAlarms;
	bool generateEvents;


	ds = sgDBGet(systemName, DBKEY_GENERATE_ALARMS);
	generateAlarms = ds[1];

	ds = sgDBGet(systemName, DBKEY_GENERATE_EVENTS);
	generateEvents = ds[1];

	if(disabled)
	{
//		if(oldStatus != newStatus) // report only changes on status
//		{
//			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "Disabled system " + systemName + " changed from: " + oldStatus + " to: " + newStatus);
//		}
		dpSet(systemName + ALARM_ACTIVE_POSTFIX, false);
//		return;
	}

	if(generateAlarms || generateEvents) 
	{
		string aeTable;
		string prefix;
		int prefixIndex;

		string severity;
		int alarm;

		aeTable = sgDBGet(systemName, DBKEY_AETABLE);

		prefix = oldStatus + newStatus;

		prefixIndex = strpos(aeTable, prefix);
		if(prefixIndex < 0)
		{
			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "AETable for system " + systemName + " can not manage change from: " + oldStatus + " to: " + newStatus + ", generate alarm");
			severity = SEVERITY_NOT_DEFINED;
			alarm = 2; // re-create
		}
		else
		{
			string s;
			dyn_string ds;

			s = substr(aeTable, prefixIndex);
			s = substr(s, 0, strpos(s, ";"));
			ds = strsplit(s, "-");

			severity = ds[1];
			severity = substr(severity, strpos(severity, ":") + 1);
			alarm = ds[2];
		}
	
		
		// PW modification to have a trace in the current history 
		// no new alarm if disabled
		//		if(generateAlarms)

		if(generateAlarms && !disabled)
		{
			if(alarm == 0)
			{
				dpSet(systemName + ALARM_ACTIVE_POSTFIX, false);
			}
			else if(alarm == 1)
			{
				dpSet(systemName + ALARM_ACTIVE_POSTFIX, true);
			}
			else if(alarm == 2)
			{
				dpSet(systemName + ALARM_ACTIVE_POSTFIX, false);
				dpSet(systemName + ALARM_ACTIVE_POSTFIX, true);
			}
		}

		if(generateEvents && (oldStatus != newStatus)) // no new event if only disabling changed
		{
			dyn_string histories;
			string eventText;
			string event;

			histories = sgDBGet(systemName, DKBEY_HISTORIES);
			eventText = sgDBGet(systemName, DBKEY_EVENT_TEXT);
			
		// PW modification to have a trace in the current history 
			if(disabled)
				severity = SEVERITY_DISABLED;

			event = eventText + " changed from " + oldStatus + " to " + newStatus;
			
			if(message == "")
			{
				sgHistoryAddEvent(histories, severity, event);
			}
			else
			{
				sgHistoryAddEvent(histories, severity, event, message);
			}
		}
	}
}

void sgFwRefreshDelayedSystem(string systemName, string preStatus, string status, bool disabled, string message, int delayTime)
{
	dyn_string delayedSystems;
	int index;
	bool b;

	delayedSystems = sgDBTableKeys(DBKEY_DELAYED_SYSTEMS);

	index = dynContains(delayedSystems, systemName);
	dyn_string values;
	if(index == 0)
	{
		time expiry;
		expiry = getCurrentTime() + delayTime;
		values = makeDynString(preStatus, status, disabled, message, expiry);
	}
	else // pending
	{
		values = sgDBGet(DBKEY_DELAYED_SYSTEMS, systemName);
		values[1] = preStatus;
		values[3] = disabled;
		values[4] = message;
	}

	b = sgDBSet(DBKEY_DELAYED_SYSTEMS, systemName, values);

	if(!b)
	{
		sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "Unable to set values for delayed system " + systemName);
	}
}

bool sgFwDelayedSystemsCheck()
{
	dyn_string delayedSystems;

	delayedSystems = sgDBTableKeys(DBKEY_DELAYED_SYSTEMS);
  
	for(int cpt = 1; cpt <= dynlen(delayedSystems); cpt++)
	{
		dyn_string values;
		time expiry;
		string preStatus;
		string status;

		values = sgDBGet(DBKEY_DELAYED_SYSTEMS, delayedSystems[cpt]);
		expiry = values[5];
		
		// yca [13-02-2013] replace prestatus with actual pre status
		dpGet(delayedSystems[cpt] + PRE_STATUS_POSTFIX, preStatus);      
		status = values[2];

//		if(expiry < getCurrentTime() || preStatus == "UKN" || status == "UKN")  old version P.Wulliens 2015-06-25
 		if(expiry < getCurrentTime() || status == "UKN" )   
		{
			bool disabled;
			string message;

			//preStatus = values[1];
			disabled = values[3];
			message = values[4];

		 if(preStatus != status) //
			{
      // yca [13-02-2013] set the new preStatus
				dpSet(delayedSystems[cpt] + STATUS_POSTFIX, preStatus);
				sgAEExec(delayedSystems[cpt], status, preStatus, message, disabled);
			}

			sgDBRemove(DBKEY_DELAYED_SYSTEMS, delayedSystems[cpt]);
		}
	}
	return true;
}

void sgFwSystemChanged(string preStatusName, string preStatusValue,
											 string statusName, string statusValue,
											 string disabledName, bool disabledValue,
											 string subDisabledName, bool subDisabledValue,
											 string messageName, string messageValue)
{
	string systemName;
	
	sgFw2SystemChangedCounter++;	
	
	systemName = sgStripDpName(preStatusName, PRE_STATUS_POSTFIX);
	

	if(preStatusValue == statusValue)
	{
		// this must be done if disabled / sub disabled changed
		// if these variables changed, their time stamps must be later than the pre-status one
		// otherwise pre-status was simply re-written (XML for exmaple) and no action is needed
		
		time statusTime, disabledTime, subDisabledTime, preStatusTime;
		
		
		dpGet(systemName + PRE_STATUS_POSTFIX + ":_online.._stime", preStatusTime,
					systemName + STATUS_POSTFIX + ":_online.._stime", statusTime,
		  		systemName + DISABLED_POSTFIX + ":_online.._stime", disabledTime,
      		systemName + SUB_DISABLED_POSTFIX + ":_online.._stime", subDisabledTime);
    
    // 21.10.2005 aj, tv add/substract 1 second to correct a possible time difference between client and server
    // the correction is done so that in worst case the logic is calculated too often
		preStatusTime -= 1;
		disabledTime += 1;
		
		if( (preStatusTime > disabledTime) && (preStatusTime > subDisabledTime) )
		{
			if(preStatusTime > statusTime)
			{
				//no action needed, PreStatus is more recent
				return;
			}
		}
		
		// reactivate alarm if system has just been re-enabled
		sgAEExec(systemName, statusValue, preStatusValue, messageValue, disabledValue);
		
		
		
		// 18.10.2005 aj, tv avoid recalculating logic if a disabled system changes (logic result would be the same but alarm could be recreated)
		// if disabling the system caused the work funktion call the parent status has to be recalculated!
		// only if system was already disabled before this work funktion call it is not necessary to recalculate the parent state
		if ( (disabledValue) &&
		( (disabledTime < preStatusTime) || (disabledTime < statusTime) || (disabledTime < subDisabledTime) ) )
		{
			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "disabled system: " + systemName + " changed - don't recalculate the logic for the parent, timestamps (disabled, preStatus, status, subDisabled): " + (string) disabledTime + ", " + (string) preStatusTime  + ", " + (string) statusTime  + ", " + (string) subDisabledTime);
			//DebugTN("sgFwSystemChanged",systemName,"changed but disabled");
			//DebugTN("sgFwSystemChanged timestamps: " + (string) disabledTime + (string) preStatusTime + (string) statusTime + (string) subDisabledTime);
			return;
		}
			
		dyn_string keys;
		
		keys = sgDBTableKeys(systemName);
		if(!dynContains(keys, DBKEY_PARENTS))
			return;
			
		dyn_string parents;
		
		parents = sgDBGet(systemName, DBKEY_PARENTS);
		
		for(int cpt = 1; cpt <= dynlen(parents); cpt++)
		{
		
			dyn_anytype inputsValues;
			dyn_anytype inputsDisableds;
			dyn_string inputs;
			dyn_string ds1, ds2, ds3;
			dyn_string allValues;
			dyn_string table;
			string parentStatus;
			string ttOutput;
			
			// notify that the parent must be recomputed
			dyn_string keys = sgDBTableKeys(DBKEY_MODIFIED_PARENTS);
			if( dynContains(keys, parents[cpt]) < 1 )
			{
				sgDBSet(DBKEY_MODIFIED_PARENTS, parents[cpt], "X");
			}
			else
			{
				sgDBAppend(DBKEY_MODIFIED_PARENTS, parents[cpt], "X");
			}
			
		}
	} // pre-status changed
	else
	{
		sgFw2ActualChangeCounter++;
		dyn_string ds;
		int delayTime;
		
		ds = sgDBGet(systemName, DBKEY_STATUS_DELAY);
		delayTime = ds[1];	
		
		if(delayTime!= 0)
		{
			sgFwRefreshDelayedSystem(systemName, preStatusValue, statusValue, disabledValue, messageValue, delayTime);
		}	
		else
		{
			sgAEExec(systemName, statusValue, preStatusValue, messageValue, disabledValue);
			dpSet(systemName + STATUS_POSTFIX, preStatusValue);
		}
	}
}

bool sgFwComputeLogic()
{
	dyn_string parents;
	dyn_string parentTemp, parentTempValues;
	dyn_string parentsStatus, parentsSubDisabled;
	dyn_bool parentsSubDisabledLTD;
	dyn_string names;
	dyn_string values;
	dyn_string allValues;

	int parentsCount;

	// first "column" = name, second = value
	parents = sgDBTableKeys(DBKEY_MODIFIED_PARENTS);

	parentsCount = dynlen(parents);

	if(parentsCount == 0)
		return true;

	// DebugTN("sgFwComputeLogic: START");


	for(int cptParents = 1; cptParents <= dynlen(parents); cptParents++)
	{
		dynAppend(parentTemp,parents[cptParents] + PRE_STATUS_POSTFIX);
		dynAppend(parentTemp,parents[cptParents] + SUB_DISABLED_POSTFIX);
		dynAppend(parentTemp,parents[cptParents] + SUB_DISABLED_POSTFIX + ORIGINAL_USERBIT_1);
	}

	dpGet(parentTemp, parentTempValues);

	for(int cptSplit = 1; cptSplit <= dynlen(parentTempValues); cptSplit++)
	{
		dynAppend(parentsStatus, parentTempValues[cptSplit++]);
		dynAppend(parentsSubDisabled, parentTempValues[cptSplit++]);
		dynAppend(parentsSubDisabledLTD, parentTempValues[cptSplit]);
	}

	// DebugTN("sgFwComputeLogic: before LOOP");

	//////////////////////////
	for(int cpt = 1; cpt <= dynlen(parents); cpt++)
	{
			dyn_string inputs;
			dyn_string ds1, ds2, ds3;
			dyn_string inputsValues, inputsDisableds, inputsSubDisableds;
			dyn_bool inputsDisabledsLTD, inputsSubDisabledsLTD;
			inputs = sgDBGet(parents[cpt], DBKEY_INPUTS);

//			DebugTN("sgFwComputeLogic Will compute " + parents[cpt]);

			for(int cptInput = 1; cptInput <= dynlen(inputs); cptInput++)
			{
				dynAppend(ds3, inputs[cptInput] + STATUS_POSTFIX);
				dynAppend(ds3, inputs[cptInput] + DISABLED_POSTFIX);
				dynAppend(ds3, inputs[cptInput] + SUB_DISABLED_POSTFIX);
				dynAppend(ds3, inputs[cptInput] + DISABLED_POSTFIX + ORIGINAL_USERBIT_1);
				dynAppend(ds3, inputs[cptInput] + SUB_DISABLED_POSTFIX + ORIGINAL_USERBIT_1);
			}

			dpGet(ds3, allValues);

			for(int cptSplit = 1; cptSplit <= dynlen(ds3); cptSplit++)
			{
				dynAppend(inputsValues, allValues[cptSplit++]);
				dynAppend(inputsDisableds, allValues[cptSplit++]);
				dynAppend(inputsSubDisableds, allValues[cptSplit++]);
				dynAppend(inputsDisabledsLTD, allValues[cptSplit++]);
				dynAppend(inputsSubDisabledsLTD, allValues[cptSplit]);
			}

			dyn_string table;
			table = sgDBGet(parents[cpt], DBKEY_TRUTH_TABLE);
			//DebugTN("sgFw2Lib: fwStatusChanged: will compute logic for " + parents[cpt] + " because of change of " + systemName);
			string ttOutput;
			ttOutput = sgTTComputeOutput(inputsValues, table, inputsDisableds);

// PW temp for test 07.02.2006
//			if(ttOutput != parentsStatus[cpt])
//			{
				dynAppend(names, parents[cpt] + PRE_STATUS_POSTFIX);
				dynAppend(values, ttOutput);
//			}

//			sgFwSubDisabledParent(parents[cpt], systemName, disabledValue, subDisabledValue);

			bool disabledInputFound = false;
			bool allDisabledLTD = true;
			string input;
			for(int cptInputs = 1; cptInputs <= dynlen(inputs); cptInputs++) {
				bool disabled = inputsDisableds[cptInputs];
				bool subDisabled = inputsSubDisableds[cptInputs];
				bool disabledLTD = inputsDisabledsLTD[cptInputs];
				bool subDisabledLTD = inputsSubDisabledsLTD[cptInputs];

				if ((disabled || subDisabled) && !disabledInputFound) {
					disabledInputFound = true;
					input = inputs[cptInputs];
				}
				if (disabled && ! disabledLTD || subDisabled && ! subDisabledLTD) allDisabledLTD = false;

			}

			if(!parentsSubDisabled[cpt] && disabledInputFound) {
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "System " + parents[cpt] + " sub-disabled because input " + input + " is disabled or sub-disabled");
				dpSet(	parents[cpt] + SUB_DISABLED_POSTFIX, true);
			}

			if (disabledInputFound && parentsSubDisabledLTD[cpt] != allDisabledLTD) {
				dpSet(parents[cpt] + SUB_DISABLED_POSTFIX + ORIGINAL_USERBIT_1, allDisabledLTD);
			}

			if((parentsSubDisabled[cpt]) && !disabledInputFound) {
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "System " + parents[cpt] + " no longer sub-disabled.");
				dpSet(	parents[cpt] + SUB_DISABLED_POSTFIX, false,
						parents[cpt] + SUB_DISABLED_POSTFIX + ORIGINAL_USERBIT_1, false);
			}

			sgDBRemove(DBKEY_MODIFIED_PARENTS, parents[cpt]);

//			DebugTN("sgFwComputeLogic finished " + parents[cpt]);
//			DebugTN("-------------------------");
		// DebugTN("sgFwComputeLogic: in LOOP:",cpt, "for inputs:", dynlen(inputs));
		}

// 	DebugTN("sgFwComputeLogic: after LOOP");

//	DebugTN("sgFwComputeLogic: Finished logic for " + parentsCount + " parents");
//	DebugTN("sgFwComputeLogic: will set  " + dynlen(names) + " datapoints");

	/////////////////////////


	dpSet(names, values);


	return true;
}

void sgFwBitStateChanged(string stateName, bool stateValue,
												string isStateName, bool isState,
											 	string lastStateName, bool lastStateValue,
											 	string messageName, string message)
{

	string bitStateName = sgStripDpName(stateName, STATE_POSTFIX);

	if(stateValue == lastStateValue)  // if equal no event, and last value is set
	{
	//	DebugN("sgFw2Lib.ctl; in sgFwBitStateChanged: stateValue == lastStateValue");
		return;
	}

	sgBitStateAddEvent(bitStateName, stateValue, message);

	// affect the last state value
	string lastStateNameStripped = sgStripDpName(lastStateName, "");
	dpSet(lastStateNameStripped, stateValue);
}

void sgBitStateAddEvent(string bitStateName, bool newValue, string message)
{
	dyn_string ds;
	bool generateEvents;
	bool isState;
	string addedMessage;

//	if(message != "")
//		addedMessage = " (" + message + ")";
//	else
//		addedMessage = "";

// if the old value = the new value, the test is made in function sgFwBitStateChanged to not rewrite the old value

	ds = sgDBGet(bitStateName, DBKEY_GENERATE_EVENTS);
	generateEvents = ds[1];

	if(!generateEvents)
		return;

	ds = sgDBGet(bitStateName, DBKEY_BITSTATE_IS_STATE);
	isState = ds[1];

	dyn_string histories;
	string eventText;
	string eventString;
	string severity;

	histories = sgDBGet(bitStateName, DKBEY_HISTORIES);
	eventText = sgDBGet(bitStateName, DBKEY_EVENT_TEXT);

	if(isState)
	{
		if(newValue)  // state is active
		{
			eventString = eventText + " changed to active state";
			severity = SEVERITY_INFO;
		}
		else
		{
			eventString = eventText + " changed to inactive state";
			severity = SEVERITY_INFO;
		}
	}
	else
	{
		if(newValue)  // bit state is in normal state
		{
			eventString = eventText + " changed to normal state";
			severity = SEVERITY_SOLVED;
		}
		else
		{
			eventString = eventText + " changed to warning state";
			severity = SEVERITY_CRITICAL;
		}
	}
	sgHistoryAddEvent(histories, severity, eventString, message);
}

bool sgFwConnectBitStates()
{
	dyn_string bitStates;

	bitStates = sgDBGet(GLOBAL_TABLE_NAME, DBKEY_BITSTATES_LIST);

	for(int cpt = 1; cpt <= dynlen(bitStates); cpt++)
	{
		int res;
		res = dpConnect("sgFwBitStateChanged", bitStates[cpt] + STATE_POSTFIX, bitStates[cpt] + IS_STATE_POSTFIX, bitStates[cpt] + LAST_STATE_POSTFIX, bitStates[cpt] + MESSAGE_POSTFIX);
		if(res != 0)
		{
			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "dpConnect failed for bit state " + bitStates[cpt]);
			return false;
		}
	}
	return true;
}


bool sgFwConnectSystems()
{
	dyn_string systems;

	systems = sgDBGet(GLOBAL_TABLE_NAME, DBKEY_SYSTEMS_LIST);

	for(int cpt = 1; cpt <= dynlen(systems); cpt++)
	{
		int res;
		res = dpConnect("sgFwSystemChanged", false, systems[cpt] + PRE_STATUS_POSTFIX, systems[cpt] + STATUS_POSTFIX, systems[cpt] + DISABLED_POSTFIX, systems[cpt] + SUB_DISABLED_POSTFIX,  systems[cpt] + MESSAGE_POSTFIX);
		if(res != 0)
		{
			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "dpConnect failed for system " + systems[cpt]);
			return false;
		}
	}
	return true;
}

void sgFwAckAll(string dpName, bool value)
{
	dyn_string ds;
	dyn_int	dynValue;

	ds = sgDBGet(DBKEY_ALARM_POINTS_TABLE, DBKEY_ACK_DATAPOINTS);

	for(int cpt = 1; cpt <= dynlen(ds); cpt++)
	{
		dynAppend(dynValue, 2); // set to 2 to Ack the Alert_hdl
	}
	dpSet(ds, dynValue);
}

bool sgInitAckAllAlarms()
{
	dyn_string localSystems;
	string systemName;
	int len;
	int cpt;
	bool generateAlarms;

	bool b;
	b =	sgDBCreateTable(DBKEY_ALARM_POINTS_TABLE);
	if(!b)
	{
		DebugTN("sgInitAckAllAlarms >> unable to create DBKEY_ALARM_POINTS_TABLE ! ");
		return false;
	}

	dyn_string empty;

	b = sgDBSet(DBKEY_ALARM_POINTS_TABLE, DBKEY_ACK_DATAPOINTS, empty);
	if(!b)
	{
		DebugTN("sgInitAckAllAlarms >> unable to create DBKEY_ACK_DATAPOINTS ! ");
		return false;
	}

	localSystems = getPointsOfType("sgFwSystem");

	len = dynlen(localSystems);
	for(cpt = 1; cpt <= len; cpt++)
	{
		systemName = localSystems[cpt];
		//dpGet(systemName + GENERATE_ALARMS_POSTFIX, generateAlarms);

		dyn_string ds;
		ds = sgDBGet(systemName, DBKEY_GENERATE_ALARMS);
		generateAlarms = ds[1];

		if(generateAlarms)
			sgDBAppend(DBKEY_ALARM_POINTS_TABLE, DBKEY_ACK_DATAPOINTS, systemName + ALARM_ACTIVE_POSTFIX + ":_alert_hdl.._ack");
	}

// PW 12.2005 Added acknowledge for Framework alarm
			sgDBAppend(DBKEY_ALARM_POINTS_TABLE, DBKEY_ACK_DATAPOINTS, ACTIVE_FW_OK + ":_alert_hdl.._ack");


	int res;
	res = dpConnect("sgFwAckAll", false, "FwUtils.AckAlarms.AckAll");
	if(res != 0)
	{
		DebugTN("sgInitAckAllAlarms >> unable to connect FwUtils.AckAlarms.AckAll");
		return false;
	}
	return true;
}


bool connectSystemGlobalStatuses()
{
	int ret = dpQueryConnectSingle("distributedStatusAlarms", FALSE, DISTRIBUTED_STATUS, 
							"SELECT '_online.._value' FROM '" + SYSTEMS_GLOBAL_STATUS + "' REMOTE ALL");
							
	if (ret != 0)
		return FALSE;
	else
	{
		int ret = dpQueryConnectSingle("distributedStatusAlarms", FALSE, DISTRIBUTED_ALARM, 
								"SELECT ALERT '_alert_hdl.._ackable' FROM '" + ACTIVE_FW_OK + "' REMOTE ALL");
		if (ret != 0)
			return FALSE;
	}
	return TRUE;
}

void distributedStatusAlarms(string ident, dyn_dyn_anytype values)
{
	dyn_string excludedSystems;
	string distributedSystem;
	bool disabled;
	
	dpGet(EXCLUDED_SYSTEMS, excludedSystems);
	
	for (int i = 2; i <= dynlen(values); i++)
	{
		distributedSystem = dpSubStr(values[i][1], DPSUB_SYS);
		//26.04.2006 aj don't create alarm for disabled system
		dpGet(distributedSystem + SYSTEMS_GLOBAL_DISABLED, disabled);
		
		if ((dynContains(excludedSystems,distributedSystem) == 0) && (!disabled))
		{
			if ( ((ident == DISTRIBUTED_STATUS) && (values[i][2] != OPS_STATUS))
				|| ((ident == DISTRIBUTED_ALARM)  && (values[i][3] == 1)) )
			{
				dpSet(ALL_SYSTEMS_OK, FALSE);
				break;
			}
		}
	}
}

void sgFwConnectActiveChain()
{
	dpConnect("sgFwActiveChainChanged", ACTIVE_CHAIN);
}


void sgFwActiveChainChanged(string dp, string activeChain)
{
	if (activeChain != oldActiveChain)
	{
		writeDisabledToRecalculateAllAlarms();
	}
	oldActiveChain = activeChain;
}

// specials functions to re create the globalsystem alarm
string lastGlobalStatus;

void connectGlobalPreStatus()
{
	dpConnect("reGenerateAlarm" ,"SystemStatus.GlobalStatus.PreStatus");
}

// special function to rewrite the alarm on the global status to re create an alarm when an second input is DEG
void reGenerateAlarm(string globalPreStatusDpName, string globalPreStatus)
{

	// if last Status was DEG and new Status is DEG
	if(lastGlobalStatus == DEG_STATUS && globalPreStatus == DEG_STATUS)
	{
		// sgFw rewrite the DEG value on status if it was forced to OPS -> restart the alarm
		dpSet("SystemStatus.GlobalStatus.Status", OPS_STATUS);
	}
	// update last status
	lastGlobalStatus = globalPreStatus;
}

