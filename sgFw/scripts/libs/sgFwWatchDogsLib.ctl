
// Constants
const string  DBKEY_REFERENCES_LIST   = "REFERENCES_LIST";
const string  DBKEY_REFERENCES_TABLE 	= "REFERENCES_TABLE";
const string  DBKEY_REFERENCE_VALUE   = "REFERENCE_VALUE";
const string 	DBKEY_TIMEOUT					  = "TIMEOUT";
const string  DBKEY_OUTPUTS 					= "OUTPUTS";
const string	DBKEY_DEFAULT_VALUE			= "DEFAULT_VALUE";	
const string	DBKEY_LAST_UPDATE				= "LAST_UPDATE";
const string	DBKEY_EXPIRED					 	= "EXPIRED";
const string  REFERENCE_POSTFIX	 			= "REF";

time nextCheckTime;

bool sgWDIsConfigValid(string references, int timeout, string defaultValues, string outputs)
{
	if (timeout <= 0)
	{
		DebugN("sgWDIsConfigValid >> value of timeout is invalid");
		return false;
	}
		
	if (strpos(references, "*") != -1)
	{
		// DebugN("sgWDIsConfigValid >> reference contain a pattern");
		if (strpos(outputs, "*") == -1)
		{
			// DebugN("sgWDIsConfigValid >> output doesn't contain a pattern");

			// 26.07.2005 aj changed to "true"
			// no changes to existing systems (was not allowed before)
			// is used to clear the cache of emdis - ref has a pattern but all write to the DPE to clear the cache
			// no problem in replaceStar() - output without star is taken for all points matching the pattern in references
			return true;
		}
		
		if (!sgPatternCoverage(references, outputs))
		{
			DebugN("sgWDIsConfigValid >> sgPatternCoverage is not valid");
			return false;
		}
		
		// DebugN("sgWDIsConfigValid >> config is valid");	
		return true;
	} // reference contain a pattern
	else
	{
		dyn_string outputsList;
		// DebugN("sgWDIsConfigValid >> reference doesn'tcontain a pattern");
		outputsList = strsplit(outputs, ";");
		
		for (cpt = 1; cpt <= dynlen(outputsList); cpt++)
		{
			dyn_string ds;
			ds = getPointsFromPattern(outputsList[cpt]);
			if (dynlen(ds) == 0)
			{
				DebugN("sgWDIsConfigValid >> Output: " + outputsList[cpt] + " doesn't match any point");
				return false;
			}
		}
		return true;
	} // reference doesn't contain a pattern
}

global int gPatternsCoverageCounter = 0;
bool sgPatternCoverage(string references, string outputs)
{
	gPatternsCoverageCounter++;
//	time start = getCurrentTime();

	dyn_string referencesList, outputsList;
	string starValue, output, reference;
	
	referencesList = getPointsFromPattern(references);
	outputsList    = getPointsFromPattern(outputs);
	
	for (int cpt = 1; cpt <= dynlen(referencesList); cpt++)
	{
		
		starValue = findStarValue(references, referencesList[cpt]);
		output = replaceStar(outputs, starValue);
		
		if (!dynContains(outputsList, output))
		{
			DebugN("sgPatternCoverage >> " + outputsList + " doesn't contain " + output);
			return false;
		}
	}
	
	for (int cptO = 1; cptO <= dynlen(outputsList); cptO++)
	{
		
		starValue = findStarValue(outputs, outputsList[cptO]);
		reference = replaceStar(references, starValue);
		
		if (!dynContains(referencesList, reference))
		{
			DebugN("sgPatternCoverage >> " + referencesList + " doesn't contain " + reference);
			return false;
		}
	} 

//	float delta = getCurrentTime() - start;
//	DebugTN("sgWatchDogsLib: patterns coverage counter: " + gPatternsCoverageCounter + " in " + delta);

	return true;
} // bool sgPatternCoverage(string references, string outputs)


bool sgWDInit()
{
	dyn_string watchDogsList;
	dyn_string references, defaultValues, outputs;
	dyn_int timeouts;
	
	watchDogsList = getPointsOfType("sgWatchDogs");
	
	bool b;
	b = sgDBCreateTable(DBKEY_REFERENCES_TABLE);
	if(!b)
	{
			DebugTN("sgWDInit >> unable to create references table");
			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgWDInit >> unable to create references table");
			return false;
	}
	
	
	dyn_string emtpy;
	b = sgDBSet(GLOBAL_TABLE_NAME, DBKEY_REFERENCES_LIST, emtpy);
	if(!b)
	{
			DebugTN("sgWDInit >> unable to create references list in global table");
			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgWDInit >> unable to create references list table");
			return false;
		}
	
//	DebugTN("sgFwWatchDogsLib: we have " + dynlen(watchDogsList) + " watchdogs");
	
	for (int cptWD = 1; cptWD <= dynlen(watchDogsList); cptWD++)
	{		
//		time start = getCurrentTime();
		dpGet(watchDogsList[cptWD] + REFERENCES_POSTFIX , references, 
					watchDogsList[cptWD] + ".Timeouts", timeouts,
					watchDogsList[cptWD] + DEFAULT_VALUES_POSTFIX , defaultValues,
					watchDogsList[cptWD] + OUTPUTS_POSTFIX , outputs);
		
		for (int refId = 1; refId <= dynlen(references); refId++)
		{					
			b = sgWDIsConfigValid(references[refId], timeouts[refId], defaultValues[refId], outputs[refId]);
			if (!b)
			{
				Debug("sgWDInit >> The wathdog config: " + references[refId] + " is invalid");
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgWDInit >> The wathdog config: " + references[refId] + " is invalid");
				return false;
			}
			
			b = sgWDFillDB(references[refId], timeouts[refId], defaultValues[refId], outputs[refId]);	
			if (!b)
			{
				Debug("sgWDInit >> sgWDFillDB return false for: " + references[refId]);
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgWDInit >> Failed to fill sgDB for watch dog: " + references[refId]);
				return false;
			}
		} // for references
		
//		float delta = getCurrentTime() - start;
//		DebugTN("sgFwWatchDogsLib: watchdog " + watchDogsList[cptWD] + " initialised in " + delta);
	} // for watchdogsList
	
	dyn_string referencesList;
	referencesList = sgDBGet(GLOBAL_TABLE_NAME, DBKEY_REFERENCES_LIST);
	
	for (cpt = 1; cpt <= dynlen(referencesList); cpt++)
	{	
		int i;
		i = dpConnect("sgDWReferenceChanged", referencesList[cpt]);
		if(i != 0)
		{
			DebugTN("sgWDInit >> Failed to connect watch dog: " + referencesList[cpt]);
			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgWDInit >> Failed to connect watch dog: " + referencesList[cpt]);
			return false;
		}	
	} // for all referrences
	
	return true;	
} // bool sgWDInit()

void sgDWReferenceChanged(string refName, string refValue)
{
	// this functionis connected to the reference of all watchdogs
	time actualTime = getCurrentTime();
	string timeNow = actualTime;
	
	string refTableName = sgStripDpName(refName, "") + REFERENCE_POSTFIX;
	
	dyn_string ds;
	int timeout;
	
	ds = sgDBGet(refTableName, DBKEY_TIMEOUT);
	timeout = ds[1];
	
	sgDBSet(DBKEY_REFERENCES_TABLE, sgStripDpName(refName, ""), actualTime + timeout);
	
	bool b;
	b = sgDBSet(refTableName, DBKEY_LAST_UPDATE, timeNow);
	if (!b)
		sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgDWReferenceChanged >> Failed to update table: " + refTableName + "with key: " + DBKEY_LAST_UPDATE);

	b = sgDBSet(refTableName, DBKEY_REFERENCE_VALUE, refValue);
	if (!b)
		sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgDWReferenceChanged >> Failed to update table: " + refTableName + "with key: " + DBKEY_REFERENCE_VALUE);	
	
	// DebugTN("sgDWReferenceChanged >> will mark: " + refTableName + " as non expired");	
	b = sgDBSet(refTableName, DBKEY_EXPIRED, false);
	if (!b)
		sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgDWReferenceChanged >> Failed to update table: " + refTableName + "with key: " + DBKEY_EXPIRED);		
} // void sgDWReferenceChanged(string refName, string refValue)

bool sgWDChecker()
{

	// Th.V Check WD only when it is needed
	time now = getCurrentTime();
	if (nextCheckTime > now)
	{
		string temp = nextCheckTime;
		// DebugTN("Next check time is: " +  temp);			
		return true;
	}

	// This function is called by the clock and check if some watch dog is / are expired
	dyn_string referencesList;
	referencesList = sgDBTableKeys(DBKEY_REFERENCES_TABLE);
	
//	DebugTN("sgWDChecker: references list size is " + dynlen(referencesList));

	// 16.08.2005 aj init nextCheckTime with first valid time
	bool initialized = FALSE;
	
	for (int cpt = 1; cpt <= dynlen(referencesList); cpt++)
	{
		bool expired, b;
		time expiry;
		dyn_string ds;
		
		ds = sgDBGet(DBKEY_REFERENCES_TABLE, referencesList[cpt]);
		expiry = ds[1];

		// 15.08.2005 aj,tv included check for next expiry time in this loop
		if ( (expiry > now) && ((expiry < nextCheckTime) || (!initialized)) )
		{
			//DebugTN("sgFwWatchDogsLib change nextCheckTime",expiry,nextCheckTime,cpt,initialized);
			initialized=TRUE;
			nextCheckTime = expiry;
		}
		// 15.08.2005 aj,tv included check for next expiry time in this loop
		
		if(expiry > now)
			continue;
		
		ds = sgDBGet(referencesList[cpt] + REFERENCE_POSTFIX, DBKEY_EXPIRED);
		expired = ds[1];
		
		if (expired)
		{
			// DebugTN("sgWDChecker: " + referencesList[cpt] + " is already expired");
			continue; // alread expired
		}
			
		time lastUpdate;
		ds = sgDBGet(referencesList[cpt] + REFERENCE_POSTFIX, DBKEY_LAST_UPDATE);
		lastUpdate = ds[1];
			
		int timeout;
		ds = sgDBGet(referencesList[cpt] + REFERENCE_POSTFIX, DBKEY_TIMEOUT);
		timeout = ds[1];
			
		if ((lastUpdate + timeout) < now)
		{
			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgWDChecker >> Watch dog: " + referencesList[cpt] + " has expired");
			
			dyn_string outputList;
			outputList = sgDBGet(referencesList[cpt] + REFERENCE_POSTFIX, DBKEY_OUTPUTS);
			
			// DebugTN("sgWDChecker >> Watch dog: " + referencesList[cpt] + " as expired, outputs are: " + outputList);
			
			string defaultValue;
			ds = sgDBGet(referencesList[cpt] + REFERENCE_POSTFIX, DBKEY_DEFAULT_VALUE);
			defaultValue = ds[1];
			
			for (int outputId = 1; outputId <= dynlen(outputList); outputId++)
			{
				if (dynContains(outputList, referencesList[cpt]))
				{
					string referenceValue;
					ds = sgDBGet(referencesList[cpt] + REFERENCE_POSTFIX, DBKEY_REFERENCE_VALUE);
					referenceValue = ds[1];
					if (referenceValue == defaultValue)
					{
						b = dynRemove(outputList, dynContains(outputList, referencesList[cpt])); 
					}		
					// DebugN("sgWDChecker >> " + referencesList[cpt] + " as value: " + referenceValue + " but default value is: " + defaultValue);
				} // output == reference
			} // loop on outputList
			
			if (dynlen(outputList) > 0)
			{
				dyn_string defaultValuesList;
				bool isXML = false;
				for (int outputId = 1; outputId <= dynlen(outputList); outputId++)
				{
					dynAppend(defaultValuesList, defaultValue);		
				}
				
				//DebugTN("sgFwWatchDogsLib: WatchDog: " + referencesList[cpt] + " is expired");
				if (dpExists("XMLUtils"))
				{
					sgXMLPrepareForceToUKN("Watchdog expired");
				}
				
//				for (int cpt = 1; cpt <= dynlen(outputList); cpt++)
//				{
//					DebugTN("sgWDChecker >> will set output: " + outputList[cpt] + " as value " + defaultValuesList[cpt]);	
//				}
				// DebugTN("sgWDChecker >> will set output: " + outputList + " as value " + defaultValuesList);	
				int res;
				res = dpSet(outputList, defaultValuesList);
							
				if (0 != res)
				{
					sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgWDChecker >> unable to set outputs to default values for reference: " + referencesList[cpt]);	
				}
			} // there are output(s) that must be set to default value
			
			// DebugTN("sgWDChecker >> will mark: " + referencesList[cpt] + " as expired"); 
			sgDBSet(referencesList[cpt] + REFERENCE_POSTFIX, DBKEY_EXPIRED, true);			
		} // expired
	} // loop on referencesList
			
	return true;
} // bool sgWDChecker()

bool sgWDFillDB(string reference, int timeout, string defaultValue, string outputs)
{
	bool b;
	time timeNow;
	timeNow = getCurrentTime();
	dyn_string tablesList, referencesList, outputList, empty;
	string currentTime,
	 
	currentTime = getCurrentTime();
	
	// DebugN("sgWDFillDB: will set watch dog for: " + reference);
	
	
	if (strpos(reference, "*") != -1)
	{
		referencesList = getPointsFromPattern(reference);
		
		for (cpt = 1; cpt <= dynlen(referencesList); cpt++)
		{
			tablesList = sgDBTablesNames();
			if (!dynContains(tablesList, referencesList[cpt] + REFERENCE_POSTFIX))
			{		
				// DebugTN("Will create table " + referencesList[cpt] + REFERENCE_POSTFIX);
				b = sgDBCreateTable(referencesList[cpt] + REFERENCE_POSTFIX);
				if (!b)
				{
					DebugTN("sgWDFillDB >> unable to create table: " + referencesList[cpt] + REFERENCE_POSTFIX);	
					sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgWDFillDB >> unable to create table: " + referencesList[cpt] + REFERENCE_POSTFIX);	
					return false;
				}
				
				b = sgDBSet(referencesList[cpt] + REFERENCE_POSTFIX, DBKEY_DEFAULT_VALUE, defaultValue);
				if (!b)
				{
					DebugTN("sgWDFillDB >> unable to set value(s) in the table: " + referencesList[cpt] + REFERENCE_POSTFIX + "with the key: " + DBKEY_DEFAULT_VALUE);	
					sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgWDFillDB >> unable to set value(s) in the table: " + referencesList[cpt] + REFERENCE_POSTFIX + "with the key: " + DBKEY_DEFAULT_VALUE);	
					return false;
				}
				
				b = sgDBSet(referencesList[cpt] + REFERENCE_POSTFIX, DBKEY_TIMEOUT, timeout);
				if (!b)
				{
					DebugTN("sgWDFillDB >> unable to set value(s) in the table: " + referencesList[cpt] + REFERENCE_POSTFIX + "with the key: " + DBKEY_TIMEOUT);	
					sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgWDFillDB >> unable to set value(s) in the table: " + referencesList[cpt] + REFERENCE_POSTFIX + "with the key: " + DBKEY_TIMEOUT);	
					return false;
				}
				
				string refValue;
				dpGet(referencesList[cpt], refValue);
				b = sgDBSet(referencesList[cpt] + REFERENCE_POSTFIX, DBKEY_REFERENCE_VALUE, refValue);
				if (!b)
				{
					DebugTN("sgWDFillDB >> unable to set value(s) in the table: " + referencesList[cpt] + REFERENCE_POSTFIX + " with key: " + DBKEY_REFERENCE_VALUE);	
					sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgWDFillDB >> unable to set value(s) in the table: " + referencesList[cpt] + REFERENCE_POSTFIX + " with key: " + DBKEY_REFERENCE_VALUE);	
					return false;
				}
				
				b = sgDBSet(referencesList[cpt] + REFERENCE_POSTFIX, DBKEY_OUTPUTS, empty);
				if (!b)
				{
					DebugTN("sgWDFillDB >> unable to set value(s) in the table: " + referencesList[cpt] + REFERENCE_POSTFIX + " with key: " + DBKEY_OUTPUTS + " value: empty");	
					sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgWDFillDB >> unable to set value(s) in the table: " + referencesList[cpt] + REFERENCE_POSTFIX + " with key: " + DBKEY_OUTPUTS);	
					return false;
				}		
			} // the table must be created
			
			string output;
			string starValue;
			
			starValue = findStarValue(reference, referencesList[cpt]);
			output = replaceStar(outputs, starValue);
			
			b = sgDBAppend(referencesList[cpt] + REFERENCE_POSTFIX, DBKEY_OUTPUTS, output);
			if (!b)
			{
				DebugTN("sgWDFillDB >> unable to set value(s) in the table: " + referencesList[cpt] + REFERENCE_POSTFIX + " with key: " + DBKEY_OUTPUTS);	
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgWDFillDB >> unable to set value(s) in the table: " + referencesList[cpt] + REFERENCE_POSTFIX + " with key: " + DBKEY_OUTPUTS);	
				return false;
			}
			
			b = sgDBSet(referencesList[cpt] + REFERENCE_POSTFIX, DBKEY_LAST_UPDATE, currentTime);
			if (!b)
			{
				DebugTN("sgWDFillDB >> unable to set value(s) in the table: " + referencesList[cpt] + REFERENCE_POSTFIX + " with key: " + DBKEY_LAST_UPDATE);	
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgWDFillDB >> unable to set value(s) in the table: " + referencesList[cpt] + REFERENCE_POSTFIX + " with key: " + DBKEY_LAST_UPDATE);	
				return false;
			}
			
			b = sgDBSet(referencesList[cpt] + REFERENCE_POSTFIX, DBKEY_EXPIRED, false);
			if (!b)
			{
				DebugTN("sgWDFillDB >> unable to set value(s) in the table: " + referencesList[cpt] + REFERENCE_POSTFIX + " with key: " + DBKEY_EXPIRED);	
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgWDFillDB >> unable to set value(s) in the table: " + referencesList[cpt] + REFERENCE_POSTFIX + " with key: " + DBKEY_EXPIRED);	
				return false;
			}

			b = sgDBAppend(GLOBAL_TABLE_NAME, DBKEY_REFERENCES_LIST, referencesList[cpt]);
			if (!b)
			{
				DebugTN("sgWDFillDB >> unable to append reference : " + referencesList[cpt] + " to references list in global table");	
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgWDFillDB >> unable to append reference : " + referencesList[cpt] + " to references list in global table");	
				return false;
			}
			sgDBSet(DBKEY_REFERENCES_TABLE, referencesList[cpt], currentTime + timeout);
			
		} // loop on matching pattern
	}
	else
	{
		// reference doesn't contain a pattern
		tablesList = sgDBTablesNames();
		if (!dynContains(tablesList, reference + REFERENCE_POSTFIX))
		{
			// DebugTN("Will create table " + reference + REFERENCE_POSTFIX);
			b = sgDBCreateTable(reference + REFERENCE_POSTFIX);
			if (!b)
			{
				DebugTN("sgWDFillDB >> unable to create table: " + reference + REFERENCE_POSTFIX);	
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgWDFillDB >> unable to create table: " + reference + REFERENCE_POSTFIX);	
				return false;
			}
			
			b = sgDBSet(GLOBAL_TABLE_NAME, DBKEY_REFERENCE_VALUE, reference + REFERENCE_POSTFIX);
			if (!b)
			{
				DebugTN("sgWDFillDB >> unable to set value(s) in the table: " + GLOBAL_TABLE_NAME + " with key: " + reference + REFERENCE_POSTFIX);	
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgWDFillDB >> unable to set value(s) in the table: " + GLOBAL_TABLE_NAME + " with key: " + reference + REFERENCE_POSTFIX);	
				return false;
			}
			
			b = sgDBSet(reference + REFERENCE_POSTFIX, DBKEY_DEFAULT_VALUE, defaultValue);
			if (!b)
			{
				DebugTN("sgWDFillDB >> unable to set value(s) in the table: " + reference + REFERENCE_POSTFIX + "with the key: " + DBKEY_DEFAULT_VALUE);	
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgWDFillDB >> unable to set value(s) in the table: " + reference + REFERENCE_POSTFIX + "with the key: " + DBKEY_DEFAULT_VALUE);	
				return false;
			}
			
			b = sgDBSet(reference + REFERENCE_POSTFIX, DBKEY_TIMEOUT, timeout);
			if (!b)
			{
				DebugTN("sgWDFillDB >> unable to set value(s) in the table: " + reference + REFERENCE_POSTFIX + "with the key: " + DBKEY_TIMEOUT);	
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgWDFillDB >> unable to set value(s) in the table: " + reference + REFERENCE_POSTFIX + "with the key: " + DBKEY_TIMEOUT);	
				return false;
			}
			
			b = sgDBSet(reference + REFERENCE_POSTFIX, DBKEY_OUTPUTS, empty);
			if (!b)
			{
				DebugTN("sgWDFillDB >> unable to set value(s) in the table: " + reference + REFERENCE_POSTFIX + " with key: " + DBKEY_OUTPUTS + " value: empty");	
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgWDFillDB >> unable to set value(s) in the table: " + reference + REFERENCE_POSTFIX + " with key: " + DBKEY_OUTPUTS);	
				return false;
			}		
		}	// the table doesn't exist
		
		b = sgDBSet(reference + REFERENCE_POSTFIX, DBKEY_LAST_UPDATE, currentTime);
		if (!b)
		{
			DebugTN("sgWDFillDB >> unable to set value(s) in the table: " + reference + REFERENCE_POSTFIX + " with key: " + DBKEY_LAST_UPDATE);	
			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgWDFillDB >> unable to set value(s) in the table: " + reference + REFERENCE_POSTFIX + " with key: " + DBKEY_LAST_UPDATE);	
			return false;
		}
		
		b = sgDBSet(reference + REFERENCE_POSTFIX, DBKEY_EXPIRED, false);
		if (!b)
		{
			DebugTN("sgWDFillDB >> unable to set value(s) in the table: " + reference + REFERENCE_POSTFIX + " with key: " + DBKEY_EXPIRED);	
			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgWDFillDB >> unable to set value(s) in the table: " + reference + REFERENCE_POSTFIX + " with key: " + DBKEY_EXPIRED);	
			return false;
		}
				
		outputList = getPointsFromPattern(outputs);

		b = sgDBAppend(reference+ REFERENCE_POSTFIX, DBKEY_OUTPUTS, outputList);
		if (!b)
		{
			DebugTN("sgWDFillDB >> unable to set value(s) in the table: " + reference + REFERENCE_POSTFIX + " with key: " + DBKEY_OUTPUTS);	
			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgWDFillDB >> unable to set value(s) in the table: " + reference + REFERENCE_POSTFIX + " with key: " + DBKEY_OUTPUTS);	
			return false;
		}
		
		b = sgDBAppend(GLOBAL_TABLE_NAME, DBKEY_REFERENCES_LIST, reference);
		if (!b)
		{
			DebugTN("sgWDFillDB >> unable to append reference : " + reference + " to references list in global table");	
			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgWDFillDB >> unable to append reference : " + reference + " to references list in global table");	
			return false;
		}			
		
		sgDBSet(DBKEY_REFERENCES_TABLE, reference, currentTime + timeout);
				
	}
		
	return true;
}