// Globals for the server
dyn_string eventsHistories;
int nbEvents, cpt, gNbFiles;
bool bPercentCompleted;

const string MAX_EVENTS_NUMBER_REACHED = "Max events number reached";
const char TAB = '\t';
				
string convToTwoDigits(int value)
{
	string result, temp;
	sprintf(result, "%02d", value);
	return result;	
}

float translatTime(time delta)
{
	int seconds, dixiemmes, milliSeconds, temp;
	
	seconds = second(delta);
	int minutes = minute(delta);
	int hours = hour(delta);
	milliSeconds  = milliSecond(delta);
		
	temp = milliSeconds + (seconds * 1000);	
	dixiemmes = milliSeconds/100; //time in tenths of second
	return hours * 3600 + minutes * 60 + seconds + ((float)dixiemmes/10);
} // float translatTime(time delta)
	
void initsgFwQueries()
{
	// This function is called by the manager 
	// Just make a connection to know when a query must be processed
	dpConnect("HistoryQueryProcess", false, "FwUtils.HistoryQuery.Starter");
		
} // initsgFwQueries()

void HistoryQueryProcess(string dpName, string historyPoint)
{
	// This function is connected to the query client
	
	string activeChain;
	dpGet(ACTIVE_CHAIN, activeChain);
	
	// 31.03.2005 aj query is only done on the active chain
	if ( (isServerA(getHostname()) && activeChain != "A") || (isServerB(getHostname()) && activeChain != "B") )
	{
	 	//DebugTN("sgFwQueryLib >> passive host, stop");
		return;
	}

		
	// create the historyPoint
	// DebugN("sgFwQueryLib >> The server will create the point: " + historyPoint);
	dpCreate(historyPoint, "sgFwHistoryQuery");	

	// 31.03.2005 aj to avoid errors that dp doesn't exist if the UI is on the passive host
 	do
 	 		delay(0,500);
 	while( !dpExists(historyPoint));
 	//DebugTN("sgFwQueryLib >> continue ", historyPoint);

	
	// wait for the client to write the query	
	time start, stop;
	start = getCurrentTime();
	
	int MaxEventsNumber;

	while (getCurrentTime() - start < 5)
	{
		int t;
		dpGet(historyPoint + ".Query.MaxEventsNumber", MaxEventsNumber);
		// DebugN("sgFwQueryLib >> the server is waiting for: " +  historyPoint + ".Query.MaxEventsNumber");
		if (MaxEventsNumber > 0)
			break;
			
		dpSet(historyPoint + ".Result.PercentCompleted", "sgFwQueryLib >> the server is waiting for the client to write the query in the remote point");	
		delay(0, 200);
	}
	
	if (MaxEventsNumber == 0)
	{
		DebugN("sgFwQueryLib >> the client was unable to write the query, or the MaxEventsNumber = 0");
		dpSet(historyPoint + ".Result.Events", "Invalid query to be deleted");
		delay(1);
		deleteHistoriesPoints();
		return;
	}
		
	cpt = 0;
	// clear the dynString
	dynClear(eventsHistories);
			
	// DebugN("sgFwQueryLib >> historyPoint: " + historyPoint);
	dpSet(historyPoint + ".Result.PercentCompleted", "In progress");
	bPercentCompleted = true;
	// Read the query
	string queue;
	string from, to;
			
	// Read the query
	dpGet(historyPoint + ".Query.Queue", queue);
	// DebugN("sgFwQueryLib >> queue: " + queue);
	dpGet(historyPoint + ".Query.From", from,
				historyPoint + ".Query.To", to,
				historyPoint + ".Query.MaxEventsNumber", MaxEventsNumber);
				
	// DebugN("sgFwQueryLib >> from: " + from + ",  to " + to);
	
	// get dpName corresponding to queue
	
	
	
	// Generate file name to process
	dyn_string fileNames, yearNames;
	string dayFrom, monthFrom, yearFrom, fileName;
	
	// extrating date from
	dyn_string temp;
	temp = strsplit(from, ".");
	yearFrom = temp[1];
	monthFrom = temp[2];
	
	temp  = strsplit(temp[3], " ");
	dayFrom = temp[1];
	
	// extracting day to
	string dayTo, monthTo, yearTo;
	temp = strsplit(to, ".");
	yearTo = temp[1];
	monthTo = temp[2];
	
	temp  = strsplit(temp[3], " ");
	dayTo = temp[1];
	
	// create time objects
	time t1, t2;
	setTime(t1, yearFrom, monthFrom, dayFrom);
	setTime(t2, yearTo, monthTo, dayTo);
	
	// Getting the date range
	int oneDay = 60 * 60 * 24;
	
	// get the log path
	dyn_string dyn_path;
	string path;
	dpGet("FwUtils.LogsPath", dyn_path);
	path = dyn_path[1];

	while (t1 <= t2)
	{
		
		fileName = path + year(t1) + "-" + convToTwoDigits(month(t1)) + "-" + convToTwoDigits(day(t1)) + ".txt";
		dynAppend(fileNames, fileName);
		dynAppend(yearNames, year(t1));
		t1 += oneDay;
	}   // while 
	
	// to be shure to have all events (buffer can be written the day after) we add one file
	sprintf(fileName, "%s%04d-%02d-%02d.txt", path, year(t1), month(t1), day(t1));
	
	// test if file exist (may be tomorrow !)
//	if (getFileSize(fileName) != -1)
//		dynAppend(fileNames, fileName);
		
//	DebugN("HistoryQuery >> files to process: " + fileNames);
			
	// processing log files
	nbEvents = 0;
	int totalFilesSize = 0;
	bool end = false; // This flag will be true when the time stamp is out of the within range
	gNbFiles = 0;
	for (int id = 1; id <= dynlen(fileNames); id++)
	{
		end = processQueryLogFile(queue, fileNames[id], yearNames[id], from, to, MaxEventsNumber, historyPoint);
		totalFilesSize += getFileSize(fileNames[id]);
		// DebugN("HistoryQuery >> fileName: " + fileNames[id] +  " nbTotEventsHistories: " + dynlen(eventsHistories) + " nbTotEvents: " + cpt);
		if (end)
			break;			
	}
	
	// DebugN("sgFwQueryLib >> Result: " + eventsHistories);
	if (dynlen(eventsHistories) == 0)
		dynAppend(eventsHistories, "No events in this time range");
		
	dpSet(historyPoint + ".Result.Events", eventsHistories);
	stop = getCurrentTime();
	int deltaTime = (stop - start);
	if (deltaTime == 0)
		deltaTime = 1;
	int perf = cpt / deltaTime;
	
	string elaplsedTime  = translatTime(stop - start);
	// DebugTN("HistoryQuery performance is: aprox " + perf + " events/sec, total size is: " + (float)totalFilesSize/(float)1000000 + " MO on: " + gNbFiles + " files + in: " + elaplsedTime + " seconds");
		
	// erase old points
	// wait to be shure the client can get the result
	delay(2);
	deleteHistoriesPoints();
} // HistoryQueryProcess

void deleteHistoriesPoints()
{

	dyn_string histories;
	histories = getPointsOfType("sgFwHistoryQuery");
	// DebugN("HistoryQuery >>  liste of hitories: " + histories);
	for (int i = 1; i <= dynlen(histories); i++)
	{
		dyn_string events;
		dpGet(histories[i] + ".Result.Events", events);

		
		// erase only points with results
		if (dynlen(events) > 0)
		{
			// DebugN("HistoryQuery >> will delete point: " + histories[i]);
			dpDelete(histories[i]);
		} 
		else
			DebugN("HistoryQuery >> " + histories[i] + " has no result, may be a query is currentli in execution or this point must be deleted by hand");
	}
} // void deleteHistoryPoints()

bool processQueryLogFile(dyn_string queue, string fileName, int yearName, time from, time to, int MaxEventsNumber, string historyPoint)
{
	// This function return true when the time stamp of the current event is after the within range (parameter to)
	// open the file
	file handle;
	handle = fopen(fileName, "r"); // Create a new file
	if (handle == 0)
	{
		// DebugN("HistoryQuery >> Unable to open file: " + fileName); 
		return false;
  } 
  
  dyn_string allHistories;
  allHistories = getPointsOfType("sgFwHistory");
    
	gNbFiles++;
	while (feof(handle)==0) // as long as it is not at the end of the file 
	{
		string line, tampon;

		fgets(line, 1024, handle);

		// increment the parsed lines counter
		cpt++;

		// to flash the percentCompleted label
		if (cpt % 3000 == 0)
		{
			if (bPercentCompleted == true)
			{
				dpSet(historyPoint + ".Result.PercentCompleted", "");
				// DebugTN("HistoryQuery >> cpt: " + cpt + " text: ");
				bPercentCompleted = false;
			}
			else
			{
				dpSet(historyPoint + ".Result.PercentCompleted", "In progress");
				// DebugTN("HistoryQuery >> cpt: " + cpt + " text: In Progress");
				bPercentCompleted = true;
			}
			delay(0,50);	
		}	// modulo

		// to preserve the cpu load
		if (cpt % 50 == 0)
		{
			delay(0,01);
		}
		
		string eventHistory;
		string eventDate;
		string eventTime;
		string eventSeverity;
		string eventText;
		string eventMessage;
		
		dyn_string ds;
		ds = strsplit(line, EVENTTEXT_DELIMITER);
		
		// evaluate ds length; line can be not an event line (for example xml)
		int dsLength;
		dsLength = dynlen(ds);
		
		if((dsLength >= 1) && (dynContains(allHistories, ds[1]) >= 1))  // is an event line AND History name is possible
		{
			eventHistory = ds[1];
			eventDate = ds[2];
			eventTime = ds[3];
			eventSeverity = ds[4];
			eventText = ds[5];
			if(dsLength >= 6) // event message is optional
				eventMessage = ds[6];
			else
				eventMessage = "";
			
			// process date
			int eventDay;
			int eventMonth;
			int eventYear;
			
			dyn_string dsDate;
			dsDate = strsplit(eventDate, "/");
			
			eventDay = dsDate[1];
			eventMonth = dsDate[2];
			eventYear = 2000 + (int) dsDate[3]; // year is without the century
			
			// process time
			int eventHour;
			int eventMinute;
			int eventSecond;
			
			dyn_string dsTime;
			dsTime = strsplit(eventTime, ":");
			
			eventHour = dsTime[1];
			eventMinute = dsTime[2];
			eventSecond = dsTime[3];
		 		 	
			time timeStamp;
			timeStamp = makeTime(eventYear, eventMonth, eventDay, eventHour, eventMinute);
						
			if (timeStamp < from)
			{
				continue;
			}
				
			if (timeStamp > to)
			{
				return true;
			}
		
			if (queue == eventHistory)
			{
				// extract the event 
				string event;
				// delete the event history
		//		event = substr(line, strpos(line, EVENTTEXT_DELIMITER) + 1);
				
			//	event = strreplace(event, "\r\f", "");   // the new line Character

		

				event = eventDate + EVENTTEXT_DELIMITER + eventTime + EVENTTEXT_DELIMITER + eventSeverity + 
														EVENTTEXT_DELIMITER + eventText + EVENTTEXT_DELIMITER + eventMessage;
				// delete last Char (Newline)
				event = substr(event, 0, strlen(event) - 1);

				dynAppend(eventsHistories, event);
				nbEvents++;
			}
			
			if (nbEvents >= MaxEventsNumber)
			{
				// add line to inform that max events number is reached. Severity is system severity
				string maxEventsLine;
				maxEventsLine = "   ---" + EVENTTEXT_DELIMITER + "   ---" + EVENTTEXT_DELIMITER + SEVERITY_SYSTEM + EVENTTEXT_DELIMITER + MAX_EVENTS_NUMBER_REACHED;
				
				dynAppend(eventsHistories, maxEventsLine);
				return true;
			}
			
		} // if .. history != ""	
	} // while ! eof	
	fclose(handle);
	
	return false;
} // processQueryLogFile



