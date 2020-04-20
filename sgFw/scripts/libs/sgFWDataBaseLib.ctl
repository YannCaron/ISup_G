// 
// Version 2.0
//
// Date 12-JUL-04
//
// This file is the library for the caching data base
//
// History
// =======
// 12-JUL-04 : First version (VL, PW, ThV)


//Function (NoName)_General()

// Globals
global dyn_string gDBTableNames; // list of table names
global dyn_dyn_string gDBTableKeys; // keys
global dyn_dyn_string gDBTableValues; // values

global bool gDBInitialised = false;
global bool gDBInitStarted = false;

// Constants
const string GLOBAL_TABLE_NAME = "GLOBAL_TABLE";


void sgDynDynAppend(dyn_dyn_string &dds, dyn_string ds)
{
	dds[dynlen(dds) + 1] = ds;
}

void sgDBWaitForInit()
{
	while(!gDBInitialised)
	{
		delay(1,0);
	}
}

void sgDBInit()
{
	dyn_dyn_string emptyDds;

	// 12.05.2005 aj, avoid "double" initialisation
	// check if initialisation already started once, if so, don't do it again :-)
	// not using gDBInitialised because it is set at the end of the initialisation only
	if (!gDBInitStarted)
		gDBInitStarted = TRUE;
	else
		return;
	// 12.05.2005 aj, avoid "double" initialisation

	dpConnect("sgDBProcessQuery", false, "FwUtils.DBQuery.Table");
	
	dpConnect("sgDBProcessTableList", false, "FwUtils.sgDBTableList.TableListUpdate");
	
	bool result;
	
	dynClear(gDBTableNames);
	gDBTableKeys = emptyDds;
	gDBTableValues = emptyDds;
	
	result = sgDBCreateTable(GLOBAL_TABLE_NAME);
	
	if (result != true)
		sgHistoryAddEvent("FwUtils.DBHistory", SEVERITY_SYSTEM, "sgDBInit >> failed to initialize !");
		
	gDBInitialised = true;
} // void sgDBInit()

bool sgDBCreateTable(string tableName)
{
	dyn_string empty;

	if (dynContains(gDBTableNames, tableName) > 0)
	{
		sgHistoryAddEvent("FwUtils.DBHistory", SEVERITY_SYSTEM, "sgDBCreateTable >> table: " + tableName + " already exist !");
		return false;
	}
	
	dynAppend(gDBTableNames, tableName);

	sgDynDynAppend(gDBTableKeys, empty);
	sgDynDynAppend(gDBTableValues, empty);
	
	return true;
} // bool sgDBCreateTable()

dyn_string sgDBTablesNames()
{
	return gDBTableNames;
} // dyn_string sgDBTablesNames()

dyn_string sgDBTableKeys(string tableName)
{
	dyn_string empty;
	int index;
	index = dynContains(gDBTableNames, tableName);
	if (index < 1)
	{
		sgHistoryAddEvent("FwUtils.DBHistory", SEVERITY_SYSTEM, "sgTableKeys >> table: " + tableName + " not found !");
//		DebugTN("sgDBTableKeys >> table: " + tableName + " not found !");
		return empty;
	}
	
	return gDBTableKeys[index];
} // dyn_string sgTableKeys(string tableName)

// 11.07.2005 aj new function for optimization
// code was taken from old sgDBGet()
// new function is called in sgDBGet() - no changes for sgDBGet()
string sgDBGetString(string tableName, string tableKey)
{
	dyn_string empty;
	int iTable;
	iTable = dynContains(gDBTableNames, tableName);
	
	if (iTable < 1)
	{
		sgHistoryAddEvent("FwUtils.DBHistory", SEVERITY_SYSTEM, "sgDBGet >> table: " + tableName + " not found ! (searching key is: " + tableKey + ")");
//		DebugTN("sgDBGet >> table: " + tableName + " not found ! (searching key is: " + tableKey + ")");
		return empty;
	}	
	
	int iKey;
	iKey = dynContains(gDBTableKeys[iTable], tableKey);
	if (iKey < 1)
	{
		sgHistoryAddEvent("FwUtils.DBHistory", SEVERITY_SYSTEM, "sgDBGet >> key: " + tableKey + " in the table: " + tableName + " not found !");
//		DebugTN("sgDBGet >> key: " + tableKey + " in the table: " + tableName + " not found ! ");
		return empty;
	}
		
        
        
	string values;
        if ( (dynlen(gDBTableValues) < iTable) || (dynlen(gDBTableValues[iTable]) < iKey) )
          DebugTN("DB index difference", dynlen(gDBTableNames), dynlen(gDBTableValues[iTable]), dynlen(gDBTableKeys[iTable]), iTable, iKey, gDBTableNames[iTable], gDBTableKeys[iTable], gDBTableValues[iTable], gDBTableKeys[iTable][iKey]);
	values = gDBTableValues[iTable][iKey];

	return values;
}

// 11.07.2005 aj as a new function for optimization was done, use it :-)
// no changes for sgDBGet in the end!!
dyn_string sgDBGet(string tableName, string tableKey)
{
	string values = sgDBGetString(tableName,tableKey);
	
	// remove spaces before and after separation pipes
	
	strreplace(values, " | ", "|");
	
	return strsplit(values, "|");
} // dyn_string sgDBGet()

bool sgDBSet(string tableName, string tableKey, dyn_string values)
{
	int iTable;
	iTable = dynContains(gDBTableNames, tableName);
	if (iTable < 1)
	{
		sgHistoryAddEvent("FwUtils.DBHistory", SEVERITY_SYSTEM, "sgDBSet >> table: " + tableName + " not found !");
//		DebugTN("sgDBSet >> table: " + tableName + " not found !");
		return false;
	}	
	
	int iKey;
	iKey = dynContains(gDBTableKeys[iTable], tableKey);
	if (iKey < 1)
	{
            // 200901 aj/pw
            // changed order of dynAppend - values first
            // to avoid index out of range when there are a lot of changes
            // shouldn't have any side effects
            // values are added later but are not used for logic calculation
            // in other cases it could be good to add values here/at same time as key)
			dynAppend(gDBTableValues[iTable], "");
			dynAppend(gDBTableKeys[iTable], tableKey);
	}	

	iKey = dynContains(gDBTableKeys[iTable], tableKey);
	
	string valuesString;
	
	for (int cpt = 1; cpt <= dynlen(values); cpt++)
	{
		valuesString += values[cpt];
		valuesString += "|";
	}

	gDBTableValues[iTable][iKey] = valuesString;	
	return true;
} // bool sgDBSet(string tableName, string tableKey, dyn_string Values)

// 2009.04.02 aj new function to add several elements in one step (avoiding race conditions with other processes)
bool sgDBAppendMultiple(string tableName, string tableKey, dyn_string values)
{
  string valuesString;
  bool res;

  // when assigning a dyn_string to a string " | " is used automatically to separate the elements 
  // works fine but as it is done with a loop in sgDBSet it is done like this here as well

  if (dynlen(values) >0)
  {
    valuesString = values[1];
   
    for (int cpt = 2; cpt <= dynlen(values); cpt++)
    {
      // 20090609 aj bugfix - "+=" instead of "=" otherwise the connID is LOST
      valuesString += "|" + values[cpt];
    }
 
    res = sgDBAppend(tableName, tableKey, valuesString);
  
    return res;
  }
  else
    return false; // if an empty dyn_string should be appended - "false"
}


// 11.07.2005 aj using new function sgDBGetString
// as the values are stored in a string in any case
// avoid splitting and concatenating in case of a sgDBAppend
// takes a lot of time if the string is getting long ...
bool sgDBAppend(string tableName, string tableKey, string value)
{
	string values;
	dyn_string keys;
	
	keys = sgDBTableKeys(tableName);
	if(!dynContains(keys, tableKey))
	{
		sgHistoryAddEvent("FwUtils.DBHistory", SEVERITY_SYSTEM, "sgDBAppend >> table: " + tableName + " or " + " key: " + tableKey + " not found !");
//		DebugTN("sgDBAppend >> table: " + tableName + " or " + " key: " + tableKey + " not found !");
		return false;
	}

	values = sgDBGetString(tableName, tableKey);
	values += value;

	// test2 not needed anymore - only test
        //dyn_string test2 = sgDBGet(tableName, tableKey);
	//dynAppend(test2,value);
	//dyn_string test = strsplit(values, "|");
	//DebugTN("sgDBAppend >>", dynlen(test), value);

	sgDBSet(tableName, tableKey, values);
		
	return true;
} // bool sgDBAppend(string tableName, string tableKey, dyn_string values)

bool sgDBRemove(string tableName, string tableKey)
{
	// remove the given key in the table tableName
	int iTable;
	iTable = dynContains(gDBTableNames, tableName);
	if (iTable < 1)
	{
		sgHistoryAddEvent("FwUtils.DBHistory", SEVERITY_SYSTEM, "sgDBRemove >> table: " + tableName + " not found !");
//		DebugTN("sgDBRemove >> table: " + tableName + " not found !");
		return false;
	}	
	
	int iKey;
	iKey = dynContains(gDBTableKeys[iTable], tableKey);
	if (iKey < 1)
	{
		sgHistoryAddEvent("FwUtils.DBHistory", SEVERITY_SYSTEM, "sgDBRemove >> key: " + tableKey + " in the table: " + tableName + " not found !");
//		DebugTN("sgDBRemove >> key: " + tableKey + " in the table: " + tableName + " not found !");
		return false;
	}
	
	dynRemove(gDBTableKeys[iTable], iKey);
	dynRemove(gDBTableValues[iTable], iKey);
	
	return true;
} // bool sgDBRemove((string tableName, string tableKey)

void sgDBProcessQuery(string dpName, string tableName)
{
	// This function is connected to fwUtils.DBQuery.Table
	dyn_string keys;
	
	// check if table exists (table can exist and be emtpy)
	if(dynContains(gDBTableNames, tableName) == 0 || dynContains(gDBTableNames, tableName) == -1)
		return;
	
	keys = sgDBTableKeys(tableName);
	dyn_string values;
	
	for (int idKey = 1; idKey <= dynlen(keys); idKey++)
	{
		dyn_string currentValues;
		currentValues = sgDBGet(tableName, keys[idKey]);
		values[idKey] = currentValues;
	} // for
	
	dpSet("FwUtils.DBQuery.Keys", keys,
			  "FwUtils.DBQuery.Values", values);
} // void sgDBProcessQuery(string dpName, string table)

void sgDBProcessTableList(string dpName, bool dpValue)
{
	delay(myManNum(), "0");
	// Add the table list
	dyn_string tableList;
	dpGet("FwUtils.sgDBTableList.TableList", tableList);
	
	for (cpt = 1; cpt <= dynlen(gDBTableNames); cpt++)
		dynAppend(tableList, gDBTableNames[cpt]);
	
	dpSetWait("FwUtils.sgDBTableList.TableList", tableList);
}



