const string SYLEX_PROCESSOR = "Sylex processor";

int gSylexId;
int gStatus1 = -1;
int gStatus2 = -1;
string gActivChain;

main()
{
	gSylexId = 1;

	sgDBWaitForInit();
	
	if (!initISupXMLLib())
		return;
	
	forceAllSylexToUKN();
	
	dpConnect("sylexCommandOutChanged", "SYLEX.Commands.Out");
	
	string hostAddress1, hostAddress2, hostAddress3;
	int port1, port2, port3, timeout;
	dpGet("SYLEX.Config.HostAddress1", hostAddress1,
	      "SYLEX.Config.HostAddress2", hostAddress2,
//	      "SYLEX.Config.HostAddress3", hostAddress3,
	      "SYLEX.Config.Timeout", timeout);
        
	port1 = getConfigValue(hostAddress1);
	port2 = getConfigValue(hostAddress2);
//	port3 = getConfigValue(hostAddress3);
	
	string processorName1 = SYLEX_PROCESSOR + 1;
	string processorName2 = SYLEX_PROCESSOR + 2;
//	string processorName3 = SYLEX_PROCESSOR + 3;
	 	
	sgProcessorCreate(processorName1, hostAddress1, port1, timeout, "7", true);
	sgProcessorCreate(processorName2, hostAddress2, port2, timeout, "7", true);
//	sgProcessorCreate(processorName3, hostAddress3, port3, timeout, "7", true);
		
	bool b = sgDBSet(DBKEY_PROCESSOR_PREFIX + processorName1, DB_KEY_PROCESSOR_OLDSTATUS, 0);
	if (!b)
	{
		DebugTN("sgINCHProcessor >> unable to add DB_KEY_PROCESSOR_OLDSTATUS variable to the table" +  processorName1);
		return;
	}
	
	bool b = sgDBSet(DBKEY_PROCESSOR_PREFIX + processorName2, DB_KEY_PROCESSOR_OLDSTATUS, 0);
	if (!b)
	{
		DebugTN("sgINCHProcessor >> unable to add DB_KEY_PROCESSOR_OLDSTATUS variable to the table" +  processorName2);
		return;
	}

	//bool b = sgDBSet(DBKEY_PROCESSOR_PREFIX + processorName3, DB_KEY_PROCESSOR_OLDSTATUS, 0);
//	if (!b)
//	{
//		DebugTN("sgINCHProcessor >> unable to add DB_KEY_PROCESSOR_OLDSTATUS variable to the table" +  processorName2);
//		return;
//	}
	
	string thisChain = getThisChain();
	
	dpConnect("sylexActivchainChanged", ACTIVE_CHAIN);
	
	while(true)
	{
		updateProcessor(thisChain, "SYLEX.SYLEX" + 1 + ".Interface" + thisChain + "Status.PreStatus", processorName1, "SYLEX.History", processorName2);
		updateProcessor(thisChain, "SYLEX.SYLEX" + 2 + ".Interface" + thisChain + "Status.PreStatus", processorName2, "SYLEX.History", processorName1);
//		updateProcessor(thisChain, "SYLEX.SYLEX" + 3 + ".Interface" + thisChain + "Status.PreStatus", processorName3, "SYLEX.History", processorName1, processorName2);
		
		updateSylexTimeOuts(1);		
		updateSylexTimeOuts(2);		
//		updateSylexTimeOuts(3);		
		delay(1);
	}
}

void sylexActivchainChanged(string dpName, string dpValue)
{
	// DebugTN("sylexActivChainChanged >> new activ chain is: " + dpValue);
	gActivChain = dpValue;
}

void sylexSendCommand(string text)
{
	 // tell the socket manager to send the message (it can be from a button...)
	// DebugTN("sylexSendCommand >> will send to SYLEX: " + text);
	dpSet("SYLEX.SYLEX" + gSylexId + ".CommandOut", text);
}

void sylexOutput(string commandOutDpName, string commandOutValue)
{
	int res;
	string xml;
	string tag;
	string subSystemName;
	string command;
	string serverStatus;
	
	if(commandOutValue == "")
		return;
	
	// DebugTN("sylexOutput starts for message " + commandOutValue);
	
	// Refresh command
	if(commandOutValue == "Refresh")
	{
		tag = XMLcreateTag("Command", makeDynString("Name"), makeDynString("Refresh"), "");	
		tag = XMLcreateTag("SubSystem", makeDynString("Name"), makeDynString("SYLEX"), tag);	
		tag = XMLcreateTag("System", makeDynString("Name"), makeDynString("SYLEX" + gSylexId), tag);	
		tag = XMLcreateTag("ISupCommand", makeDynString("Version"), makeDynString("1.0"), tag);	
		xml = tag;
		//set all statuses to UKN for refresh
		forceAllSylexToUKN();
		delay(1);
	}
	// Connect or Disconnect command
	else if((strpos(commandOutValue, "Connect") != -1 ) || (strpos(commandOutValue, "Disconnect") != -1 ))
	{
		// Get system name
		subSystemName = substr(commandOutValue, strpos(commandOutValue, " ") + 1, (strlen(commandOutValue) - strpos(commandOutValue, " ")) - 1);
		command = substr(commandOutValue, 0, strpos(commandOutValue, " ")); 
		
//		DebugN("sylexOutput:  subSystemName: <<" +  subSystemName + ">>");
//		DebugN("sylexOutput:  command: <<" +  command + ">>");
		
		tag = XMLcreateTag("Command", makeDynString("Name"), makeDynString(command), "");	
		tag = XMLcreateTag("SubSystem", makeDynString("Name"), makeDynString(subSystemName), tag);	
		tag = XMLcreateTag("System", makeDynString("Name"), makeDynString("SYLEX" + gSylexId), tag);	
		tag = XMLcreateTag("ISupCommand", makeDynString("Version"), makeDynString("1.0"), tag);	
		//xml = XMLaddHeader(tag);
		xml = tag;
	}
	// Commut command
	else if (strpos(commandOutValue, "Commut") != -1 )
	{
		dpGet("SYLEX.SYLEX" + gSylexId + ".ServerStatus.Status", serverStatus);

		// DebugTN("sylexOutput:  user request chain switch");
		sgHistoryAddEvent("SYLEX.History", SEVERITY_COMMAND, "user request chain switch");
	
		tag = XMLcreateTag("Command", makeDynString("Name"), makeDynString("Commut"), "");	
		tag = XMLcreateTag("SubSystem", makeDynString("Name"), makeDynString("SYLEX"), tag);	
		tag = XMLcreateTag("System", makeDynString("Name"), makeDynString("SYLEX" + gSylexId), tag);	
		tag = XMLcreateTag("ISupCommand", makeDynString("Version"), makeDynString("1.0"), tag);	
		xml = tag;
		
	}
	else
	{
		xml = commandOutValue;
	}
	
	dpSet("SYLEX.SYLEX" + gSylexId + ".CommandOut", "");
		
}	// void sylexOutput(string commandOutDpName, string commandOutValue)


void updateSylexTimeOuts(int sylexId)
{
	string sylexDpName;	
	sylexDpName = "SYLEX.SYLEX" + sylexId + ".ServerStatus.PreStatus";
	
	bool isMessageReceived;
	isMessageReceived = sgGenericProcessorUpdateTimeout(SYLEX_PROCESSOR + sylexId, "SYLEX.References.SYLEX" + sylexId);
		
	if (isMessageReceived)
	{
		string status;
		dpGet(sylexDpName, status);
		
		if (isSBY(status))
		{
			// 04.01.2006 aj Commutation is only in GVA not in ZRH anymore
			if (dpExists("SYLEX.Commutation.PreStatus") && dpExists("SYLEX.References.Commutation"))
				dpSet("SYLEX.References.Commutation", true);
		}
		
		if(isOPS(status))
		{
			dpSet("SYLEX.LinesReference", true);
		}
	}
}
