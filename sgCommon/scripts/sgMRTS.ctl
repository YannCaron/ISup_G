
// blocking time for all dpQueryConnectSingle in ms
// 01.06.2005 aj changed from 2000 to 4000 because the snmp response takes long
const int BLOCKING_TIME = 4000;
const int CMD_ATTACH = 1;
const int CMD_DETACH = 2;
const int CMD_START = 1;
const int CMD_STOP = 2;
const string CMD_DELIMITER = "!";
const string MRTS_HISTORY = "MRTS.SystemHistory";
const	int	SYNC = 2;
// 10.06.2005 aj new constant for gSystemsNotFound
// minimum "timeout" is more or less BLOCKING_TIME x ALLOWED_MISSES, currently 60 sec
// maximum "timeout" is POLLING_TIME x ALLOWED_MISSES currently 150 sec
const int ALLOWED_MISSES = 15;

// 31.05.2005 aj changed name "gChain" to "gServer" to make it clear that this variable refers to the ISup Server not the MRTS Chain
string gServer;
// using variable of type mapping for the cache because it is easier
mapping gCache;
// 10.06.2005 aj using gSystemsNotFound to store the systems which could not be found in the work function
// and therefore could not be updated
// this prevents us from not noticing a system which is not updated for a long time
mapping gSystemsNotFound;

bool gIsActive;


main()
{
	int res;
	bool ret;
	dyn_string type;
	dyn_string typeElements;

	if (isServerA(getHostname()))
		gServer = "A";
	else if (isServerB(getHostname()))
		gServer = "B";
	else
	{
		sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " main() >> stopping initialisation due to: host " + getHostName() + " is neither A nor B");
		DebugTN("sgMRTS >> main() >> stopping initialisation due to: host " + getHostName() + " is neither A nor B");
		return;
	}

        // PW/AJ 29 July 2008
	// To initialize devices Name because of various radars lines changes
        sgMRTSInitDevicesName();

	//DebugTN("sgMRTS starting");
	sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " main() >> sgMRTS starting up, initializing tables and establishing dpQueryConnects");

	// connect to ClearMRTSCache but don't call work function immediately
	res = dpConnect("clearCache",FALSE,"MRTS.ClearMRTSCache");
	if (res != 0)
	{
		sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " main() >> stopping initialisation due to: dpConnect to clearCache didn't work, returned: " + res);
		DebugTN("sgMRTS >> main() >> stopping initialisation due to: dpConnect to clearCache didn't work, returned: " + res);
		return;
	}

	// connect to the DPE which tells us if we are active or not
	// write state into global variable
	// in all work functions check before if the server is active and only then do the actions,
	// if passive stop
	// like this the dpConnectQueries are established once and don't need to be established everytime when doing a switchover
	// -> hopefully more performant switchover :-)
	res = dpConnect("determineActiveServer",ACTIVE_CHAIN);
	if (res != 0)
	{
		sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " main() >> stopping initialisation due to: dpConnect to determineActiveServer didn't work, returned: " + res);
		DebugTN("sgMRTS >> main() >> stopping initialisation due to: dpConnect to determineActiveServer didn't work, returned: " + res);
		return;
	}

	// used to distinguish the different types and to build the sql string
	// get all the different possibilities for the sql, all types for NodeA and then all types for NodeB
	type = dpNames("MRTS.Components.Node*.SNMPData.*","sgMRTS");

	//DebugTN("sgMRTS >> ", dpNames("MRTS.Components.Node*.SNMPData.*","sgMRTS"));

	// init checks if db is already initialised
	sgDBInit();

	// looks like it should be possible to replace sgDB easily with (global) variables of datatype "mapping"
	// as the functionality seems to be the same
	// like table = mappingvariablename, key = mappingkey, value = mappingvalue
	// also here mappings could be used of course, however, currently use sgDB

	// init matching and conversion tables
	// probably the elements for the dpGet should be passed in addition as they might be different
	res = initTables("sgMRTSMatchingTable", "MatchingTable");
	if (res < 0)
	{
		sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " main() >> stopping initialisation due to: initTables() was not successful for sgMRTSMatchingTable, MatchingTable");
		DebugTN("sgMRTS >> main() >> stopping initialisation due to: initTables() was not successful for sgMRTSMatchingTable, MatchingTable");
		return;
	}

	res = initTables("sgMRTSConversionTable", "ConversionTable");
	if (res < 0)
	{
		sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " main() >> stopping initialisation due to: initTables() was not successful for sgMRTSConversionTable, ConversionTable");
		DebugTN("sgMRTS >> main() >> stopping initialisation due to: initTables() was not successful for sgMRTSConversionTable, ConversionTable");
		return;
	}


	// connect to all SNMP inputs
	for (int nbConnects = 1; nbConnects <= dynlen(type); nbConnects++)
	{
		// the parameter "ident" is used to distinguish in the work function between QNH, processes and devices
		// seperate queries are done to have a relatively small table in the callback
		// use only the last element name for ident (e.g. Devices, Processes)
		typeElements = strsplit(type[nbConnects],".");

		// separate query for NodeA and NodeB just to keep the tables small and have only data for one node in the work function
		// and to avoid duplicates(one from A one from B) having the same "name", otherwise extractObjectPrefixValue() would be more complicated
		// duplicates within one node are not expected as SNMP polltime > BLOCKING_TIME

		// add ".**" to get all the levels below, as we have _online.._value we will get the leaves in any case

		// 13.06.2005 changed wantsanswer to FALSE,
		// otherwise SNMP values of DB are written to the sgFwSystems
		// the problem is that in this case the WatchDog is not reloaded!!!!!
		// this WD-issue might be depending if WD has expired alredy before? otherwise it is ok?
		// therefore if no data is received anymore the states would stay the same
		// only show new values if they really have been received
		// at startup don't do anything
		res = dpQueryConnectSingle("updateObjects", FALSE, typeElements[dynlen(typeElements)],
																"SELECT '_online.._value' FROM '" + type[nbConnects] + ".**'",
																BLOCKING_TIME);

		//DebugTN("SELECT '_online.._value' FROM '" + type[nbConnects] + ".**'");
		if (res != 0)
		{
			sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " main() >> stopping initialisation due to: dpQueryConnectSingle failed for: " + type[nbConnects] + " returned: " + res);
			DebugTN("sgMRTS >> main() >> stopping initialisation due to: dpQueryConnectSingle failed for: " + type[nbConnects] + " returned: " + res);
			return;
//			DebugTN("sgMRTS >> dpQueryConnectSingle failed for: " + type[nbConnects]);
		}
	}

	// dpQueryConnect for CMD
	// don't trigger callback everytime MRTS is started up (dpConnect is established),
	// otherwise commands will be sent at startup automatically!!
	// blocking time not helpful for CMDs as there might not be many commands within several seconds :-)
	res = dpQueryConnectSingle("sendCMD", FALSE, "CMD",
														 "SELECT '_online.._value' FROM 'MRTS.Commands.**'",
														 0);
	if (res != 0)
	{
		sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " main() >> stopping initialisation due to: dpQueryConnectSingle for Commands failed, returned: " + res);
		DebugTN("sgMRTS >> main() >> stopping initialisation due to: dpQueryConnectSingle for Commands failed, returned: " + res);
		return;
	}

	// 08.06.2005 aj added automatic time distribution of the pollgroups
	// everytime the SNMP manager is restarted set the synchronisation time for the pollgroups
	// so that the pollgroups are not triggered exactly at the same time
	dpConnect("setSyncTime","_Connections.Driver.ManNums","_Connections_2.Driver.ManNums");

	//DebugTN("sgMRTS dpQueryConnects established");
	sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " main() >> sgMRTS initialization finished, dpQueryConnects established");

}

void determineActiveServer(string DPE, string activeServer)
{
	clearCache();

	gIsActive = (gServer == activeServer);

	sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " determineActiveServer() >> activeServer is " + activeServer);

	// FOR TEST ONLY, AS PROJECT IS RUNNING ON DIFFERNT PC THAN THE PC WITH THE NG FOR DEVELOPMENT CURRENTLY
	// REMOVE!!!!!!!!!!!!!!!!!!
	// gIsActive = TRUE;
	// REMOVE!!!!!!!!!!!!!!!!!!
}

void setSyncTime(string connDPE, dyn_int manNums, string connDPE_2, dyn_int manNums_2)
{
	time syncTime, currentTime;
	int h24,min;

	// if not running on active server don't do anything!!
	if (!gIsActive)
		return;

	// check if on one of the two PCs the SNMP driver is running (num -1 is used)
	// like this the syncTime is also set if one SNMP driver is stopped
	// apparently this is even necessary as stopping or restarting one of the SNMP managers
	// messes up the polling times
	if ( (dynContains(manNums,1) > 0) || (dynContains(manNums_2,1) > 0) )
	{
		currentTime = getCurrentTime();

		min = minute(currentTime) + SYNC;
		// check if the syncTime is in the next hour
		if ( min > 59 )
		{
			min -= 60;
			h24 = hour(currentTime) + 1;
		}
		else
		{
			h24 = hour(currentTime);
		}

		// correction if the syncTime is on the next day
		// day doesn't need to be incremented as the syncTime is "daily"
		if (h24 > 23)
			h24 -= 24;

		syncTime = makeTime(1970,1,2,h24,min);

		// Pollgroups hardcoded because they usually should not change and then it is easier
		// polling time is currently 10 sec, the 4 pollgroups are distributed within those 10 seconds as seen below
		dpSet("_MRTS_General.SyncTime", syncTime + 1,
					"_MRTS_Devices_A.SyncTime", syncTime + 3,
					"_MRTS_Devices_B.SyncTime", syncTime + 6,
					"_MRTS_Processes.SyncTime", syncTime + 9);
	}

}

void clearCache(string dpe="", bool value=TRUE)
{
	if (value)
	{
		//DebugTN("sgMRTS >> cache before:",gCache);
		mapping emptyMapping;
		gCache = emptyMapping;
		// 10.06.2005 aj clearing gSystemsNotFound when Cache is cleared
		// either due to forcToUKN/watchdog and then the systems are set to UKN in any case
		// or when doing a switchover and in this case we have to start again with counting as well
		gSystemsNotFound = emptyMapping;

		//DebugTN("sgMRTS >> cache after:",gCache);
		if ( mappinglen(gCache) > 0 )
			sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " clearCache() >> clear cache failed !! len: " + mappinglen(gCache));
		else
			sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " clearCache() >> cleared MRTS cache, OK");
	}
}

void sendCMD(string ident, dyn_dyn_anytype val)
{
	int res;

	// if not running on active server don't do anything!!
	if (!gIsActive)
		return;

	//DebugTN("sgMRTS >> cmd",val);

	// start with 2 as usual
	for (int nbCMD = 2; nbCMD <= dynlen(val); nbCMD++)
	{
		// if command is to attach/detach a line
		// strpos expects a string and apparently can't do the conversion automatically in this case
		if (strpos( (string) val[nbCMD][1],"Line") >= 0)
		{
			res = lineCMD(val[nbCMD][1],val[nbCMD][2]);

			if (res < 0)
				sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " sendCMD() >> lineCMD did not finish properly for " + val[nbCMD][1] + ", " + val[nbCMD][2] + " returned: " + res);

		}

		// or start/stop a process
		// strpos expects a string and apparently can't do the conversion automatically in this case
		else if (strpos( (string) val[nbCMD][1],"Process") >= 0)
		{
			res = processCMD(val[nbCMD][1],val[nbCMD][2]);

			if (res < 0)
				sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " sendCMD() >> processCMD did not finish properly for " + val[nbCMD][1] + ", " + val[nbCMD][2] + " returned: " + res);

		}
		else
		{	// write to history
			sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " sendCMD() >> could not recognize the command: " + ((string) val[nbCMD][1]) + " it is neither Line nor Process");
			//DebugTN("sgMRTS >> could not recognize CMD");
		}
	}
}

int lineCMD(string cmdDPE, string value)
{
	int res;
	dyn_string splitCMD;
	string radar;
	string line;
	dyn_string matchingTableKeys;
	string deviceName;
	dyn_dyn_anytype deviceTable;
	dyn_string deviceDPEs;
	dyn_string DPEs;
	int CMD;
	dyn_int CMDs;

	//DebugTN("sgMRTS >> command", cmdDPE,value);

	// check if DPE attach or detach has been written, as one DPE is used for attach and a second one for detach
	// determine the value which has to be written to the device command
	// there is only one DPE on SNMP side with different values
	// capital A and D !! (like DPEs)
	if (strpos(cmdDPE,"Attach") >= 0)
		CMD = CMD_ATTACH;
	else if (strpos(cmdDPE,"Detach") >= 0)
		CMD = CMD_DETACH;
	else
	{
		sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " lineCMD() >> command is neither Attach nor Detach: " + cmdDPE + " with value: " + value);
		return -1; // error: neither attach nor detach - should not be
	}

	// cmd should be "RADAR$LINE" e.g. "GV1M$LineA"
	// cmd is always done for both nodes at the same time
	splitCMD = strsplit(value,CMD_DELIMITER);

	if (dynlen(splitCMD) == 2)
	{
		radar = splitCMD[1];
		line = splitCMD[2];
	}
	else
	{
		sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " lineCMD() >> command value could not be splitted correctly: " + value + " for cmdDPE: " + cmdDPE);
		return -2; 		// splitting of command failed
	}

	// use matchingtables to convert radarname to radarnumber
	// name in matchingtable should be "Components.Radars.GV1M.Components.LineB"
	// therefore built a string like this
	// the problem is that this string is a value, not a key
	matchingTableKeys = sgDBTableKeys("DevicesMatchingTable");
	for (int nbKeys = 1; nbKeys <= dynlen(matchingTableKeys); nbKeys++)
	{
		if (sgDBGet("DevicesMatchingTable", matchingTableKeys[nbKeys]) == ("Components.Radars." + radar + ".Components." + line) )
		{
			deviceName = matchingTableKeys[nbKeys];
			break;
		}
	}

	// check if found
	if (deviceName == "")
	{
		sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " lineCMD() >> deviceName could not be found for radar: " + radar + " and line: " + line);
		return -3;   // device not found
	}

	// find DPE with corresponding devicename
	dpQuery("SELECT '_online.._value' FROM 'MRTS.Components.Node*.SNMPData.Devices.*.Name'", deviceTable);

	for (int nbDevices = 2; nbDevices <= dynlen(deviceTable); nbDevices++)
	{
		if (deviceTable[nbDevices][2] == deviceName)
		{
			// device number could be theoretically different for node A and node B ???
			// therefore search for both without stopping after the first
			dynAppend(deviceDPEs, deviceTable[nbDevices][1]);
		}
	}

	// only if the DPEs in Node A and B have been found it is ok

	// for test "> 2"  as Node B doesn't send data
	// for operation it should be "!=2" to be sure ??
	// if (dynlen(deviceDPEs) != 2)
	if (dynlen(deviceDPEs) > 2)
	{
		sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " lineCMD() >> the deviceName: " + deviceName + " was found too often (>2)");
		return -4;  // found too many devices
	}

	// write to corresponding cmd DPE

	// replace "Name" by "Command"
	// could use strreplace, problem if there is "Name" somewhere else in the dpename should not be the case but ..
	// again without the "." otherwise too much might be cut off, cuts of characters not the string

	for (int nbDPEs = 1; nbDPEs <= dynlen(deviceDPEs); nbDPEs++)
	{
		dynAppend(DPEs, (strrtrim(deviceDPEs[nbDPEs],"Name") + "Command"));
		// just for the dpSet afterwards
		dynAppend(CMDs,CMD);
	}

	//DebugTN("sgMRTS >> write to device: ", DPEs, CMDs);
	res = dpSet(DPEs,CMDs);
	if (res == 0)
		return 1; // if ok
	//else

	sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " lineCMD() >> dpSet didn't work properly for: " + DPEs + " and: " + CMDs);
	return -5;
}

int processCMD(string cmdDPE, string processName)
{
	int res;
	string CMD;
	string node;
	dyn_dyn_anytype processTable;
	string processDPE;
	string DPE;

	// expected to get the correct processName already, no need to search for it in the matchingTable
	// otherwise sgFwSystem would have to be written and then processName has to be found in matchingTable

	//DebugTN("processCMD", cmdDPE,processName);

	// check if Start or Stop a process, according to the DPE which was set
	if (strpos(cmdDPE,"Start") >= 0)
		CMD = CMD_START;
	else if (strpos(cmdDPE,"Stop") >= 0)
		CMD = CMD_STOP;
	else
	{
		sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " processCMD() >> command is neither Start nor Stop: " + cmdDPE + " for processName: " + processName);
		return -1; // error: neither start nor stop - should not be
	}

	// find DPE with corresponding devicename, processes can be started/stopped per node and not for both nodes together
	// find out which node should be used via command DPE
	// "NodeA" or "NodeB" in the DPE name, extract only "A" or "B", "Node" is in the query already
	node = substr(cmdDPE, (strpos(cmdDPE,"Node") + 4) , 1);
	//DebugTN("sgMRTS >> node for process command", node, cmdDPE);

	dpQuery("SELECT '_online.._value' FROM 'MRTS.Components.Node"+ node +".SNMPData.Processes.*.Name'", processTable);

	for (int nbProcesses = 2; nbProcesses <= dynlen(processTable); nbProcesses++)
	{
		if (processTable[nbProcesses][2] == processName)
		{
			processDPE = processTable[nbProcesses][1];
			// only one is expected to be found, therfore stop
			break;
		}
	}

	// if not found error
	if (processDPE == "")
	{
		sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " processCMD() >> processDPE could not be found for processName: " + processName);
		return -3;   // process not found
	}

	// replace "Name" by "Command" again, same as for the lines
	// could use strreplace, problem if there is "Name" somewhere else in the dpename should not be the case but ..
	// again without the "." otherwise too much might be cut off, cuts of characters not the string

	DPE = strrtrim(processDPE,"Name") + "Command";

	//DebugTN("sgMRTS >> write to process: ", DPE, CMD);
	res = dpSet(DPE,CMD);
	if (res == 0)
		return 1; // if ok

	//else
	sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " processCMD() >> dpSet didn't work properly for: " + DPE + " and: " + CMD);
	return -1;

}

int initTables(string dpTypeRef, string tablePostfix)
{
	//DebugTN("sgMRTS >> dpGetRefsToDpType", dpTypeRef, dpGetRefsToDpType(dpTypeRef));

	dyn_dyn_string tables;
	dyn_string tablesDPE;
	string tableName;
	dyn_string tDPE;
	bool bRet;
	dyn_string in;
	dyn_string out;

	// get all corresponding tables for MRTS
	tables = dpGetRefsToDpType(dpTypeRef);

	for (int nbTables = 1; nbTables <= dynlen(tables); nbTables++)
	{
		// init tables

		// just to be safe, check the DPT
		if (tables[nbTables][1] == "sgMRTS")
		{
			// use the DPE Name (only the element name itself) as name for the matching table
			tDPE = strsplit(tables[nbTables][2],".");
			tableName = tDPE[dynlen(tDPE)] + tablePostfix;
			bRet = sgDBCreateTable(tableName);
			if (!bRet)
			{
				// DebugTN("sgMRTS: unable to create table '" + tableName);
				sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " initTables() >> unable to create table (sgDBCreateTable): " + tableName + " of type: " + tablePostfix);
				return -1;
			}
			else
			{
				// DP name and elements of MT hardcoded! (but should not change)
				// attention: for conversion tables there is also ".Label" in the structure but currently not used??
				// 						for matching tables there could be another parameter to distinguish lines from other devices??
				// in and out have to have the same number of elements, or at least in < out
				dpGet("MRTS." + tables[nbTables][2] + ".In",in,
				      "MRTS." + tables[nbTables][2] + ".Out",out);
				for (int element = 1; element <= dynlen(in); element++)
				{
					// in = key = processName
					// out = value = name of sgFWSystem
					sgDBSet(tableName,in[element],out[element]);
				}
			}

			// just to be safe, outside the second if as mtDPE is used outside
			dynClear(tDPE);
			dynClear(in);
			dynClear(out);
		}
	}
	return 1;
}



// one function "updateObjects" might be enough as they are quite similar and one can use "ident" to distinguish
// maybe make a separate work function for System and NodeInformation as they are a bit different (no matchingTable needed)
void updateObjects(string ident, dyn_dyn_anytype val)
{
	string dpe;
	int value;
	string strValue;
	int returnedValue;
	int valueOp;
	int returnedValueOp;
	int res;
	string prefix;
	string returnedPrefix;
	string matchingTable;
	dyn_string matchingTableKeys;
	dyn_string dpesPreStatus, dpesLinesPreStatus, dpesLabel1, dpesLabel2;
	dyn_string values, valuesLines, valuesTech, valuesOp;
	string processName;
	dyn_string sgFwSystemName;
	int cutOff;
	string namePostfix;
	string valuePostfix;
	string conversionTable;
	string conversionTableLabel;
	string concernedNode;
	dyn_string nameElements;
	bool isLine, isQNH;
	bool techValueInCache;
	bool QNHValueInCache;

	//time start, stop;
	dyn_dyn_anytype valModified;
	bool notFound;

	// if not running on active server don't do anything!!
	if (!gIsActive)
		return;

	// 27.05.2005 aj adding supervision if MRTS script is running or not
	// otherwise if the SNMP manager runs but not the MRTS script watchdogs will not expire
	// but states are not updated!!!!

	// dpSet is only done if data is received (in work function)
	// only in active server as the other one isn't doing anything
	// watchdog is parameterized to this DPE
	// so if the MRTS script is not running on the active server
	// set everything to UKN
	dpSet("MRTS.ProcessingData",TRUE);
	// 27.05.2005 aj adding supervision if MRTS script is running or not


	// 17.06.2005 aj taking this part out of extractObjectPrefixValue()
	// as we have different queries for both nodes (always separated)
	// we can use any line in the valueTable to determine the node to which the callback refers
	// the node is needed later for the cache in extractObjectPrefixValue()
	// that it has to be done only once it is done here and then passed to the function
	// in addition this avoids having problems in case the valueTable gets empty
	// (in practice this might not be the case as there are more DPEs parameterized than used
	// "Node" could be in the string more often but the first occurance is what we need
	concernedNode = substr( (string) val[2][1], (strpos( (string) val[2][1],"Node")) , 5);
	// DebugTN("sgMRTS >> NODE", concernedNode, val[2],val[3]);


	//start = getCurrentTime();

	//DebugTN("sgMRTS >> updateObjects:", ident);

	// maybe better to use "mapping" variables instead of the switch()
	switch(ident)
	{
		case "Processes":
			namePostfix = "Name";
			valuePostfix = "Status";
			conversionTable = "ProcessStatusConversionTable";
			matchingTable = "ProcessesMatchingTable";
			// assign matching table
			// instead just for test
//			dpGet("ISup_G:MRTS.Components.NodeA.SNMPData.Processes.Process06.Name", processName);
			// sgFwSystemName is relative to the node name
			// e.g. "MRTS.Components.NodeA.Components.NTPComponents.NTPI" -> "Compontents.NTPComponents.NTPI"
//			sgFwSystemName = "Components.NTPComponents.NTPI";
//			matchingTable[1][1] = processName;
//			matchingTable[1][2] = sgFwSystemName;
//
//			dpGet("ISup_G:MRTS.Components.NodeA.SNMPData.Processes.Process07.Name", processName);
//			sgFwSystemName = "Components.NodeStatusComponents.MRTS_101";
//			matchingTable[2][1] = processName;
//			matchingTable[2][2] = sgFwSystemName;
			// end just for test

			break;

		case "Devices":
			namePostfix = "Name";
			valuePostfix = "TechStatus";
			conversionTable = "DeviceStatusConversionTable";
			conversionTableLabel = "DeviceLabelConversionTable";
			matchingTable = "DevicesMatchingTable";
			break;

		case "QNH":
			namePostfix = "Index";
			valuePostfix = "Status";
			conversionTable = "QNHAreaStatusConversionTable";
			matchingTable = "QNHAreasMatchingTable";
			// 13.06.2005 aj show QNH value
			isQNH = TRUE;
			break;

		case "Measures":
			// currently not evaluated
			return;

		/* 18.05. aj, SysControlMode is not used anymore, no input left in "System"
		   currently dpQueryConnect will be done for the two commands (done automatically)
		   but would not be needed, for the commands the default is called -> don't do anything
		case "System":
			// SNMP data is not in a table but done with the same dpQueryConnect as it is easier
			res = writeDirectData(val,"SysControlMode","Components.SysControlMode.PreStatus");
			if (res < 0)
				sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"updateObjects() >> writeDirectData for SysControlMode did not work properly, returned: " + res);
			// and don't do anything else
			return;
		*/

		case "NodeGeneral":
			// SNMP data is not in a table but done with the same dpQueryConnect as it is easier
			res = writeDirectData(val,"NodeTechStatus","Components.NodeStatusComponents.NodeTechStatus.PreStatus");
			if (res < 0)
				sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " updateObjects() >> writeDirectData for NodeTechStatus did not work properly, returned: " + res);
			// 04.11.2005 aj added new state of AST_GWY
			res = writeDirectData(val,"AST_GWYStatus","Components.NodeStatusComponents.AST_GWYStatus.PreStatus");
			if (res < 0)
				sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " updateObjects() >> writeDirectData for AST_GWYStatus did not work properly, returned: " + res);
			// and don't do anything else
			return;

		default:
			// in case there would be anything else, stop
			return;

	}
	// store original table in table which will get smaller every time one entry is found
	valModified = val;

	// read matching table
	matchingTableKeys = sgDBTableKeys(matchingTable);

	dyn_string temp;
	//DebugTN("sgMRTS >> valTable start",dynlen(valModified),valModified);

	// going through the matching table and extract the value for all needed objects
	for (int nbObjects = 1; nbObjects <= dynlen(matchingTableKeys); nbObjects++)
	{

		// get sgFwSystem name for corresponding object name
		sgFwSystemName = sgDBGet(matchingTable, matchingTableKeys[nbObjects]);
		// check if device is a line or not
		// lines are only possible in devices
		if (ident == "Devices")
		{
			// use name of sgFwSystem to check if it is a Line or not
			nameElements = strsplit(sgFwSystemName[1],".");
			// it is recognized as a line if the name is Components.Radars.****.*Line* -> attention when changing the DPT
			// it could only be checked for "Line" but who knows if it is somewhere else as well :-)
			if (dynlen(nameElements) >= 3)  // can't be a radar line if it is shorter
				isLine = ( (nameElements[1] == "Components") && (nameElements[2] == "Radars") && ( strpos(nameElements[dynlen(nameElements)],"Line") >= 0) );
		}
		else
			isLine = FALSE;

		//DebugTN("sgMRTS:",matchingTable[nbObjects][1],"val",val);
		// for performance improvements the objects which have been found are removed from val
		// therefore the new valueTable is returned as a reference from extractObjectPrefixValue
		// empty, as returnedPrefix is used to bypass the search for the prefix if we have it already
		notFound = false;
		returnedPrefix = "";
		res = extractObjectPrefixValue(concernedNode, matchingTableKeys[nbObjects], namePostfix, valuePostfix, valModified, returnedPrefix, returnedValue);
		// check res
		// if res = -2 then the system was not found several times -> set it to UKN (don't stop the loop!)
		if (res < -1)
		{
			sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " updateObjects() >> extractObjectPrefixValue for " + matchingTableKeys[nbObjects] + " was not found several times, will be set to UKN, returned: " + res);
			notFound = true;
			// but don't stop here!!
		}
		// if name or value not found go to next iteration, distinguish between name not found and value not found
		else if (res < 0) // error
		{
			sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " updateObjects() >> extractObjectPrefixValue for " + matchingTableKeys[nbObjects] + " didn't finish properly, returned: " + res);
			// also for a line it doesn't help to continue as TechValue AND OpValue are needed to get the overall state for the line
			// the same is true for QNH if the index is not found
			continue;
		}
		else if (res < 1) // not found
		{
			sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " updateObjects() >> extractObjectPrefixValue for " + matchingTableKeys[nbObjects] + " didn't finish properly, returned: " + res);
			// also for a line it doesn't help to continue as TechValue AND OpValue are needed to get the overall state for the line
			// QNH if the status of the area is not found the value could still be found
			// but it might not make to much sense, stop
			continue;
		}

		// not changed -> found in cache
		// if it is not a line we can stop
		// if it is a line the OpStatus might have changed -> maybe new overall state
		if (res == 100)
		{
			if (isLine)
				techValueInCache = TRUE;
			// 13.06.2005 aj don't stop if it is QNH
			else if (isQNH)
				QNHValueInCache = TRUE;
			else
				continue;
		}
		else
		{
			techValueInCache = FALSE;
			QNHValueInCache = FALSE;
		}

		prefix=returnedPrefix;
		value=returnedValue;

		//DebugTN("extracted prefix:", prefix, "extracted value:", value);

		// calc dpe for writing the data is made out of prefix and sgFwSystemname in matchingTable
		// find SNMPData and cut off everything afterwards, the "." stays and must not be in the matchingTable
		// sgFwSystemName[1] because of sgDB
		cutOff = strpos(prefix,"SNMPData");
		dpe = substr(prefix,0, cutOff) + sgFwSystemName[1];

		//DebugTN("extracted prefix:", prefix, "extracted value:", value, "dpe:", dpe);

		if (isLine)
		{

			// if TechStatus was not found no need to look for OpStatus
			// just set it to UKN as well
			if (notFound)
				valueOp = -1;
			else
			{
				// searching the same name twice is not efficient, use solution below with for loop?
				// prefix will be the same as before therefore we don't need to calculate again afterwards and can just overwrite it
				// for performance improvements the objects which have been found are removed from val
				// therefore the new valueTable is returned as a reference from extractObjectPrefixValue
				// performance: in addition we don't need to search for the object again as we have the prefix from before
				// therefore we can bypass the search via passing the found prefix via returnedPrefix!!
				returnedPrefix = prefix;
				res = extractObjectPrefixValue(concernedNode, matchingTableKeys[nbObjects], namePostfix, "OpStatus", valModified, returnedPrefix, returnedValueOp);

				//DebugTN("sgMRTSsss >> ", res, returnedValueOp,returnedPrefix);
				// if res = -2 then the system was not found several times -> set it to UKN (don't stop the loop!)
				if (res < -1)
				{
					sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " updateObjects() >> extractObjectPrefixValue for " + matchingTableKeys[nbObjects] + " was not found several times, will be set to UKN, returned: " + res);
				}
				else if (res < 0) // error
				{
					sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " updateObjects() >> extractObjectPrefixValue for " + matchingTableKeys[nbObjects] + " with OpStatus didn't finish properly, returned: " + res);
					continue;
				}
				else if (res < 1)
				{
					sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " updateObjects() >> extractObjectPrefixValue for " + matchingTableKeys[nbObjects] + " with OpStatus didn't finish properly, returned: " + res);
					continue;
				}

				// if both values have been in the cache -> go to next iteration
				// otherwise new overall value has to be determined
				if ( (res == 100) && (techValueInCache) )
				{
					// DebugTN("sgMRTS >> both values for a Line have been found in the cache");
					continue;
				}

				// if ok
				valueOp=returnedValueOp;
			}

			// for lines the status needs to be "calculated"
			// string as the conversion is done "automatically" there
			strValue = getLineStatus(value, valueOp);
			//DebugTN("sgMRTS >> calcvalues", value,valueOp,strValue);

			dynAppend(dpesLabel1, dpe + ".Label1");
			dynAppend(valuesTech, value);
			dynAppend(dpesLabel2, dpe + ".Label2");
			dynAppend(valuesOp, valueOp);
			dynAppend(dpesLinesPreStatus, dpe + ".PreStatus");
			dynAppend(valuesLines, strValue);

		}// end if line
		// 13.06.2005 aj
		// if QNH then we need also the value to be displayed as a label
		else if (isQNH)
		{

			// write at least the status of the QNH area, regardless of the result for the value
			// 22.06.2005 aj unless it was found in the cache before
			if (!QNHValueInCache)
			{
				dynAppend(dpesPreStatus,dpe + ".PreStatus");
				dynAppend(values,value);
			}

			// if the QNH state has not been found many times just put the QNH value to UKN as well
			if (notFound)
				valueOp = -1;
			else
			{
				// again no need to search vor the prefix if it has been found already
				returnedPrefix = prefix;
				res = extractObjectPrefixValue(concernedNode, matchingTableKeys[nbObjects], namePostfix, "Value", valModified, returnedPrefix, returnedValueOp);

				// if res = -2 then the system was not found several times -> set it to UKN (don't stop the loop!)
				if (res < -1)
				{
					sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " updateObjects() >> extractObjectPrefixValue for " + matchingTableKeys[nbObjects] + " was not found several times, will be set to UKN, returned: " + res);
				}
				else if (res < 0) // error
				{
					sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " updateObjects() >> extractObjectPrefixValue for " + matchingTableKeys[nbObjects] + " with Value didn't finish properly, returned: " + res);
					continue;
				}
				else if (res < 1)
				{
					sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " updateObjects() >> extractObjectPrefixValue for " + matchingTableKeys[nbObjects] + " with Value didn't finish properly, returned: " + res);
					continue;
				}

				// if ok
				valueOp = returnedValueOp;
			}

			// -1 is used if it should be set to UKN
			if (valueOp != -1)
			{
				sprintf(strValue,"%4d",valueOp);
				strreplace(strValue," ","0");
			}
			else
				strValue = "unknown";

			//DebugTN("sgMRTS >> qnh value,", valueOp, strValue);
			dynAppend(dpesLabel1, dpe + ".Label1");
			dynAppend(valuesTech, strValue);
		} // end QNH value
		else
		{
			// if no line
			dynAppend(dpesPreStatus,dpe + ".PreStatus");
			dynAppend(values,value);
		}
		//DebugTN("sgMRTS >> valTable middle",dynlen(valModified));
	}

	//DebugTN("sgMRST >>", dpesLinesPreStatus,valuesLines);

	//DebugTN("sgMRTS >> valTable end",dynlen(valModified),valModified);

	// only if there is really data
	// convert the value to sgFwStates and write it to the sgFwSystem
	// conversion table is optional, values = dyn_string as the values are used as string for sgDB in any case
	// a bit "messy" but like this we can use the same function for converted and raw values
	if (dynlen(values) > 0)
		res = writeObjectValues(dpesPreStatus, values, conversionTable);
		// check res

	if (dynlen(valuesLines) > 0)
	{
		res = writeObjectValues(dpesLinesPreStatus, valuesLines); // without conversion table as those values are already converted
		// check res
		if (res < 0)
			sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " updateObjects() >> writeObjectValues failed for dpes " + dpesLinesPreStatus + " and values: " + valuesLines + ", returned: " + res);
	}

	// lines and other devices are mixed here!!! therefore write if there is something in the variables
	// conversionTable might be different then the one above!
	if (dynlen(valuesTech) > 0)
	{
		res = writeObjectValues(dpesLabel1, valuesTech, conversionTableLabel);
		// check res
		if (res < 0)
			sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " updateObjects() >> writeObjectValues failed for dpes " + dpesLabel1 + " and values: " + valuesTech + ", returned: " + res);
	}

	if (dynlen(valuesOp) > 0)
	{
		res = writeObjectValues(dpesLabel2, valuesOp, conversionTableLabel);// different conversion table needed
		// check res
		if (res < 0)
			sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " updateObjects() >> writeObjectValues failed for dpes " + dpesLabel2 + " and values: " + valuesOp + ", returned: " + res);
	}
	//DebugTN("sgMRTS >> time", ident,(getCurrentTime() - start));

}

string getLineStatus(int valueTech, int valueOp)
{
	// possible states (currently):
	// Tech: 2 (starting but set to U/S in conversion table), 3 (OPS), 4 (U/S), 5 (STP), else (UKN)
	// Op: 5 (STP), 9 (SBY), 10 (OPS), else (UKN)

	string value;
	string convertedTechValue;
	string convertedOpValue;
	// possible states are already in conversion tables
	// use conversion tables for this to have only one source for the states
	// conversion table for Tech is part of the table for Op therefore use only one
	dyn_int deviceStates = sgDBTableKeys("DeviceStatusConversionTable");

	// to make it better readable and independant from changes we can use converted value
	// in addition as we have already the conversion here we can skip the conversion when writing
	// 9 and 10 are only for OpStatus, therefore exclude them here
	if ( (valueTech == 9) || (valueTech == 10) )
		convertedTechValue = U_S_STATUS;
	else if (dynContains(deviceStates,valueTech) > 0)
		convertedTechValue = sgDBGet("DeviceStatusConversionTable",valueTech);
	else
		convertedTechValue = UKN_STATUS;

	if (dynContains(deviceStates,valueOp) > 0)
		convertedOpValue = sgDBGet("DeviceStatusConversionTable",valueOp);
	else
		convertedOpValue = UKN_STATUS;

	if (isUKN(convertedTechValue))
		value = UKN_STATUS;
	else if (isUS(convertedTechValue))
		value = U_S_STATUS;
	else if (isSTP(convertedTechValue))
		value = STP_STATUS;
	else if (isOPS(convertedTechValue))
		{
			if (isOPS(convertedOpValue))
				value = OPS_STATUS;
			else if (isSBY(convertedOpValue))
				value = SBY_STATUS;
			else
				value = U_S_STATUS;
		}
	else
		value = U_S_STATUS;

	//DebugTN("sgMRTS >>",valueTech,valueOp,value);

	return value;
}

int extractObjectPrefixValue(string node, string searchObject,
											string namePostfix, string valuePostfix,
											dyn_dyn_anytype &valueTable,
											string &returnPrefix, int &returnValue)
{
	string prefix = "";
	string dpe;
	int value = -1;
	// TechValue and OpValue have the same searchObject!!
	string cacheKey = namePostfix + "_" + searchObject + "_" + valuePostfix;
	bool cacheHit;
	int misses;

	//DebugTN("sgMRTS >> extractObjectPrefixValue");

	// 13.06.2005 aj node is passed to the function and extracted only once in the workfunction
	cacheKey =  node + "_" + cacheKey;
	//DebugTN("sgMRTS >> ", cacheKey);

	// look for the prefix only if we don't have it already
	// for lines we have searched already before therefore not needed anymore

	if (returnPrefix == "")
	{
		// DebugTN("sgMRTS >> search for prefix",searchObject,namePostfix,valuePostfix);
		// find searchObject in valueTable
		// start with 2 because first line is a header
		// first column = dpe
		// second column = value wheras the value can be a name or a status
		// currently duplicates are not checked
		// not a problem if the two nodes are not within one query and SNMP polltime > BLOCKING_TIME
		for (int nbLines=2; nbLines <= dynlen(valueTable); nbLines++)
		{
			if (valueTable[nbLines][2] == searchObject)
			{
				// extract prefix using namePostfix
				// cuts off all characters in namePostfix therefore the "." must not be part of the namePostfix to avoid cutting off too much
				prefix = strrtrim( (string) valueTable[nbLines][1], namePostfix);

				// 31.05.2005 aj
				// added a check to see if the namePostfix was really cut off
				// (resp. if the namePostfix was at the end of the DPE in valueTable[nbLines][1]
				// reason why this has to be checked is because for QNH the name (area index) is "1" and the value can also be "1"
				// therefore if the name is updated within the blocking time but the value is updated only afterwards
				// the value "1" is seen as beeing the area index and the corresponding value is searched
				// and in this case the strrtrim would not be able to remove the namePostfix because it was not there :-)
				// this issue doesn't cause any problem, it just adds another a bit confusing line to the MRTS.SystemHistory
				// and it occurs only if there is a too big delay between the update of the name and the value
				// nevertheless to make it proper this is corrected here with the additional "if" and "else" - before the dynRemove and break was done without check

				if (prefix != valueTable[nbLines][1])
				{
					// just for debug
					//sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " extractObjectPrefixValue() >> Object " + searchObject + "#" + prefix + "#" + (string) valueTable[nbLines][1] + "#" + namePostfix + "#" + nbLines);

					// remove object from table to be faster when searching next time
					// DebugTN("sgMRTS >> remove Line",valueTable[nbLines]);
					dynRemove(valueTable,nbLines);

					//DebugTN("sgMRTS >> prefix", prefix);
					break;
				}
				// otherwise the real name was not found!
				else
				{
					// just for debug
					//sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " extractObjectPrefixValue() >> Object " + searchObject + " was not really found, prefix will be reset " + prefix + "#" + (string) valueTable[nbLines][1] + "#" + namePostfix + "#" + nbLines);
					prefix = "";
				}

			}
		}
	}
	else
	{
		//DebugTN("sgMRTS >> nooooooooooo search for prefix",searchObject,namePostfix,valuePostfix);
		prefix = returnPrefix;
	}

	//DebugTN("sgMRTS >> extract..",prefix,returnPrefix);

	if (prefix == "")
	{	// if searchObject was not found return 0 to tell that it has not change
	  //DebugTN("sgMRTS >> extract..",searchObject,prefix,returnPrefix);
		sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " extractObjectPrefixValue() >> Object " + searchObject + " for " + node + " could not be found in table -> value for Object was not updated within the blockingTime");

		// 10.06.2005 aj increment counter in gSystemsNotFound to avoid not noticing if a system is not updated over a long time
		if (mappingHasKey(gSystemsNotFound,cacheKey))
		{
			misses = gSystemsNotFound[cacheKey];
			misses++;
			if (misses > ALLOWED_MISSES)
			{
				//DebugTN("sgMRTS >> ", gSystemsNotFound);
				sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " extractObjectPrefixValue() >> " + cacheKey + " could not be found in table <" + misses + "> times in a row -> deleted from cache and set to UKN");

				// delete value from cache
				if (mappingHasKey(gCache,cacheKey))
					mappingRemove(gCache,cacheKey);

				mappingRemove(gSystemsNotFound,cacheKey);
				// construct the returnPrefix as a dummy prefix containing the node
				// needs to be done to be able to set the system to UKN afterwards
				returnPrefix = "MRTS.Components." + node + ".SNMPData.DUMMY";
				// -1 is not in conversiontable -> will be UKN
				returnValue = -1;
				// -2 in case system has to be set to UKN
				return -2;
			}
			else
			{
				gSystemsNotFound[cacheKey] = misses;
				//DebugTN("sgMRTS >> ", gSystemsNotFound, misses);
				sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " extractObjectPrefixValue() >> " + cacheKey + " could not be found in table <" + misses + "> times in a row");
			}
		}
		else
		{
			gSystemsNotFound[cacheKey] = 1;
			sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " extractObjectPrefixValue() >> " + cacheKey + " could not be found in table <1> times in a row");
		}
		// end of 10.06.2005


		return 0;
	}
	else
	{

		// concatenate prefix and valuePostfix to get the value-DPE which corresponds to searchObject
		dpe = prefix + valuePostfix;

		// find value-DPE in valueTable
		// another loop through the table, avoidable?
		// maybe put this loop into the if of the loop above
		for (int nbLines=2; nbLines <= dynlen(valueTable); nbLines++)
		{
			if (valueTable[nbLines][1] == dpe)
			{
				// get value of valueDPE in valueTable
				value = valueTable[nbLines][2];

				// remove object from table to be faster when searching next time
				// DebugTN("sgMRTS >> remove Line",valueTable[nbLines]);
				dynRemove(valueTable,nbLines);

				//DebugTN("sgMRTS >> value", value);
				break;
			}
		}

		if ( (value != -1))
		{
			// cache
			// check if a value for this object is in cache
			// and if it is the same

			if ( mappingHasKey(gCache,cacheKey) )
				if (gCache[cacheKey] == value)
				{
					//DebugTN("sgMRTS >> value found in cache for",cacheKey,value);
					cacheHit = true;
				}
				else
				{
					//DebugTN("sgMRTS >> different value in cache for",cacheKey,value,"changed");
					gCache[cacheKey] = value;
				}
			else
			{
				//DebugTN("sgMRTS >> key not found in cache",cacheKey,value,"added");
				gCache[cacheKey] = value;
			}

			// write value and prefix to the references
			// prefix is needed for the write-function
			returnPrefix = prefix;
			returnValue = value;

			// 10.06.2005 aj clear counter in gSystemsNotFound as we received and extracted a value for it
			if (mappingHasKey(gSystemsNotFound,cacheKey))
			{
				mappingRemove(gSystemsNotFound,cacheKey);
				sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " extractObjectPrefixValue() >> " + cacheKey + " was found again -> deleted from gSystemsNotFound");
			}

			if (cacheHit)
				// 100 for test if found in cache
				// value is needed also in this case as it might be a line
				// and to get the overall state of a line Tech and Op are needed but only one might have changed
				return 100;
			else
				return 1;
		}
		else
		{
			// error, searchString was found but not the value
			sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " extractObjectPrefixValue() >> new Value for Object " + searchObject + " for " + node + " at dpe " + dpe + " (constructed with " + prefix + "#" + valuePostfix + "#" + namePostfix + "#" + returnPrefix + ") could not be found in table -> name for Object was updated but not the value");

			// 10.06.2005 aj increment counter in gSystemsNotFound to avoid not noticing if a system is not updated over a long time
			if (mappingHasKey(gSystemsNotFound,cacheKey))
			{
				misses = gSystemsNotFound[cacheKey];
				misses++;
				if (misses > ALLOWED_MISSES)
				{
					//DebugTN("sgMRTS >> ", gSystemsNotFound);
					sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " extractObjectPrefixValue() >> " + cacheKey + " could not be found in table <" + misses + "> times in a row -> deleted from cache and set to UKN");

					// delete value from cache
					if (mappingHasKey(gCache,cacheKey))
						mappingRemove(gCache,cacheKey);

					mappingRemove(gSystemsNotFound,cacheKey);
					returnPrefix = prefix;
					// -1 is not in conversiontable -> will be UKN
					returnValue = -1;
					// -2 in case system has to be set to UKN
					return -2;
				}
				else
				{
					gSystemsNotFound[cacheKey] = misses;
					sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " extractObjectPrefixValue() >> " + cacheKey + " could not be found in table <" + misses + "> times in a row");
				}
			}
			else
			{
				gSystemsNotFound[cacheKey] = 1;
				sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " extractObjectPrefixValue() >> " + cacheKey + " could not be found in table <1> times in a row");
			}
			// end of 10.06.2005

			return -1;
		}
	}
}

int writeDirectData(dyn_dyn_anytype valTable, string searchStr, string sgFwSystem)
{
	int res;
	anytype value;
	string dpe;
	string cacheKey = "directData_" + searchStr;
	bool cacheHit;

	// hardcoded as there should be only one dpe per function call
	for (int lines=2; lines <= dynlen(valTable); lines++)
	{
		if (strpos( (string) valTable[lines][1],searchStr) >= 0)
		{
			//reset cacheHit
			cacheHit = false;
			value = valTable[lines][2];
			dpe = valTable[lines][1];
			cacheKey = substr(dpe, (strpos(dpe,"Node")), 5) + "_" + cacheKey;
			//DebugTN("sgMRTS >> noooooooooooooooode",node);
			// cache
			// check if a value for this object is in cache
			// and if it is the same
			if ( mappingHasKey(gCache,cacheKey) )
				if (gCache[cacheKey] == value)
				{
					//DebugTN("sgMRTS >> value found in cache for",cacheKey,value);
					cacheHit = true;
				}
				else
				{
					//DebugTN("sgMRTS >> different value in cache for",cacheKey,value,"changed");
					gCache[cacheKey] = value;
				}
			else
			{
				//DebugTN("sgMRTS >> key not found in cache",cacheKey,value,"added");
				gCache[cacheKey] = value;
			}


			if (!cacheHit)
			{
				// write to the correct sgFwSystem - node independant
				// "casting" seems to be needed
				res = writeObjectValues(substr( (string) valTable[lines][1],0, strpos( (string) valTable[lines][1],"SNMPData")) + sgFwSystem,
																valTable[lines][2],searchStr + "ConversionTable");
				if (res == 1)
					return 1;
				else
				{
					sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " writeDirectData() >> writeObjectValues failed for dpes " + (substr( (string) valTable[lines][1],0, strpos( (string) valTable[lines][1],"SNMPData")) + sgFwSystem) + " and values: " + valTable[lines][2] + ", returned: " + res);
					return -1;
				}
			}
			else
				// found in cache
				return 100;
		}
	}
	return 0;
}


int writeObjectValues(dyn_string dpes, dyn_string values, string convertTable = "")
{
	dyn_string convertedValues;
	dyn_string keys;
	int res;

	// only if we got raw values
	if (convertTable != "")
	{
		keys = sgDBTableKeys(convertTable);

		for (int nbValue = 1; nbValue <= dynlen(values); nbValue++)
		{
			//convert
			// check necessary??
			if (dynContains(keys,values[nbValue]) > 0)
				convertedValues[nbValue] = sgDBGet(convertTable,values[nbValue]);
			else
				convertedValues[nbValue] = UKN_STATUS;
		}
	}
	else convertedValues = values;

  //DebugTN("sgMRTS >> writeObjectValues", dpes, values, convertedValues);

	res = dpSet(dpes, convertedValues);
	if (res == 0)
		return 1; // if ok
	//else
	sgHistoryAddEvent(MRTS_HISTORY,SEVERITY_SYSTEM,"Server" + gServer + " writeObjectValues() >> error in dpSet for dpes: " + dpes + " with values: " + values + " converted values: " + convertedValues + " returned: " + res);
	return -1;
}

// To initialize the devices Name at start because of various radars lines changes
void sgMRTSInitDevicesName()
{
  string nodesDpName = "MRTS.Components.Node*.SNMPData.Devices.Device*";
  dyn_string names;
  dyn_string emptyDs;

//DebugTN("sgMRTSInitDevicesName called");

  names = dpNames(nodesDpName);
  for (int i = 1; i<=dynlen(names); i++)
  {// create an empty dyn_string to initialize the point
    dynAppend(emptyDs, "");
    // add suffix àt the end of the names
    names[i] = names[i] + ".Name";
  }
  dpSet(names, emptyDs);
}
// sgMRTSInitDevicesName()
