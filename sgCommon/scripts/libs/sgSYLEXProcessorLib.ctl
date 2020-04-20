bool gContinueThread;
int gSylexId;

string gISupServerSubName;

// Set all the Sylex points to UKN
void forceAllSylexToUKN()
{
	dyn_string names;
	int cpt;
	
	names = dpNames("SYLEX.Lines.*.PreStatus");
	
	dynAppend(names, dpNames("SYLEX.SYLEX*.ServerStatus.PreStatus"));
	
	// 04.01.2006 aj 
	//Commutation doesn't exist in Zürich anymore but still in Geneva
	if (dpExists("SYLEX.Commutation.PreStatus"))
		dynAppend(names, "SYLEX.Commutation.PreStatus");		
	
	dyn_string ds;
	
	for (int cpt = 1; cpt <= dynlen(names); cpt++)
	dynAppend(ds, "UKN");
		
//	for(cpt = 1; cpt <= dynlen(names); cpt++)
//	{
//		dpSet(names[cpt], "UKN");
//	}
	//DebugTN("forceAllSylexToUKN");
	dpSetWait(names, ds);
	// dpSet("SYLEX.Commutation.PreStatus", "UKN");
}



/* 04.01.2006 aj function apparently not used anymore
                 same function with one parameter defined in the sylex-script
// Refresh watchDogs reference points 
void updateSylexTimeOuts()
{
	string sylexDpName;
	string status;
	
	sylexDpName = "SYLEX.SYLEX" + gSylexId + ".ServerStatus.PreStatus";

	dpGet(sylexDpName, status);
	// DebugTN("updateSylexTimeOuts >> will update timeout for SYLEX: " + sylexId);
	dpSet(sylexDpName, status);
	
	if (isSBY(status))
	{
		string commutStatus;
		dpGet("SYLEX.Commutation.PreStatus", commutStatus);
		dpSet("SYLEX.Commutation.PreStatus", commutStatus);
	}
	
	if(isOPS(status))
	{
//		DebugN("updateSylexTimeOut: Lines link is alive");
		dpSet("SYLEX.LinesReference", "Alive");
	}
}
*/

void socketInterfaceChanged(string dpName, string dpValue)
{
	if (!isOPS(dpValue) && !gContinueThread)
	{
		gContinueThread = false;
	}
	else
	{
	 if (!gContinueThread)
	 {
	 	threadId = startThread("sylexInterfaceThread", gSylexId);
	 }
	}	
}

void sylexSendCommand(string text)
{
	 // tell the socket manager to send the message (it can be from a button...)
	// DebugTN("sylexSendCommand >> will send to SYLEX: " + text);
	dpSet("SYLEX.SYLEX" + gSylexId + ".CommandOut", text);
}

//void SYLEXInputChanged(string dpName, string xmlReceived)
//{
	// DebugTN("SYLEXInputChanged >> xml received (from SYLEX: " + dpName + " ): " + xmlReceived);
//	sgHistoryAddEvent("SYLEX.SystemHistory", SEVERITY_SYSTEM, "Receive from: " + dpName  + ": " + xmlReceived);
//	parseSylexMessageReceived(xmlReceived);	
//		
	// set interface status to ops
//	if(gContinueThread)
//		setSylexInterfaceStatus(OPS_STATUS);
//} // void SYLEXInputChanged(string dpName, string xmlReceived)

void sylexCommandOutChanged(string dpName, string commandOutValue)
{
	// DebugTN("sylexCommandOutChanged");
	
	if(commandOutValue == "")
		return;
	
	if((commandOutValue == "Refresh") || (commandOutValue == "Commut"))
	{
		forceAllSylexToUKN();
		sgXMLPrepareForceToUKN();
		
	}
	
	// DebugTN("sylexCommandOutChanged >> will send for processor id 1");
	sendSylexAnswer(commandOutValue, 1);
	
	// DebugTN("sylexCommandOutChanged >> will send for processor id 2");
	sendSylexAnswer(commandOutValue, 2);

	// DebugTN("sylexCommandOutChanged >> will send for processor id 2");
	sendSylexAnswer(commandOutValue, 3);

	
	dpSet("SYLEX.Commands.Out", "");
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
		
		
	//DebugTN("sylexOutput starts for message " + commandOutValue);
	
	// Refresh command
	if(commandOutValue == "Refresh")
	{
		tag = XMLcreateTag("Command", makeDynString("Name"), makeDynString("Refresh"), "");	
		tag = XMLcreateTag("SubSystem", makeDynString("Name"), makeDynString("SYLEX"), tag);	
		tag = XMLcreateTag("System", makeDynString("Name"), makeDynString("SYLEX" + gSylexId), tag);	
		tag = XMLcreateTag("ISupCommand", makeDynString("Version"), makeDynString("1.0"), tag);	
		// xml = XMLaddHeader(tag);
		xml = tag;
		//set all statuses to UKN for refresh
		forceAllSylexToUKN();
		// delay(1);
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
		// xml = XMLaddHeader(tag);
		xml = tag;
		
	}
	else
	{
		xml = commandOutValue;
	}
	
	if (gContinueThread)
	{
		// DebugTN("sylexOutput >> Will send: " + xml);
		if(isServerA(getHostname()))
			dpSet("SYLEX.SYLEX" + gSylexId + ".SocketConnectionA.Payload.Out.Message", xml);
			
		if(isServerB(getHostname()))
			dpSet("SYLEX.SYLEX" + gSylexId + ".SocketConnectionB.Payload.Out.Message", xml);
	}
	dpSet("SYLEX.SYLEX" + gSylexId + ".CommandOut", "");
		
}	// void sylexOutput(string commandOutDpName, string commandOutValue)

void sendSylexAnswer(string commandOutValue, int processorId)
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
		tag = XMLcreateTag("System", makeDynString("Name"), makeDynString("SYLEX" + processorId), tag);	
		tag = XMLcreateTag("ISupCommand", makeDynString("Version"), makeDynString("1.0"), tag);	
		xml = tag;
	}
	// Connect or Disconnect command
	else if((strpos(commandOutValue, "Connect") != -1 ) || (strpos(commandOutValue, "Disconnect") != -1 ))
	{
		// Get system name
		subSystemName = substr(commandOutValue, strpos(commandOutValue, " ") + 1, (strlen(commandOutValue) - strpos(commandOutValue, " ")) - 1);
		command = substr(commandOutValue, 0, strpos(commandOutValue, " ")); 
		
		tag = XMLcreateTag("Command", makeDynString("Name"), makeDynString(command), "");	
		tag = XMLcreateTag("SubSystem", makeDynString("Name"), makeDynString(subSystemName), tag);	
		tag = XMLcreateTag("System", makeDynString("Name"), makeDynString("SYLEX" + processorId), tag);	
		tag = XMLcreateTag("ISupCommand", makeDynString("Version"), makeDynString("1.0"), tag);	
		//xml = XMLaddHeader(tag);
		xml = tag;
	}
	// Commut command
	else if (strpos(commandOutValue, "Commut") != -1 )
	{
		// DebugTN("sylexOutput:  user request chain switch");
		sgHistoryAddEvent("SYLEX.History", SEVERITY_COMMAND, "user request chain switch");
	
		tag = XMLcreateTag("Command", makeDynString("Name"), makeDynString("Commut"), "");	
		tag = XMLcreateTag("SubSystem", makeDynString("Name"), makeDynString("SYLEX"), tag);	
		tag = XMLcreateTag("System", makeDynString("Name"), makeDynString("SYLEX" + processorId), tag);	
		tag = XMLcreateTag("ISupCommand", makeDynString("Version"), makeDynString("1.0"), tag);	
		// xml = XMLaddHeader(tag);
		xml = tag;
		
	}
	else
	{
		xml = commandOutValue;
	}	
	sgProcessorsSendMessage(SYLEX_PROCESSOR + processorId, xml);
}
