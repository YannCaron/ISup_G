public const int DISPATCH_SYNC_TIMEOUT = 10;

public void dispatchObjectsSync(string dp) {
  dpQueryConnectAll ("dispatchObjectsQuery", false, "ident", "SELECT '_original.._value' FROM '" + dp + ".XMLDispatcher.Objects.{PreStatus, Label1, Message}'", DISPATCH_SYNC_TIMEOUT);
  sgHistoryAddEvent(dp + ".SystemHistory", SEVERITY_SYSTEM, "Objects connected");
}

public void dispatchEventsSync(string dp) {
  dpQueryConnectAll ("dispatchObjectsQuery", false, "ident", "SELECT '_original.._value' FROM '" + dp + ".XMLDispatcher.Events.{PreStatus, Label1}'", DISPATCH_SYNC_TIMEOUT);
  sgHistoryAddEvent(dp + ".SystemHistory", SEVERITY_SYSTEM, "Events connected");
}

public void dispatchObjectsQuery(string ident, dyn_dyn_anytype data) {
  mapping points;
  
  for (int r = 2; r <= dynlen(data); r++) {
    dyn_anytype row = data[r];
    
    points[(string)row[1]] = row[2];
  }

  dyn_string dps, values;  
  dyn_anytype keys = mappingKeys(points);
  for (int k = 1; k <= dynlen(keys); k++) {
    string key = keys[k];
    
    string dp = dpSubStr(key, DPSUB_DP);
    
    if (strpos(key, "Message") > 0) {
      dynAppend(dps, dp + ".Components.ErrorsList.Change.Object");
    } else if (strpos(key, "PreStatus") > 0) {
      dynAppend(dps, dp + ".Components.ErrorsList.Change.Status");
    } else {
      dynAppend(dps, dp + ".Components.ErrorsList.Change.FullText");
    }
    dynAppend(values, points[key]);
  }
  
  dpSet(dps, values);
  
}

// Th.V mai 18 2004

void initErrorsList()
{
	sgDBWaitForInit();	
	// DebugTN(" will init errors list");
	dyn_string errorsList;
	errorsList = getPointsOfType("sgErrorsList");
	
	for (int idErrorsList = 1; idErrorsList <= dynlen(errorsList); idErrorsList++)
	{
		// dpConnect for the script
		// 2007 09 19 aj connect directly to all change-dpes - avoid dpget in work function afterwards (can be changed again!!!!)
		dpConnect("statusChange", false, errorsList[idErrorsList] + ".Change.Object", errorsList[idErrorsList] + ".Change.Status", errorsList[idErrorsList] + ".Change.FullText");
	
		// dpConnect for the globalStatus
		dpConnect("listChange", false, errorsList[idErrorsList] + ".Lists.Texts", errorsList[idErrorsList] + ".GlobalStatus.PreStatus");
		
		// if the object list is empty set the status to OPS
		
		// DebugTN("initErrorsList >> will initialize the status of: " + errorsList[idErrorsList] + ".Change.Status");
		dyn_string ds;
		dpGet(errorsList[idErrorsList] + ".Lists.Objects", ds);
		if (dynlen(ds) == 0)
			dpSet(errorsList[idErrorsList] + ".GlobalStatus.PreStatus", OPS_STATUS);
		else
			dpSet(errorsList[idErrorsList] + ".GlobalStatus.PreStatus", U_S_STATUS);
	} // for	
}

void listChange(string listDpName, dyn_string texts, string preStatusDpName, string preStatusValue)
{
	// DebugTN("sgErrorsListLib: list changed, texts: " + texts + " status: " + preStatusValue);

	string errorsListName;	
	errorsListName = dpSubStr(listDpName, DPSUB_DP_EL);
		
	errorsListName = sgStripDpName(errorsListName, ".Lists.Texts");
		
	int nbItems;
	nbItems = dynlen(texts);
	
	// if list is empty, immediatly set pre status to ops
	if ((nbItems == 0) && !isOPS(preStatusValue))
	{
    // DebugN("sgErrorsListLib: List is empty for the point: " + errorsListName);
		dpSet(errorsListName + ".GlobalStatus.PreStatus", "OPS");
		return;
	}	 
	else if((nbItems == 0) && isOPS(preStatusValue))// list is empty, status is already OPS
	{
    // DebugN("sgErrorsListLib: List is already empty for the point: " + errorsListName + ", do nothing");
		return;
	}
	else if((nbItems != 0) && (isOPS(preStatusValue)))
	{
		// no delay in a connected function! it doesn't work 
		startThread("errorsListWaiter", errorsListName);
	}
} // void listsChange, string point, string value)

void errorsListWaiter(string errorsListName)
{
	// wait for the delay
	int delayTime;
	dpGet(errorsListName + ".Delay", delayTime);

	// DebugN("ErrorsListPanel >> listsChange: point: " + errorsListName + ", PreStatus: we must to wait");
	
	delay(delayTime);
	
	string status;

	dpGet(errorsListName + ".GlobalStatus.Status", status);
	dyn_string newTexts;
	// if list is not empty, set the presatus to U/S
	dpGet(errorsListName + ".Lists.Texts", newTexts);
	if (dynlen(newTexts) != 0)
	{
		//DebugN("List is not empty for the point: " + pointName);
		if (status != "U/S")
			dpSet(errorsListName + ".GlobalStatus.PreStatus", "U/S");
	}
}

// 2007 09 19 aj connect directly to all change-dpes - avoid dpget in work function afterwards (can be changed again!!!!)
void statusChange(string dpe1, string object,
									string dpe2, string status,
									string dpe3, string fulltext)
{
	dyn_string objectsList, statusList, textsList;

	// 21.07.2005 aj historyDP added to be able to use the library for EMNet as well
	// therefore a DPT using an ErrorsList has to have a SystemHistory directly below the root element!!
	string historyDP = dpSubStr(dpe2, DPSUB_DP) + ".SystemHistory";

	
	//  Get the point name
	string pointName;
	pointName = dpSubStr(dpe2, DPSUB_DP_EL);
	
	pointName = sgStripDpName(pointName, ".Change.Status");
	// DebugN("sgErrorsList: dpName after strip: " + pointName);
	
	//DebugN("ErrorsPanel >> point name: " +	pointName);
	
	// Get the object name and its status
// 2007 09 19 aj connect directly to all change-dpes - avoid dpget in work function afterwards (can be changed again!!!!)
//	string object, status;
	bool isOps;
		
// 2007 09 19 aj connect directly to all change-dpes - avoid dpget in work function afterwards (can be changed again!!!!)
//	dpGet(pointName + ".Change.Object", object,
//				pointName + ".Change.Status", status);
	
	dpGet(pointName + ".Lists.Objects", objectsList,
			  pointName + ".Lists.Statuses" , statusList,
				pointName + ".Lists.Texts"  , textsList);
	
	// check if same object with same status is already registered
	int index;
	index = dynContains(objectsList, object);
	
	// DebugTN("ErrorsListLib, statusChange >> object: " + object + " as index: " + index);
	
	if (index > 0)
	{ 
	  if (statusList[index] == status)
		{
			// DebugTN("ErrorsListLib, statusChange >> object: " + object + " already registred with status: " + status);
			sgHistoryAddEvent(historyDP, SEVERITY_SYSTEM, "statusChange >> object: " + object + " already registred with status: " + status);
			return;
		}
		else
		{
			// DebugTN("ErrorsListLib, statusChange >> object: " + object + " already registred, actual status is: " + statusList[index] + ", new status is: " + status);
			sgHistoryAddEvent(historyDP, SEVERITY_SYSTEM, "statusChange >> object: " + object + " already registred with status: " + status);
		} 		
	} 
	
	// Get the StatusConvTable to find if the point is in "OPS" state or not
	dyn_string inputs, outputs;
	dpGet(pointName + ".ConvTables.StatusConvTable.Input", inputs,
		    pointName + ".ConvTables.StatusConvTable.Output", outputs);
  			
	int id = dynContains(inputs, status);
	// DebugN("ErrorsListPAnel >> id: ", id);
	
	if (id == 0) {
		isOps == false;
	} else {
		isOps = outputs[id];
  }
			
	string level;	
	if (isOps == false)
	{
		// point is not ops: if already in the objects list update status and texts
		string dateTime;
		dateTime = formatTime("%d/%m %H:%M:%S", getCurrentTime());
		
		if (index > 0)
		{
			level = SEVERITY_WARNING;
			sgHistoryAddEvent(historyDP, SEVERITY_SYSTEM, "statusChange >> object: " + object + " already registred. Actual status is: " + statusList[index] + 
			                                         " + new status is: " + status);
			statusList[index] = status;
			
			// 2007 09 19 aj use fulltext in case there is one (text send directly from nms like it should be shown)
			// adding object id as it is used in the history when object is removed manually
			if (fulltext != "")
				textsList[index]   = fulltext + " (" + object + ")";
			else
				textsList[index]   = dateTime + " " + object + " " + status;
		}
		else
		{
			// new failed object
			level = SEVERITY_CRITICAL;
			// DebugN("StatusChange >> add object: ", object);
			dynAppend(objectsList, object);
			dynAppend(statusList, status);

			// 2007 09 19 aj use fulltext in case there is one (text send directly from nms like it should be shown)
			if (fulltext != "")
				dynAppend(textsList, fulltext + " (" + object + ")");
			else
				dynAppend(textsList, dateTime + " " + object + " " + status);
		}
	}
	else
	{
	 // object is ops: if in the failed objects list remove it !
	 if (index > 0)
	 {
	 		level = SEVERITY_SOLVED;
	 		if (status == "manually removed by the user")
	 			level = SEVERITY_WARNING;
      	 			
	 		//DebugN("StatusChange >> remove id: " + id);
	 		dynRemove(objectsList, index);
	 		dynRemove(statusList, index);
	 		dynRemove(textsList, index);
	 }
	 else
	 {
	 	// object is not on the falied object list: already "OPS" OPS -> OPS -> info
	 	level = SEVERITY_INFO;
	 	sgHistoryAddEvent(historyDP, SEVERITY_SYSTEM, "statusChange >> object: " + object + " OPS and not registred. Raw status is: " + status);
	 	return;
	 }
	}	
	
	// DebugN("ErrorsList: set new values in the list");
	// 2007 09 19 aj one single dpset
	dpSet(pointName + ".Lists.Objects", objectsList,
				pointName + ".Lists.Statuses" , statusList,
				pointName + ".Lists.Texts"  , textsList); 
	  	
  // DebugN("ErrorsList >> level: " + level);
 
	// 2007 09 19 aj use fulltext in case there is one (text send directly from nms like it should be shown)
	if (fulltext != "")
		sgHistoryAddEvent(pointName + ".History", level, fulltext + " (" + object + ")");
	else
		sgHistoryAddEvent(pointName + ".History", level, object + " " + status);
}
