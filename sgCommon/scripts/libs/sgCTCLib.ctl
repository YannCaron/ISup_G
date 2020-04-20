

const string  WARNING = "W";
const string  ALARM   = "A";

global bool gCTCTablesLoaded = false;

global dyn_string gModuleName;
global dyn_string gModuleOIDValues;
global dyn_string gModuleTablesName;

dyn_dyn_string  dds;
dyn_string ddsOrder, empty_ds;

mapping ctcStatus;
mapping ctcConfig;

const int CTCName = 1;
const int subModule;

global char lastActiveChain;

global bool loadInProgress = false;
bool gCTCAlreadyConnected;

void sgCTCActiveChainChanged(string dpName1, string activeChain)
{
		if (lastActiveChain != activeChain )
		{	
			lastActiveChain = activeChain;
			// DebugTN("new active chain: " + activeChain);
			sgCTCForceAllCTCToUKN();	
		}
}


void sgCTCLoadTables()
{
	if (loadInProgress == true)
	{
		while (gCTCTablesLoaded != true)
		{
			delay(0,200);	
		}
		return;
	}
		
	loadInProgress = true;
	
	// DebugTN("Will load tables for CTC");
	dpGet("CTC.ConvTables.ModulType.ModuleName", gModuleName);
	dpGet("CTC.ConvTables.ModulType.OIDValue", gModuleOIDValues);
	dpGet("CTC.ConvTables.ModulType.CorrespondingTable", gModuleTablesName);
	
	// DebugTN("ModuleName: " + gModuleName);

	int index = 1;
	
	for (int i = 1; i <= dynlen(gModuleTablesName); i++)
	{
		if (dynContains(ddsOrder, gModuleTablesName[i]) == 0)
		{
			string tableName = gModuleTablesName[i];
			
			// DebugTN("Append table: " + tableName);
			dynAppend(ddsOrder, tableName);
					
			dyn_string ds;
			int  b = dpGet("CTC.ConvTables." + tableName, ds);
			if (b == -1)
				DebugTN("Unable to load table: " + "CTC.ConvTables." + tableName);
				
			
			// DebugTN("Table loaded: " + ds);	
			dynAppend(dds[index], ds);
			index++;
		}
	}
	gCTCTablesLoaded = true;
}

bool sgCTCCheckConfig(string rootName, int slotNumber)
{
	int slotConfig;
	dpGet(rootName + ".Config.Slot_" + slotNumber, slotConfig);
	 		
	// get slot received:
	int slotConfigReceived;
	dpGet(rootName + ".RawConfig.Slot_" + slotNumber, slotConfigReceived);
	
	string key = 	rootName + slotNumber;
	bool s = mappingHasKey(ctcConfig, key);			
	if (s == false)
	{
		// DebugTN("Adding keyfor ctcConfig: " + key);
		// get slot received:
		int slotConfig;
		dpGet(rootName + ".Config.Slot_" + slotNumber, slotConfig);
		// DebugTN("RootName: " + rootName + " Config for slot: " + slotNumber + " is: " + slotConfig);
		ctcConfig[key] = slotConfig;		
	}
	
	// DebugTN("RootName: " + rootName + " Slot received: " + slotConfigReceived + ", );
	if (ctcConfig[key] == slotConfigReceived)
		return true;
		
	return false;
}

void sgUpdateCTCSubComponent(string rootName, int slotConfig, string slotNumber, int inputValue)
{
	// DebugTN("sgUpdateCTCSubComponent invoked for CTC: " + rootName + " module type: " + slotConfig + " slotNumber: " + slotNumber + " value: " + inputValue);
	
	if (inputValue == -1)
	{
		sgCTCForceToUKN(rootName, slotNumber);
		return;
	}
			
	bool b = sgCTCCheckConfig(rootName, slotNumber);
	if (!b)
	{
		// DebugTN("slot doesnt match for CTC: " + rootName + " slot: " + slotNumber);
		sgFillSubComponentAsConfigDoesntMatch(rootName, slotNumber);	
		return;
	}		
						
	if (slotConfig == 0)
	{
		sgFillSubComponentAsAbscent(rootName, slotNumber); // no module
		return;
	}
				
	if (dynlen(gModuleOIDValues) == 0)
		DebugTN("Tables are not loaded");
		
	int index = dynContains(gModuleOIDValues, slotConfig);
	//DebugTN("Index: " + index);
	
	//DebugTN("sgUpdateCTCSubComponent >> faultsTableName: " + gModuleTablesName[index]);
	//string faultsTableName = gModuleTablesName[slotConfig];	//
	string faultsTableName = gModuleTablesName[index];	//
				
	sgFillSubComponent(rootName, slotNumber, faultsTableName, inputValue);			
}

void sgCTCForceToUKN(string rootName, int slotNumber)
{
	string key = rootName + slotNumber;
	
	bool s = mappingHasKey(ctcStatus, key);			
	if (s == false)
	{
		// DebugTN("Adding key: " + key);
		ctcStatus[key] = "";
	}

	string newStatus = UKN_STATUS;
	
	sgForceSubComponent(rootName, slotNumber, newStatus, key);
}

void sgFillSubComponentAsConfigDoesntMatch(string rootName, int slotNumber)
{
	string key = rootName + slotNumber;
	
	bool s = mappingHasKey(ctcStatus, key);			
	if (s == false)
	{
		// DebugTN("Adding key: " + key);
		ctcStatus[key] = "";
	}

	string newStatus = U_S_STATUS;
	
	sgForceSubComponent(rootName, slotNumber, newStatus, key, "Slot config doesn't match with received config");
}	

void sgFillSubComponentAsAbscent(string rootName, int slotNumber)
{
	string key = rootName + slotNumber;
	
	bool s = mappingHasKey(ctcStatus, key);			
	if (s == false)
	{
		// DebugTN("Adding key: " + key);
		ctcStatus[key] = "";
	}

	string newStatus = ABS_STATUS;
	
	sgForceSubComponent(rootName, slotNumber, newStatus, key);
}

void sgForceSubComponent(string rootName, string slotNumber, string newStatus, string key, string label1 = "")
{	
	if (ctcStatus[key] != newStatus)
	{
		dyn_string ds1, ds2;
		
		dynAppend(ds1, newStatus);
		dynAppend(ds2, rootName + ".SubComponents.Slot_" + slotNumber + ".PreStatus");
		
		if (label1 == "")
		{
			// empty old labels
			for (int i = 1; i <= 3; i++)
			{
				dynAppend(ds1, "");
				dynAppend(ds2, rootName + ".SubComponents.Slot_" + slotNumber + ".Label" + i);
			}
		}
		else
		{
			dynAppend(ds1, label1);
			dynAppend(ds2, rootName + ".SubComponents.Slot_" + slotNumber + ".Label1");	
			
			dynAppend(ds1, "");
			dynAppend(ds2, rootName + ".SubComponents.Slot_" + slotNumber + ".Label2");	
			dynAppend(ds1, "");
			dynAppend(ds2, rootName + ".SubComponents.Slot_" + slotNumber + ".Label2");	
		}
		 	
		int b = dpSet(ds2, ds1);
		if (b == -1)
			DebugTN("Unable to set: " + ds1);
			
		ctcStatus[key] = newStatus;
	}
	else
		;// DebugTN("No dpSet because value in the cache for: " + rootName + " and slot: " + slotNumber + " are the same");
}

void sgFillSubComponent(string rootName, string slotNumber, string faultsTableName, int errorCode)
{
	string key = rootName + slotNumber;
	
	bool s = mappingHasKey(ctcStatus, key);			
	if (s == false)
	{
		// DebugTN("Adding key: " + key);
		ctcStatus[key] = "";
	}
	
	string newStatus, dummy;
	dyn_string labels;
	int nbLabels;
		
	if (errorCode)
	{
		// DebugTN("CTC: " + rootName + " errorCode: " + errorCode);
		int i;
		dyn_string warningsMsg, alarmsMsg;
		
		for (i = 0; i <= 15; i++)
		{
			if (getBit(errorCode, i))
			{	
				// DebugTN("faultsTableName: " + faultsTableName);
				int index = dynContains(ddsOrder, faultsTableName);
				// DebugTN("ddsOrder index: " + index);
				dyn_string messageTable = dds[index];
				//DebugTN("Message table: " + messageTable);
				
				string message = messageTable[i+1];
				
				dyn_string ds = strsplit(message, ";");
				if (dynlen(ds) != 2)
				{
					DebugTN("sgCTCLib: unable to recognise the level of this message (;A for Alarm and ;W for warning)");
				}
				
				if (ds[2] == WARNING)
				{
					//DebugTN("Warning: " + ds[1]);
					dynAppend (warningsMsg, ds[1]);
					if (newStatus != U_S_STATUS)
						newStatus = DEG_STATUS;
				} 
				else if (ds[2] == ALARM)
				{
					//DebugTN("Alarm: " + ds[1]);
					dynAppend (alarmsMsg, ds[1]);
					newStatus = U_S_STATUS;
				}
				else
					;// DebugTN("Unknow error type: not an warning nor an alarm for message:" + message);
			}		
		} // for	
		
		labels = alarmsMsg;
		
		nbLabels = dynlen(labels);
		// DebugTN("There is: " +  nbLabels + " alarmsMsg  labels");
		
		if (dynlen(alarmsMsg) > 3)
		{
			labels[3] = "And more alarms...";
			nbLabels = 3;		
		}
												 
		if (nbLabels < 3 && dynlen(warningsMsg) > 0)
		{
			// there is free labels for warnings
			if (nbLabels == 0) 
			{
				// there are only warnings message
				labels = warningsMsg;
				nbLabels = dynlen(warningsMsg);
				if (dynlen(warningsMsg) > 3)
				{
					labels[3] = "And more warnings...";		
					nbLabels = 3;			
				}
			}
			else if (nbLabels == 1) 
			{
				// DebugTN("One alarm and warning(s)");
				// one alarm
				labels[2] = warningsMsg[1];
				nbLabels = 2;
			
				if (dynlen(warningsMsg) == 2)
				{
					// one alarm and 2 warnings
					labels[3] = warningsMsg[2];
					nbLabels = 3;
				}
				else if (dynlen(warningsMsg) > 2)
				{
					labels[3] = "And more warnings";
					nbLabels = 3;
				}	
			}
			else if (dynlen(warningsMsg) == 1)
			{
				// 2 alarms and 1 warning
				// DebugTN("nbLabels: " + nbLabels + " and 1 warnings");
				labels[3] = warningsMsg[1];
				nbLabels = 3;
			}
			else
			{
				// 2 alarms and more than 1 warning
				labels[3] = "And warnings";
				nbLabels = 3;
			}	
		} // alarms and warning
		else
		{
			if (dynlen(warningsMsg) > 0)
				labels[3] += " and warning(s)";
			 
		}
	}
	else
	{
		// no error;
		newStatus = OPS_STATUS;
	}
		
	// dpSet only if value changed
	string actualValue = newStatus;
				
	for (int i = 1; i <= nbLabels; i++)
	{
		actualValue = actualValue + labels[i];
	}
		
	if (actualValue != ctcStatus[key])
	{
		// DebugTN("ActualValue : " + actualValue);
		// DebugTN("Cached value: " + ctcStatus[key]);
	
		dyn_string ds1, ds2;
		dynAppend(ds1, newStatus);
		dynAppend(ds2, rootName + ".SubComponents.Slot_" + slotNumber + ".PreStatus");
					
		ctcStatus[key] = newStatus;
			
		for (int i = 1; i <= nbLabels; i++)
		{
			dynAppend(ds1, labels[i]);
			dynAppend(ds2, rootName + ".SubComponents.Slot_" + slotNumber + ".Label" + i);
			ctcStatus[key] = ctcStatus[key] + labels[i];
		}
		// DebugTN("Nb labels: " + nbLabels);
		
		// empty old labels
		for (int i = ++nbLabels; i <= 3; i++)
		{
			dynAppend(ds1, "");
			dynAppend(ds2, rootName + ".SubComponents.Slot_" + slotNumber + ".Label" + i);
		}
			
		
		// DebugTN("Will dpSet: " + ds2);
		// DebugTN("With: " + ds1);
		int b = dpSet(ds2, ds1);
		if (b == -1)
			DebugTN("Error on dpSet");
	}
	else
	{
		// DebugTN("No dpSet because value in the cache for: " + rootName + " and slot: " + slotNumber + " are the same");
	}
}

void sgCTCForceAllCTCToUKN()
{
	dyn_string names, status;
		dynAppend(names, getPointsFromPattern("CTC.Components.*.RawDatas.Slot_0"));
		dynAppend(names, getPointsFromPattern("CTC.Components.*.RawDatas.Slot_1"));
		dynAppend(names, getPointsFromPattern("CTC.Components.*.RawDatas.Slot_2"));
		dynAppend(names, getPointsFromPattern("CTC.Components.*.RawDatas.Slot_3"));
		dynAppend(names, getPointsFromPattern("CTC.Components.*.RawDatas.Slot_4"));
		dynAppend(names, getPointsFromPattern("CTC.Components.*.RawDatas.Slot_5"));
				
		for(int cpt = 1; cpt <= dynlen(names); cpt++)
		{
			status[cpt] = -1;
		}

		int res = dpSet(names, status);
		
		if (res == -1)
			DebugTN("Unable to set: " + names);
		
}

