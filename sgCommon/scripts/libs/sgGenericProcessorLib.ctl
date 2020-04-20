string gActiveChain;

const string DB_KEY_PROCESSOR_OLDSTATUS = "ProcessorOldStatus";

string getThisChain()
{
	string thisChain;
	if(isServerA(getHostname()))
		thisChain = "A";
	else if(isServerB(getHostname()))
		thisChain = "B";
		
	return thisChain;
}

void updateProcessor(char thisChain, string statusDpName, string processorTableName, string historyDp, string secondProcessorTableName) //, string thirdProcessorTableName = "")
{
	string activeChain = "";
	string currentStatus;
	dpGet("FwUtils.Framework.ActiveChain", activeChain,
				statusDpName, currentStatus);
	
	// Check if the status of this chain is the same as the preceding loop
	if (activeChain != gActiveChain)
	{
		// DebugTN("sgProcessor >> detecting a switch over");
		// wait for the new status of the processor
		delay(1);
		// DebugTN("sgProcessor >> end of the delay");
		bool b;
		b = sgDBSet(DBKEY_PROCESSOR_PREFIX + processorTableName, DB_KEY_PROCESSOR_OLDSTATUS, -1);
		if (!b)
			DebugN("sgGwenericProcessorLib >> unable to set variable: " + DB_KEY_PROCESSOR_OLDSTATUS + " on table: " + processorTableName + " with value: -1");
			
		b = sgDBSet(DBKEY_PROCESSOR_PREFIX + secondProcessorTableName, DB_KEY_PROCESSOR_OLDSTATUS, -1);
		if (!b)
			DebugN("sgGwenericProcessorLib >> unable to set variable: " + DB_KEY_PROCESSOR_OLDSTATUS + " on table: " + secondProcessorTableName + " with value: -1");

//		if (thirdProcessorTableName != "")
//		{
//			b = sgDBSet(DBKEY_PROCESSOR_PREFIX + thirdProcessorTableName, DB_KEY_PROCESSOR_OLDSTATUS, -1);
//			if (!b)
//				DebugN("sgGwenericProcessorLib >> unable to set variable: " + DB_KEY_PROCESSOR_OLDSTATUS + " on table: " + thirdProcessorTableName + " with value: -1");
//		}
			
		gActiveChain = activeChain;
	}
	
	 dyn_string ds;
	 ds = sgDBGet(DBKEY_PROCESSOR_PREFIX + processorTableName, DB_KEY_PROCESSOR_OLDSTATUS);
	 int oldStatus;
	 oldStatus = ds[1];
	
	string newStatus = sgProcessorsGetStatus(processorTableName);	
	
	// parse messages if status is open
	if (newStatus == PROC_STATUS_OPEN)
		sgGenericProcessorParseMessagesReceive(processorTableName, historyDp);	
		
	// VL,AJ: 24-JUN-2005: added this check to re-write status in case of timeout after a switchover			
	if(isUKN(currentStatus))
	{
		if(thisChain == gActiveChain)
		{
			if (newStatus == PROC_STATUS_OPEN)
				dpSet(statusDpName, OPS_STATUS);
			else
				dpSet(statusDpName, U_S_STATUS);
		}
		else
		{
			dpSet(statusDpName, SBY_STATUS);
		}
	}

	
	// check if the status as changed
	if (newStatus == oldStatus)
		return;
	else
	{
		// status changed
		// DebugTN("sgGenericProcessorLib  >> status of chain: " + thisChain + " was: " + oldStatus + " is now: " + newStatus + " for processor: " + processorTableName);
						
		sgDBSet(DBKEY_PROCESSOR_PREFIX + processorTableName, DB_KEY_PROCESSOR_OLDSTATUS, newStatus);	
							
		if (thisChain == gActiveChain)
		{
			if (newStatus == PROC_STATUS_OPEN)
				dpSet(statusDpName, OPS_STATUS);
			else
				dpSet(statusDpName, U_S_STATUS);	
		}
		else
		{				
			// DebugTN("chain: " + thisChain + " is SBY");
		  dpSet(statusDpName, SBY_STATUS);	
		 }
	}
}

void sgGenericProcessorParseMessagesReceive(string processor, string history)
{

 	dyn_string messages;
	messages = sgProcessorsGetMessages(processor);
		
	// DebugTN("sgGenericProcessorParseMessagesReceive there is: " + dynlen(messages) + " message in the queue");
	for(int cpt = 1; cpt <= dynlen(messages); cpt++)
	{
		dyn_dyn_string xmls;
		xmls = XMLsplit(messages[cpt]);

		dyn_string xmlReceived = xmls[1];
		// DebugN("updateINCHProcessor xml: " + xmlReceived);
		dyn_int indexes;
		indexes = XMLfindTagIndex(xmlReceived, "ISupStatus");

		string answer;
		if(dynlen(indexes) != 0)
		{	
			answer = XMLanalyseISupStatus(xmlReceived, true);
			sgGenericProcessorCommandAck(processor, history, xmlReceived);
		} // if 
	
		if (answer != "")
		{
				// DebugTN("updateINCHProcessor >> Will answer:\n" + answer);
				sgProcessorsSendMessage(processor, answer);
		}
	}
}

// Process the command XML message 
void sgGenericProcessorCommandAck(string history, dyn_string command)
{
	dyn_int indexes;
	int cpt;
	dyn_string commandTags;
	string res;
	
	indexes = XMLfindTagIndex(command, "ISupCommand");	

	for(cpt = 1; cpt <= dynlen(indexes); cpt++)
	{
		commandTags = XMLextractSubTag(command, "System", indexes[cpt]);
		
//		DebugTN("sgGenericProcessorCommandAck >> System command tag:" + commandTags);
		sgGenericProcessorCommandSystem(history, commandTags);
	}	
}

void sgGenericProcessorCommand(string histroy, dyn_string command)
{
	dyn_int indexes;
	int cpt;
	dyn_string systemTags;
	string res;
	
	indexes = XMLfindTagIndex(command, "System");	

	// check version

	for(cpt = 1; cpt <= dynlen(indexes); cpt++)
	{
		systemTags = XMLextractSubTag(command, "System", indexes[cpt]);
		sgGenericProcessorCommandSystem(history, systemTags);
	}	
}

// Process the command XML message (system)
void sgGenericProcessorCommandSystem(string history, dyn_string systemTags)
{
	dyn_int indexes;
	int cpt;
	dyn_string subSystem;
	string systemName;

	
	indexes = XMLfindTagIndex(systemTags, "SubSystem");	
	
	systemName = XMLgetTagProperty(systemTags[1], "Name");
//	DebugN("Process system " + systemName);	
	for(cpt = 1; cpt <= dynlen(indexes); cpt++)
	{
		subSystem = XMLextractSubTag(systemTags, "SubSystem", indexes[cpt]);
		
		sgGenericProcessorCommandSubSystem(history, subSystem, systemName);
	}
}

// Process the command XML message (subSystem)
void sgGenericProcessorCommandSubSystem(string history, dyn_string tags, string systemName)
{
	dyn_int indexes;
	int cpt;
	dyn_string commandTags;
	string subSystemName;
	string systemPrefix;

	indexes = XMLfindTagIndex(tags, "Command");
	
	subSystemName = XMLgetTagProperty(tags[1], "Name");
//	DebugN("Process subsystem " + systemName + "." + subSystemName + " with status " + status);	
	for(cpt = 1; cpt <= dynlen(indexes); cpt++)
	{
		commandTags = XMLextractSubTag(tags, "Command", indexes[cpt]);
		sgGenericProcessorCommandTag(history, commandTags, systemName, subSystemName);		
	}	
}

// Process the command XML message (tag) and add event
void sgGenericProcessorCommandTag(string history, dyn_string tags, string systemName, string subSystemName)
{
	string commandName;
	commandName = XMLgetTagProperty(tags[1], "Name");
	
	sgHistoryAddEvent(history, SEVERITY_SYSTEM, "Command " + commandName + " " + subSystemName + " acknowledged by " + systemName);
}

bool sgGenericProcessorUpdateTimeout(string processorName, string heartbeatDpName)
{
	dyn_string ds;
	ds = sgDBGet(DBKEY_PROCESSOR_PREFIX + processorName, "Status", ds);
	int interfaceStatus = ds[1];
	// DebugTN("updateSylexTimeOuts >> interfaceSatus: " + interfaceStatus);
	
	if (interfaceStatus == PROC_STATUS_OPEN)
	{
		dpSet(heartbeatDpName, "Received");
		return true;
	}	
	return false;
}

