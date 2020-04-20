const string DBKEY_HISTORY_QUEUE = "History queue";
const string DBKEY_HISTORY_SIZE = "History size";
const string DBKEY_HISTORY_MODIFIED = "History modified";

const string DBKEY_LOGS_PATHS = "History logs paths";
const string DBKEY_HISTORIES_BUFFER = "Histories buffer";
const string DBKEY_ALL_HISTORIES = "All histories";

const string HISTORY_SIZE_POSTFIX = ".HistorySize";
const string SHORT_HISTORY_POSTFIX = ".ShortHistory";
const string HISTORY_MESSAGE_POSTFIX = ".Message";

const string DBKEY_PENDING_EVENTS = "PendingEvents";
const string HSTDP_DELIMITER = "@";

time gStartRefreshHistories;

// Th.V
string gBuffer;
dyn_string gPendingsEvents;
int gHistoriesDebugLevel;

bool lastDayFileSaved;  // PW: flag for the last events save of day done (used in sgHistoryStackTreatment)

void sgHistoriesDebugLevelChanged(string dpName, int dpValue)
{
	gHistoriesDebugLevel = dpValue;
	if (gHistoriesDebugLevel > 0)
		DebugN("sgHistories >> Will trace if function sgRefreshShortHistories take more than 200 milli seconds");
	
	if (gHistoriesDebugLevel > 1)
		DebugN("sgHistories >> Will trace if function sgRefreshShortHistories has more than 1 histories");
}

bool sgHistoriesInit()
{
	dyn_string histories;
	dyn_string empty;
	bool b;
	int i;
	
	// Th.V
	dpConnect("sgHistoriesDebugLevelChanged", false, "FwUtils.Commands.DebugLevel");
	
	dpGet("FwUtils.Commands.DebugLevel", gHistoriesDebugLevel);
	
	histories = getPointsOfType("sgFwHistory");
	
	for(int cpt = 1; cpt <= dynlen(histories); cpt++)
	{
		int size;
		dyn_string history;
		dpGet(histories[cpt] + HISTORY_SIZE_POSTFIX, size,
				  histories[cpt] + SHORT_HISTORY_POSTFIX, history);
				  
		if(size <= 0)
		{
			DebugTN("sgHistoriesLib: history " + histories[cpt] + " has a size of " + size);
			return false;
		}

		
		b = sgDBCreateTable(histories[cpt]);
		if(!b)
		{
			DebugTN("sgHistoriesLib: unable to create table for history " + histories[cpt]);	
			return false;
		}

		b = sgDBSet(histories[cpt], DBKEY_HISTORY_QUEUE, history);
		if(!b)
		{
			DebugTN("sgHistoriesLib: unable to set history for history " + histories[cpt]);	
			return false;
		}

		b = sgDBSet(histories[cpt], DBKEY_HISTORY_SIZE, size);
		if(!b)
		{
			DebugTN("sgHistoriesLib: unable to set history size for history " + histories[cpt]);	
			return false;
		}
		
		b = sgDBSet(histories[cpt], DBKEY_HISTORY_MODIFIED, "FALSE");
		if(!b)
		{
			DebugTN("sgHistoriesLib: unable to set modified flag for history " + histories[cpt]);	
			return false;
		}
		

		i = dpConnect("sgHistoryAddEventCore", false, histories[cpt] + HISTORY_MESSAGE_POSTFIX);
		if(i != 0)
		{
			DebugTN("sgHistoriesLib: dpConnect failed for history " + histories[cpt]);	
			return false;
		}
	}

	b = sgDBSet(GLOBAL_TABLE_NAME, DBKEY_ALL_HISTORIES, histories);
	if(!b)
	{
		DebugTN("sgHistoriesLib: unable to set histories table in database");	
		return false;
	}

	b = sgDBSet(GLOBAL_TABLE_NAME, DBKEY_HISTORIES_BUFFER, empty);
	if(!b)
	{
		DebugTN("sgHistoriesLib: unable to set histories table in database");	
		return false;
	}

	
	dyn_string logsPaths;
	i = dpGet("FwUtils.LogsPath", logsPaths);
	if(i != 0)
	{
		DebugTN("sgHistoriesLib: dpGet on FwUtils.LogsPath failed");	
		return false;
	}

	b = sgDBSet(GLOBAL_TABLE_NAME, DBKEY_LOGS_PATHS, logsPaths);
	if(!b)
	{
		DebugTN("sgHistoriesLib: unable to set logs paths table in database");	
		return false;
	}

	// TO DO: check that folders exist.
	
	return true;

}

void sgHistoryAddEvent(dyn_string historiesList, string severity, string eventText, string message = " ")
{
	string s;
	
	// Date
	s = formatTime("%d/%m/%y", getCurrentTime());
	// Time
	s = s + EVENTTEXT_DELIMITER + formatTime("%H:%M:%S", getCurrentTime());
	//Severity
	s = s + EVENTTEXT_DELIMITER + severity;
	//eventText
	s = s + EVENTTEXT_DELIMITER + eventText;	
	//message
	s = s + EVENTTEXT_DELIMITER + message;	
	
	for(int cpt = 1; cpt <= dynlen(historiesList); cpt++)
	{
		string dpName;
		
		dpName = historiesList[cpt] + HISTORY_MESSAGE_POSTFIX;
							
		if(!dpExists(dpName))
		{
			DebugTN("sgHistoryAddEvent >> " + historiesList[cpt] + " does not exist, message is:" + s);
			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "History " + historiesList[cpt] + " does not exist, eventText is:" + eventText);
		}
		else
		{
                //PW JAN 2009 new string replacement to allow II in eventText
                        if (strpos(s,"|") >= 0)
                           DebugTN("sgFwHistoriesLib.ctl; sgHistoryAddEvent; found pipe in history!!!", s);
			strreplace(s, "|", " &pipe& "); // | not allowed with the dynamic DB!!!!
//			strreplace(s, "|", "II"); // | not allowed with the dynamic DB!!!!

                        			dpSet(dpName, s);
		}
	}
}

void sgHistoryAddEventCore(string dpName, string message)
{
	string str;
		
	str = dpName + HSTDP_DELIMITER + message;
	
	// Th.V
	dynAppend(gPendingsEvents, str);
	/*
	if (!sgDBAppend(GLOBAL_TABLE_NAME, DBKEY_PENDING_EVENTS, str))
		DebugTN("sgHistoryAddEventCore >> unable to add message: " + message + " in pending queue");	
	*/
}

void sgHistoryStackTreatment(bool forceSavingBuffer)
{
	time startTime = getCurrentTime();
	// Retrieve dpName and message from sgDB
	dyn_string buffer;

	// Th.V
	/*
	dyn_string ds;
	ds = sgDBGet(GLOBAL_TABLE_NAME, DBKEY_PENDING_EVENTS);
	*/
	dyn_string uniqueHistoryName;
	// dyn_int hits;
	int id;

	//for (int cpt = 1; cpt <= dynlen(ds); cpt++)
	for (int cpt = 1; cpt <= dynlen(gPendingsEvents); cpt++)
	{
		string dpName, message;
		
		dyn_string splitted;
		//Th.V
		//splitted =  strsplit(ds[cpt], HSTDP_DELIMITER);
		splitted =  strsplit(gPendingsEvents[cpt], HSTDP_DELIMITER);
		if (dynlen(splitted) != 2)
		{
			//DebugN("sgHistoryStackTreatment >> dynlen of splitted ?? " + ds[cpt]);
			DebugN("sgHistoryStackTreatment >> dynlen of splitted ?? " + gPendingsEvents[cpt]);
			continue;
		}
			
		message = splitted[2];	
                            
                //PW JAN 2009 new string replacement to allow II in eventText
                strreplace(message, " &pipe& ", "|"); // | not allowed with the dynamic BD !!
		//strreplace(message, "II", "|"); // | not allowed with the dynamic BD !!
		
                dpName = splitted[1];
		
		if (!dynContains(uniqueHistoryName, dpName))
			dynAppend(uniqueHistoryName, dpName);
			
		id = dynContains(uniqueHistoryName, dpName);
		// hits[id]++;
	
		// DebugN("sgHistoryStackTreatment >> message: " + message);
		// DebugN("sgHistoryStackTreatment >> dpName: " + dpName);
	
		time start = getCurrentTime();
		
		string historyName;
		
		historyName = sgStripDpName(dpName, HISTORY_MESSAGE_POSTFIX);

		
		dyn_string history;
		dyn_string dsa;
		int size;
		
		if (historyName == "")
		{
			// DebugTN("sgHistoryStackTreatment >> historyName is null! dpName: " + dpName + " ds[cpt]: " + ds[cpt]);
			DebugTN("sgHistoryStackTreatment >> historyName is null! dpName: " + dpName + " ds[cpt]: " + gPendingsEvents[cpt]);
		}
		
		history = sgDBGet(historyName, DBKEY_HISTORY_QUEUE); 
		dsa = sgDBGet(historyName, DBKEY_HISTORY_SIZE);
		size = dsa[1];
		//DebugTN(message);
		strreplace(message, "|", "\r\n");
		
		dynAppend(history, message);
		
		// int loopCounter = 0;
		
		while(dynlen(history) > size)
		{
			dynRemove(history, 1);
		// 	loopCounter ++;
		}			

		bool b;
		
		b = sgDBSet(historyName, DBKEY_HISTORY_QUEUE, history);
		if(!b)
		{
			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "Unable to set history " + historyName + " in database");
			return;
		}

		b = sgDBSet(historyName, DBKEY_HISTORY_MODIFIED, "TRUE");
		if(!b)
		{
			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "Unable to set history " + historyName + " as modified in database");
			return;
		}

		// 11.07.2005 aj replace get and set with an append -> performance!!!
		//		buffer = sgDBGet(GLOBAL_TABLE_NAME, DBKEY_HISTORIES_BUFFER);
		//		dynAppend(buffer, historyName + "\t" + message);
		
		//		DebugTN(dynlen(buffer));
		//		b = sgDBSet(GLOBAL_TABLE_NAME, DBKEY_HISTORIES_BUFFER, buffer);
		// Th.V
		gBuffer += historyName + "\t" + message + "\n";
		// b = sgDBAppend(GLOBAL_TABLE_NAME, DBKEY_HISTORIES_BUFFER, historyName + "\t" + message);
		if(!b)
		{
			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "Unable to set history buffer in database");
			return;
		}
	}	
	
	time currentTime;
	time yersterday;	

	time delta = getCurrentTime() - startTime;
	int mili = period(delta) * 1000 + milliSecond(delta);
	
	if (mili > 200 && gHistoriesDebugLevel > 0)
		DebugTN("sgHistoryStackTreatment >> Time to fill the buffer "  + mili + " mili for: " + dynlen(gPendingsEvents) + " pending events");
	
	// Th.V
	dynClear(gPendingsEvents);
	
	// **** Modification to have one file per day
	// PW august 2006
	bool isNewDay;
		
	// set flag to write file at 0 pm
	if (hour(getCurrentTime()) == 0 && !lastDayFileSaved)
	{
		isNewDay = true;
	}

	// reset flag at 1 pm
	if (hour(getCurrentTime()) == 1)
	{
		isNewDay = false;
		lastDayFileSaved = false;
	}
	
// Save if buffer is full or new day or force from event query
	if(strlen(gBuffer) > 10000 || (isNewDay && !lastDayFileSaved) || forceSavingBuffer)
	{
		// DebugTN("sgHistoryStackTreatment >> Will write to file: " + bufferString);
		// Th.V
		//strreplace(bufferString, " | ", "\n");
		// bufferString += "\n"; // ensure line break after buffer
		string fileName;
				
		file f;
		
		currentTime = getCurrentTime();
		yersterday = currentTime - (24 * 3600);
		
		dyn_string logsPath;
		
		logsPath = sgDBGet(GLOBAL_TABLE_NAME, DBKEY_LOGS_PATHS);
		
		for (int cpt = 1; cpt <= dynlen(logsPath); cpt++)
		{
			if(isNewDay && !lastDayFileSaved)  // case buffer empty at midnight, saved in yersterday file
				sprintf(fileName, "%s%04d-%02d-%02d.txt", logsPath[cpt], year(yersterday), month(yersterday), day(yersterday));
			else // normal case, buffer was full
				sprintf(fileName, "%s%04d-%02d-%02d.txt", logsPath[cpt], year(currentTime), month(currentTime), day(currentTime));
				
			f = fopen(fileName, "a");
			if (f != 0)
			{	
				// fputs(bufferString, f);
				fputs(gBuffer, f);
				fclose(f);
			}
			else
			{
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "Unable to write buffer in file " + fileName);
			}
		} // loop on logs files 
		//dyn_string empty;
		//buffer = empty;
		
	
	// **** Modification to have one file per day
	// PW august 2006
	// set flag, file has been saved
		if(isNewDay && !lastDayFileSaved)
		{
			lastDayFileSaved = true;
		}
		
		// Th.V
		gBuffer = "";
		sgDBSet(GLOBAL_TABLE_NAME, DBKEY_HISTORIES_BUFFER, buffer);		
	}
} // void sgHistoryStackTreatment()

bool sgRefreshShortHistories(bool forceSavingBuffer)
{
	dyn_string histories;
	
	histories = sgDBGet(GLOBAL_TABLE_NAME, DBKEY_ALL_HISTORIES);
	gStartRefreshHistories = getCurrentTime();
	int nb = 0;
	for(int cpt = 1; cpt <= dynlen(histories); cpt++)
	{
		bool modified;
		
		dyn_string ds;
		ds = sgDBGet(histories[cpt], DBKEY_HISTORY_MODIFIED);
		
		modified = ds[1];
		
		if(modified)
		{
			nb++;
			dyn_string events;
			
			events = sgDBGet(histories[cpt], DBKEY_HISTORY_QUEUE);

			int i;
			i = dpSet(histories[cpt] + SHORT_HISTORY_POSTFIX, events);			
			if(i != 0)
			{
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "Unable to set short history " + histories[cpt]);
				return false;
			}
			
			bool b;
			
			b = sgDBSet(histories[cpt], DBKEY_HISTORY_MODIFIED, "FALSE");
			if(!b)
			{
				sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "Unable to reset modified flag for history " + histories[cpt]);
				return false;
			}
		}
	}
	if (nb > 1 && gHistoriesDebugLevel > 1)
		DebugTN("sgRefreshShortHistories >> Will dpSet: " + nb + " histories");	
		
	time delta = getCurrentTime() - gStartRefreshHistories;
	int mili = period(delta) * 1000 + milliSecond(delta);
	if (mili > 200 && gHistoriesDebugLevel > 1)
		DebugTN("sgRefreshShortHistories >> elapsed time for dpSet: " + mili + " mili");
//	}
	
	sgHistoryStackTreatment(forceSavingBuffer); 	
	return true;
}

void connectQueriesToSavePendingEvents()
{
	// This function is called by the manager 
	// Just make a connection to know when a query must be processed
	dpConnect("HistoryQueryProcessToSavePendingsEvents", false, "FwUtils.HistoryQuery.Starter");
		
} // initsgFwQueries()

void HistoryQueryProcessToSavePendingsEvents(string dpName, string historyPoint)
{
	// This function is connected to the query client
	sgRefreshShortHistories(true); // force to save pending events in buffer
}


