const int BLOCKING_TIME = 3000;
const int NB_VALUES_TYPE1 = 3;
const int NB_VALUES_TYPE2 = 2;
const string EMDIS_SYSTEM_HISTORY = "EMDIS.SystemHistory";
const string EMDIS_HISTORY = "EMDIS.History";
const string LABEL_NORMAL = "OK";
const string LABEL_BATTERY = "BAT";
const string LABEL_UNKNOWN = "UKN";
const string LABEL_BYPASS = "BYP";
const string LABEL_AC = "AC";
const int US_TIME = 600;
const int DEG_TIME = 1800;

string gServer;
bool gIsActive;
// using variable of type mapping for the cache because it is easier
mapping gCache;

main()
{
	int res;

	// get server name, for writing into the history
	if (isServerA(getHostname()))
		gServer = "A";
	else if (isServerB(getHostname()))
		gServer = "B";
	else
	{
		sgHistoryAddEvent(EMDIS_SYSTEM_HISTORY, SEVERITY_SYSTEM, "main() >> stopping initialisation due to: host " + getHostName() + " is neither A nor B");
		DebugTN("sgEMDIS >> main() >> stopping initialisation due to: host " + getHostName() + " is neither A nor B");
		return;
	}

	sgHistoryAddEvent(EMDIS_SYSTEM_HISTORY, SEVERITY_SYSTEM,"Server" + gServer + " main() >> sgEMDIS starting up, establishing dpQueryConnects");

	// connect to ClearEMDISCache but don't call work function immediately
	res = dpConnect("clearCache",FALSE,"EMDIS.ClearEMDISCache");
	if (res != 0)
	{
		sgHistoryAddEvent(EMDIS_SYSTEM_HISTORY, SEVERITY_SYSTEM,"Server" + gServer + " main() >> stopping initialisation due to: dpConnect to clearCache didn't work, returned: " + res);
		DebugTN("sgEMDIS >> main() >> stopping initialisation due to: dpConnect to clearCache didn't work, returned: " + res);
		return;
	}

	// to know active chain, not really necessary except for Commands!!
	res = dpConnect("determineActiveServer",ACTIVE_CHAIN);
	if (res != 0)
	{
		sgHistoryAddEvent(EMDIS_SYSTEM_HISTORY, SEVERITY_SYSTEM,"Server" + gServer + " main() >> stopping initialisation due to: dpConnect to determineActiveServer didn't work, returned: " + res);
		DebugTN("sgEMDIS >> main() >> stopping initialisation due to: dpConnect to determineActiveServer didn't work, returned: " + res);
		return;
	}

	// connect to ClientCommand but don't call work function immediately
	res = dpConnect("clientCommand",FALSE,"EMDIS.ClientCommand");
	if (res != 0)
	{
		sgHistoryAddEvent(EMDIS_SYSTEM_HISTORY, SEVERITY_SYSTEM,"Server" + gServer + " main() >> stopping initialisation due to: dpConnect to clientCommand didn't work, returned: " + res);
		DebugTN("sgEMDIS >> main() >> stopping initialisation due to: dpConnect to clientCommand didn't work, returned: " + res);
		return;
	}

	// get all UPS
	// 12.01.2006 aj, including EMSup UPS -> Type and not Pattern
	//dyn_string UPS = dpNames("EMDIS.UPS.*","sgEMDIS");
	dyn_string UPS = getPointsOfType("sgEMDISUPS");
	dyn_string labelsAC, datapointsAC;

	//DebugTN(UPS);

	for (int cptUPS = 1; cptUPS <= dynlen(UPS); cptUPS++)
	{
		// constructing dyn_strings to set the label for AC
		datapointsAC[cptUPS] = UPS[cptUPS] + ".ACStatus.Label1";
		labelsAC[cptUPS] = LABEL_AC;
		
		// establish dpQueryConnect per UPS
		// no callback at startup - only when values change
		res = dpQueryConnectSingle("calcStateType1",FALSE,UPS[cptUPS],"SELECT '_online.._value' FROM '" + UPS[cptUPS] + ".SNMPDataType1.*'",BLOCKING_TIME);
		res = dpQueryConnectSingle("calcStateType2",FALSE,UPS[cptUPS],"SELECT '_online.._value' FROM '" + UPS[cptUPS] + ".SNMPDataType2.*'",BLOCKING_TIME);

		if (res != 0)
		{
			sgHistoryAddEvent(EMDIS_SYSTEM_HISTORY, SEVERITY_SYSTEM," main() >> stopping initialisation due to: dpQueryConnectSingle failed for: " + UPS[cptUPS] + " returned: " + res);
			DebugTN("sgEMDIS >> main() >> stopping initialisation due to: dpQueryConnectSingle failed for: " + UPS[cptUPS] + " returned: " + res);
			return;
		}
	}
	
	// setting static label for AC at startup, just to be sure
	dpSet(datapointsAC,labelsAC);

	sgHistoryAddEvent(EMDIS_SYSTEM_HISTORY, SEVERITY_SYSTEM,"Server" + gServer + " main() >> sgEMDIS initialization finished, dpQueryConnects established");

}

void calcStateType1(string ident, dyn_dyn_anytype valueTable)
{
	int batteryRemainingTime, outputOnBattery, outputOnByPass;
	int hours, minutes;
	string state, label, UPSName;
	string sMinutes;
	int res;
	bool cacheHit = FALSE;
	string stateAC;
	bool cacheHitAC = FALSE;
	
	//DebugTN("calcState", valueTable);

	// if not running on active server don't do anything!!
	// not really necessary - like this, passive host has less load
	if (!gIsActive)
		return;
	
	UPSName = ident;

	// only do something if all values have been updated, first line is header -> +1
	if	(dynlen(valueTable) != (NB_VALUES_TYPE1 +1))
	{
		//		ERROR!!!!
		sgHistoryAddEvent(EMDIS_SYSTEM_HISTORY, SEVERITY_SYSTEM,"Server" + gServer + " calcState() >> UPS " + UPSName + " did not receive all three values in time, stopping ...");
		return;
	}

	// decode values from table
	for (int cptLines = 2; cptLines <= (NB_VALUES_TYPE1 +1); cptLines++)
	{
		if (strpos( (string) valueTable[cptLines][1],"BatteryRemainingTime") > -1)
		{
			batteryRemainingTime = valueTable[cptLines][2];
			continue;
		}
		if (strpos( (string) valueTable[cptLines][1],"OutputOnBattery") > -1)
		{
			outputOnBattery = valueTable[cptLines][2];
			continue;
		}
		if (strpos( (string) valueTable[cptLines][1],"OutputOnByPass") > -1)
		{
			outputOnByPass = valueTable[cptLines][2];
			continue;
		}
	}

	//DebugTN("sgEMDIS >>",batteryRemainingTime,outputOnByPass,outputOnBattery);
	// calculate state according spec
	// batteryRemainingTime in seconds
	// 0 = UKN or U/S ???
	if ( (batteryRemainingTime < US_TIME) || (outputOnByPass == 1) )
		state = U_S_STATUS;
	else if (batteryRemainingTime < DEG_TIME)
		state = DEG_STATUS;
	else if (outputOnByPass == 2)
		state = OPS_STATUS;
	else
		state = UKN_STATUS;

	//DebugTN("sgEMDIS >> UPSName,state",UPSName,state);

	if (outputOnBattery == 1)
		stateAC = U_S_STATUS;
	else if (outputOnBattery == 2)
		stateAC = OPS_STATUS;
	else
		stateAC = UKN_STATUS;

	//DebugTN("sgEMDIS >> UPSName,stateAC",UPSName,stateAC);

	// concatenate label

	hours = batteryRemainingTime / 3600;
	minutes = (batteryRemainingTime % 3600) / 60;
	sprintf(sMinutes,"%2d",minutes);
	strreplace(sMinutes," ","0");
	label += ( hours + "h" + sMinutes + " ");
	
	// output on battery and output on bypass should not (can't?) occur at the same time
	if (outputOnByPass == 1)
		label += LABEL_BYPASS;
	else if (outputOnBattery == 1)
		label += LABEL_BATTERY;
	else if (outputOnBattery == 2)
		label += LABEL_NORMAL;
	else
		label += LABEL_UNKNOWN;
	
	//DebugTN("sgEMDIS >>",label,UPSName);	

	// check if value in cache
	// cache is only used for state - labels are written everytime
	// labels might change more often (time) and writing the labels should not influence the performance
	// therefore labels can be used for watchdogs
	// but logic is not recalculated everytime as states are in the cache
	cacheHit = findInCache(UPSName,state);
	cacheHitAC = findInCache(UPSName + "AC",stateAC);

	if (cacheHit)
	{
		res = dpSet(UPSName + ".GlobalStatus.Label1",label);
		if (res != 0)
			sgHistoryAddEvent(EMDIS_SYSTEM_HISTORY, SEVERITY_SYSTEM,"Server" + gServer + " calcState() >> error in dpSet for UPS: " + UPSName + " with label: " + label + " returned: " + res);
	}
	else
	{
		res = dpSet(UPSName + ".GlobalStatus.PreStatus",state,
					UPSName + ".GlobalStatus.Label1",label);
		if (res != 0)
			sgHistoryAddEvent(EMDIS_SYSTEM_HISTORY, SEVERITY_SYSTEM,"Server" + gServer + " calcState() >> error in dpSet for UPS: " + UPSName + " with state: " + state + " and label: " + label + " returned: " + res);
	}

	if (!cacheHitAC)
	{
		res = dpSet(UPSName + ".ACStatus.PreStatus",stateAC);
		if (res != 0)
			sgHistoryAddEvent(EMDIS_SYSTEM_HISTORY, SEVERITY_SYSTEM,"Server" + gServer + " calcState() >> error in dpSet for UPS AC: " + UPSName + " with stateAC: " + stateAC + " returned: " + res);
	}
}

void calcStateType2(string ident, dyn_dyn_anytype valueTable)
{
	int batteryRemainingTime, outputStatus;
	int hours, minutes;
	string state, label, UPSName;
	string sMinutes;
	int res;
	bool cacheHit = FALSE;
	string stateAC;
	bool cacheHitAC = FALSE;
	
	//DebugTN("calcStateType2", valueTable);

	// if not running on active server don't do anything!!
	// not really necessary - like this, passive host has less load
	if (!gIsActive)
		return;
	
	UPSName = ident;

	// only do something if all values have been updated, first line is header -> +1
	if	(dynlen(valueTable) != (NB_VALUES_TYPE2 +1))
	{
		//		ERROR!!!!
		sgHistoryAddEvent(EMDIS_SYSTEM_HISTORY, SEVERITY_SYSTEM,"Server" + gServer + " calcStateType2() >> UPS " + UPSName + " did not receive all three values in time, stopping ...");
		return;
	}

	// decode values from table
	for (int cptLines = 2; cptLines <= (NB_VALUES_TYPE2 +1); cptLines++)
	{
		if (strpos( (string) valueTable[cptLines][1],"BatteryRemainingTime") > -1)
		{
			batteryRemainingTime = valueTable[cptLines][2];
			continue;
		}
		if (strpos( (string) valueTable[cptLines][1],"OutputStatus") > -1)
		{
			outputStatus = valueTable[cptLines][2];
			continue;
		}
	}
        

        // for this UPS type, the value must be divided per 100 (Time Thicks)
        batteryRemainingTime = batteryRemainingTime / 100;
        
      	//DebugTN("sgEMDIS.ctl; calcStateType2; UPSName,batteryRemainingTime,outputStatus", UPSName, batteryRemainingTime, outputStatus);
	// calculate state according spec
	// batteryRemainingTime in seconds             // 6:softWareBypass; 9:switchedBypass; 10:hardwareFailureBypass
	if ( (batteryRemainingTime < US_TIME) || (outputStatus == 6)||(outputStatus == 9)||(outputStatus == 10) )
		state = U_S_STATUS;
	else if (batteryRemainingTime < DEG_TIME)
		state = DEG_STATUS;
                                // 2:onLine; 3:onBattery; 
	else if ( (outputStatus == 2) || (outputStatus == 3) )
		state = OPS_STATUS;
	else
		state = UKN_STATUS;

	//DebugTN("sgEMDIS.ctl; calcStateType2; UPSName,state", UPSName, state);

                    // 2:onLine; 6:softWareBypass; 9:switchedBypass; 10:hardwareFailureBypass
	if ( (outputStatus == 2)||(outputStatus == 6)||(outputStatus == 9)||(outputStatus == 10) )
		stateAC = OPS_STATUS;
                    // 3:onBattery; 
        	else if (outputStatus == 3)
		stateAC = U_S_STATUS;
	else
		stateAC = UKN_STATUS;
        
        //DebugTN("sgEMDIS.ctl; calcStateType2; UPSName,stateAC: ", UPSName, stateAC);

	// concatenate label
                
	hours = batteryRemainingTime / 3600;
	minutes = (batteryRemainingTime % 3600) / 60;
	sprintf(sMinutes,"%2d",minutes);
	strreplace(sMinutes," ","0");
	label += ( hours + "h" + sMinutes + " ");
	
	// output on battery and output on bypass should not (can't?) occur at the same time
                            //6:softWareBypass; 9:switchedBypass; 10:hardwareFailureBypass
	if ( (outputStatus == 6)||(outputStatus == 9)||(outputStatus == 10) )
		label += LABEL_BYPASS;
                            
      	else if (outputStatus == 3)    //3:onBattery; 
		label += LABEL_BATTERY;
	else if (outputStatus == 2)     // 2:onLine; 
		label += LABEL_NORMAL;
	else
		label += LABEL_UNKNOWN;
	
	//DebugTN("sgEMDIS >>",label,UPSName);	

	// check if value in cache
	// cache is only used for state - labels are written everytime
	// labels might change more often (time) and writing the labels should not influence the performance
	// therefore labels can be used for watchdogs
	// but logic is not recalculated everytime as states are in the cache
	cacheHit = findInCache(UPSName,state);
	cacheHitAC = findInCache(UPSName + "AC",stateAC);

	if (cacheHit)
	{
		res = dpSet(UPSName + ".GlobalStatus.Label1",label);
		if (res != 0)
			sgHistoryAddEvent(EMDIS_SYSTEM_HISTORY, SEVERITY_SYSTEM,"Server" + gServer + " calcState() >> error in dpSet for UPS: " + UPSName + " with label: " + label + " returned: " + res);
	}
	else
	{
		res = dpSet(UPSName + ".GlobalStatus.PreStatus",state,
					UPSName + ".GlobalStatus.Label1",label);
		if (res != 0)
			sgHistoryAddEvent(EMDIS_SYSTEM_HISTORY, SEVERITY_SYSTEM,"Server" + gServer + " calcState() >> error in dpSet for UPS: " + UPSName + " with state: " + state + " and label: " + label + " returned: " + res);
	}

	if (!cacheHitAC)
	{
		res = dpSet(UPSName + ".ACStatus.PreStatus",stateAC);
		if (res != 0)
			sgHistoryAddEvent(EMDIS_SYSTEM_HISTORY, SEVERITY_SYSTEM,"Server" + gServer + " calcState() >> error in dpSet for UPS AC: " + UPSName + " with stateAC: " + stateAC + " returned: " + res);
	}
}

bool findInCache(string key, string value)
{
	if ( mappingHasKey(gCache,key) )
	{
		if (gCache[key] == value)
		{
			return TRUE;
			//DebugTN("sgEMDIS >> found in cache:",key,value);
		}
		else
		{
			//DebugTN("sgEMDIS >> not found in cache:",key,value,"old:",gCache[key]);
			gCache[key] = value;
			return FALSE;
		}
	}
	else
	{
		//DebugTN("sgEMDIS >> not in cache:",key);
		gCache[key] = value;
		return FALSE;
	}

	// just as default, will never get here
	return FALSE;
}

void determineActiveServer(string DPE, string activeServer)
{
	clearCache();
	
	gIsActive = (gServer == activeServer);

	sgHistoryAddEvent(EMDIS_SYSTEM_HISTORY, SEVERITY_SYSTEM,"Server" + gServer + " determineActiveServer() >> activeServer is " + activeServer);
}


void clearCache(string dpe="", bool value=TRUE)
{
	if (value)
	{
		if ( mappinglen(gCache) == 0 )
		{
			sgHistoryAddEvent(EMDIS_SYSTEM_HISTORY, SEVERITY_SYSTEM,"Server" + gServer + " clearCache() >> but cache is already empty");
			return;
		}
		//DebugTN("sgEMDIS >> clear Cache",gCache);
		mapping emptyMapping;
		gCache = emptyMapping;
		
		if ( mappinglen(gCache) > 0 )
			sgHistoryAddEvent(EMDIS_SYSTEM_HISTORY, SEVERITY_SYSTEM,"Server" + gServer + " clearCache() >> clear cache failed !! len: " + mappinglen(gCache));
		else
			sgHistoryAddEvent(EMDIS_SYSTEM_HISTORY, SEVERITY_SYSTEM,"Server" + gServer + " clearCache() >> cleared EMDIS cache, OK");
	}
}

void clientCommand(string dpe, string command)
{
	int res;
	
	// send command only from active server, of course
	if (!gIsActive)
		return;

	res = system(command);
	if (res != 0)
	{
		sgHistoryAddEvent(EMDIS_HISTORY, SEVERITY_SYSTEM,"command could not be sent to the corresponding client");
		sgHistoryAddEvent(EMDIS_SYSTEM_HISTORY, SEVERITY_SYSTEM,"Server" + gServer + " clientCommand() >> failed, returned: " + res);
	}
	else
		sgHistoryAddEvent(EMDIS_SYSTEM_HISTORY, SEVERITY_SYSTEM,"Server" + gServer + " clientCommand() >> sent: " + command);

}
