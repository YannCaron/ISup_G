
void xxNetInitxxNet(string netType)
{
	// for each partion check if critical events are empty and in this case set status to OPS
	// get partitions from table partitionConvTable
	
	dyn_string partitionsNode;
	dpGet(netType + ".ConvTables.PartitionConvTable.Output", partitionsNode);
	
	for (int cpt = 1; cpt <= dynlen(partitionsNode); cpt++)
	{
		dyn_string ds;
		dpGet(netType + "." + partitionsNode[cpt] + ".NewCriticalEvents", ds);
		//DebugTN("initxxNet >> will get: " + netType + ". " + partitionsNode[cpt] + ".NewCriticalEvents");
		
		//DebugTN("initxxNet >> will set: " + netType + "." + partitionsNode[cpt] + ".CriticalEventsStatus");
		
		if (dynlen(ds) == 0)
			dpSet(netType + "." + partitionsNode[cpt] + ".CriticalEventsStatus.PreStatus", OPS_STATUS);
		else
			dpSet(netType + "." + partitionsNode[cpt] + ".CriticalEventsStatus.PreStatus", U_S_STATUS);	
	}
}

void xxNetNodeInfo(string netType, string fullName, string type, string text, string code)
{
	//DebugN("xxNetNodeInfo >> fullName: " + fullName + " type: " + type + " text: " + text + " code: " + code);
	
	// trim the full name to avoid multiple points
	string trimmedName;
	trimmedName = strrtrim(fullName, ".");
	
	// is the text a remarkable critical event ?
	dyn_string allowedCriticalEvents;
	dpGet(netType + ".AllowedCriticalEvents", allowedCriticalEvents);
	
	bool found = false;
	for (int cpt = 1; cpt <= dynlen(allowedCriticalEvents); cpt++)
	{
		if (strpos(text, allowedCriticalEvents[cpt]) != -1)
		{
			found = true;
			break;
		}
	}
	
	// store critical events with info if the event is accepted by the filter (allowedCriticalEvents)
	string s;
	string event;
	event = "critical events: node " + trimmedName + " (" + type + ") " + text + " (" + code + ")"; 
	
	if (found)
		s = "Accepted ";
	else
		s = "Rejected ";
		
	s += event;	
	sgHistoryAddEvent(netType + ".CriticalEventsHistory", SEVERITY_SYSTEM, s);  

	if (!found)
	{	
		//DebugTN("sgXXNetCallBacksLib >> no remarkable event");
		return; // not a remarkable event
	}
	
	// only for ScNet this has to be done ...
	string baseName;
	bool isSetiNetEvent = false;

	if (dpExists(netType + ".SetiNetNodes"))
	{		
		// is the event in the setiNet node list ?
  	//DebugTN("sgXXNetCallBacksLib >> SetiNetNodes exists");
		dyn_string setiNetList;
		dpGet(netType + ".SetiNetNodes", setiNetList);
		
		for (int cpt = 1; cpt <= dynlen(setiNetList); cpt++)
		{
			if (stringMatchPattern(trimmedName, setiNetList[cpt]))
			{
				isSetiNetEvent = true;
				break;
			}
		} // for
	
		if (isSetiNetEvent)
			baseName = netType + ".SetiNet";
		else
			baseName = netType + ".scNet";
	}
	else
	{
		baseName = netType + "." +netType;
	}
 	
	//DebugTN("sgXXNetCallBacksLib >>", baseName);
		
	// historyAddEvent, NewCriticalEvent, criticalEventStatus
	
	s = formatTime("%d/%m %H:%M:%S", getCurrentTime()) + " " + event;
	
	sgHistoryAddEvent(netType + ".SystemHistory", SEVERITY_SYSTEM, "xxNetNodeInfo (event) for " + netType + " >>\t fullName:\t" + fullName + "\ttype:\t" + type +  "\ttext:\t" + text + "\tcode:\t" + code + "\tSetiNet event:\t" +  isSetiNetEvent);
	dpSet(baseName + ".CriticalEventsStatus.PreStatus", "U/S");
	
	// append the new critical event to the existing list
	dyn_string criticalEvents;
	dpGet(baseName + ".NewCriticalEvents", criticalEvents);
		
	// check if event already exist
	for (int cpt = 1; cpt <= dynlen(criticalEvents); cpt++)
	{
		if (strpos(criticalEvents[cpt], event) != -1)
		{
			// DebugTN("xxNetNodeInfo >> event: " + event + " already exist");
			return;
		}
	}
	
	sgHistoryAddEvent(baseName + ".ErrorsList.History" , SEVERITY_SYSTEM, event);
	dynAppend(criticalEvents, s);
	dpSet(baseName + ".NewCriticalEvents", criticalEvents);
} // xxNetNodeInfo

void xxNetCall(string netType, string name, string type, string status, string partitionName)
{
	//DebugN("xxNetCall >> 'raw data' name: " + name + " type: " + type + " status: " + status + " partionName: " + partitionName);
	
	string trimmedName;
	
	trimmedName = strrtrim(name, ".");
	
	// convert the type (integer) to a text with the table CallTypeConvTable
	dyn_string typeInput, typeOutput;
	dpGet(netType + ".ConvTables.CallTypeConvTable.Input", typeInput);
	dpGet(netType + ".ConvTables.CallTypeConvTable.Output", typeOutput);
	
	int index;
	index = dynContains(typeInput, type);
	string typeText;
	if (index != 0)
		typeText = typeOutput[index];
	else
	{
		typeText = "unrecognised call type (OID value: " + type + " )";
		sgHistoryAddEvent(netType + ".SystemHistory", SEVERITY_SYSTEM, "xxNetCall for " + netType + " >> xxNet.ConvTables.CallTypeConvTable.Input unreconised call type (OID value: " + type + " )");
	}
	
	string objectName = trimmedName + " (" + typeText + ")";
	
	// convert the status (integer) to a text with the table CallStatusConvTable	
	dyn_string statusInput, statusOutput;
	dpGet(netType + ".ConvTables.CallStatusConvTable.Input", statusInput);
	dpGet(netType + ".ConvTables.CallStatusConvTable.Output", statusOutput);
	
	string statusText;
	index = dynContains(statusInput, status);
	if (index != 0)
		statusText = statusOutput[index];
	else
	{
		statusText = "unrecognised call status (OID value: " + status + " )";
		sgHistoryAddEvent(netType + ".SystemHistory", SEVERITY_SYSTEM, "xxNetCall (object) for " + netType + " >> xxNet.ConvTables.CallStatusConvTable.Input unrecognised call status (OID value: " + status + " )");
	}
	
	sgHistoryAddEvent(netType + ".SystemHistory", SEVERITY_SYSTEM, "xxNetCall (object) for " + netType + " >>\tname:\t" + name + "\ttype:\t" + type + "\tstatus:\t" + status + "\tpartitionName:\t" + partitionName + "\tfinded type:\t" + typeText + "\tfinded status:\t" + statusText);
	
	// network corresponding to the partition name
	xxNetSetObject(netType, objectName, statusText, partitionName);	
} // xxNetCall

void xxNetSetObject(string netType, string name, string status, string partitionName)
{

	dyn_string partitionNames, networks;
	dpGet(netType + ".ConvTables.PartitionConvTable.Input", partitionNames);
	dpGet(netType + ".ConvTables.PartitionConvTable.Output", networks);
	
	int index;
	string partition = strrtrim(partitionName, ".");
	index = dynContains(partitionNames, partition);
	string network;
	if (index == 0)
	{
		network = networks[1];
		sgHistoryAddEvent(netType + ".SystemHistory", SEVERITY_SYSTEM, "xxNetSetObject for " + netType + " >>\tname:\t" + name + "\tstatus:\t: " + status + "\tpartitionName:\t" + partitionName + "\t warning unrocognised partition!");
	}
	else
		network = networks[index];
		
	sgHistoryAddEvent(netType + ".SystemHistory", SEVERITY_SYSTEM, "xxNetSetObject for " + netType + " >>\tname:\t" + name + "\tstatus:\t: " + status + "\tpartitionName:\t" + partitionName + "\tnetwork finded:\t" + network);
		
	// send the event to the errors list
	// 2007 09 19 aj
	// one dpset to avoid double trigger of callback function
	// adding dpe fulltext for lan nms - has to be empty for scnet etc.
	dpSet(netType + "." + network + ".ErrorsList.Change.Object", name,
				netType + "." + network + ".ErrorsList.Change.Status", status,
				netType + "." + network + ".ErrorsList.Change.FullText", "");	
}

void xxNetPhysicalLink(string netType, string name, string type, string status, string partitionName)
{
	//DebugN("xxNetPhysicalLink >> name: " + name + " type: " + type + " status: " + status + " partionName: " + partitionName);
	
	string trimmedName;
	
	trimmedName = strrtrim(name, ".");
	
	// convert the type (integer) to a text with the table CallTypeConvTable
	dyn_string typeInput, typeOutput;
	dpGet(netType + ".ConvTables.PhysicalTypeConvTable.Input", typeInput);
	dpGet(netType + ".ConvTables.PhysicalTypeConvTable.Output", typeOutput);
	
	int index;
	index = dynContains(typeInput, type);
	string typeText;
	if (index != 0)
		typeText = typeOutput[index];
	else
	{
		typeText = "unrecognised physical link (OID value: " + type + ")";
		sgHistoryAddEvent(netType + ".SystemHistory", SEVERITY_SYSTEM, "xxNetPhysicalLink for " + netType + " >> xxNet.ConvTables.PhysicalTypeConvTable.Input unrecognised physical link (OID value: " + type + "), (trimmed name: " + trimmedName + "), (status: " + status + "), (partition name: " + partitionName);
	}
	
	string objectName = trimmedName + " (" + typeText + ")";
	
	// convert the status (integer) to a text with the table CallStatusConvTable	
	dyn_string statusInput, statusOutput;
	dpGet(netType + ".ConvTables.PhysicalStatusConvTable.Input", statusInput);
	dpGet(netType + ".ConvTables.PhysicalStatusConvTable.Output", statusOutput);
	
	string statusText;
	index = dynContains(statusInput, status);
	if (index != 0)
		statusText = statusOutput[index];
	else
	{
		statusText = "unrecognised link status (OID value: " + status + " )";
		sgHistoryAddEvent(netType + ".SystemHistory", SEVERITY_SYSTEM, "xxNetPhysicalLink for " + netType + " >> xxNet.ConvTables.PhysicalStatusConvTable.Input unrecongnised link status (OID value: " + status + " )");
	}
		
	sgHistoryAddEvent(netType + ".SystemHistory", SEVERITY_SYSTEM, "xxNetPhysicalLink for " + netType + " >>\tname:\t" + name + "\ttype:\t" + type + "\tstatus:\t" + status + "\tpartitionName:\t" + partitionName + "\tphysical type finded:\t" + typeText + "\tstatus finded \t" + statusText);
	// network corresponding to the partition name
	xxNetSetObject(netType, objectName, statusText, partitionName);		
} // xxNetPhysicalLink

void xxNetHeartbeat(string netType, string sysDescr, string uptime)
{
	// Heartbeat ar for all systems: scNet and setiNet and EMNet
	// DebugN("xxNetHeartbeat >> sysDescr: " + sysDescr + "uptime: " + uptime);
	dyn_string points = getPointsFromPattern(netType + ".*.TimeoutRef.PreStatus");
	
	//DebugTN("sgXXNetCallBacksLib >>", points, netType);
	
	for (int cptPoints = 1; cptPoints <= dynlen(points); cptPoints++)
		dpSet(points[cptPoints], "OPS");
}