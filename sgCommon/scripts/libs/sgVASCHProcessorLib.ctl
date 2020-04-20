//bool gContinueThread;
int gVaschId;

//string gISupServerSubName;

// Set all the Vasch points to UKN
void forceAllVaschToUKN()
{
	dyn_string names;
        dyn_string excludedNames;
	int cpt;

	names = dpNames("VASCH.VASCH1.*.PreStatus");
	dynAppend(names, dpNames("VASCH.VASCH2.*.PreStatus"));

        // to avoid alarm on ISup/Links if Refresh
        excludedNames = dpNames("VASCH.VASCH1.Interface*.PreStatus");
	dynAppend(excludedNames, dpNames("VASCH.VASCH2.Interface*.PreStatus"));

        for (int i = 1 ; i <= dynlen(excludedNames); i++)
        {
          int index = 0;
          index = dynContains(names, excludedNames[i]);
          if (index > 0)
              dynRemove(names, index);
        }
    //    DebugTN("forceAllVaschToUKN; names:" + names);


	dyn_string ds;

	for (int cpt = 1; cpt <= dynlen(names); cpt++)
	  dynAppend(ds, "UKN");

	//DebugTN("forceAllVaschToUKN");
	dpSetWait(names, ds);
}

// already defined in SYLEX & not used! PW March 2008
// void socketInterfaceChanged(string dpName, string dpValue)
// {
// 	if (!isOPS(dpValue) && !gContinueThread)
// 	{
// 		gContinueThread = false;
// 	}
// 	else
// 	{
// 	 if (!gContinueThread)
// 	 {
// 	 	threadId = startThread("vaschInterfaceThread", gVaschId);
// 	 }
// 	}
// }

void vaschSendCommand(string text)
{
	 // tell the socket manager to send the message (it can be from a button...)
	// DebugTN("VaschSendCommand >> will send to Vasch: " + text);
	dpSet("VASCH.VASCH" + gVaschId + ".CommandOut", text);
}

void vaschCommandOutChanged(string dpName, string commandOutValue)
{
	// DebugTN("VaschCommandOutChanged");

	if(commandOutValue == "")
		return;

	if((commandOutValue == "Refresh") || (commandOutValue == "Commut"))
	{
		forceAllVaschToUKN();
		sgXMLPrepareForceToUKN();

	}

	// DebugTN("VaschCommandOutChanged >> will send for processor id 1");
	sendVaschAnswer(commandOutValue, 1);

	// DebugTN("VaschCommandOutChanged >> will send for processor id 2");
	sendVaschAnswer(commandOutValue, 2);

	dpSet("VASCH.Commands.Out", "");
}

// DISABLED PW MARCH 2008
// void vaschOutput(string commandOutDpName, string commandOutValue)
// {
// 	int res;
// 	string xml;
// 	string tag;
// 	string subSystemName;
// 	string command;
// 	string serverStatus;
//
// 	if(commandOutValue == "")
// 		return;
	//DebugTN("VaschOutput starts for message " + commandOutValue);
//
	// Refresh command
// 	if(commandOutValue == "Refresh")
// 	{
// 		tag = XMLcreateTag("Command", makeDynString("Name"), makeDynString("Refresh"), "");
	//	tag = XMLcreateTag("SubSystem", makeDynString("Name"), makeDynString("VASCH"), tag);
// 		tag = XMLcreateTag("System", makeDynString("Name"), makeDynString("VASCH" + gVaschId), tag);
// 		tag = XMLcreateTag("ISupCommand", makeDynString("Version"), makeDynString("1.0"), tag);
		// xml = XMLaddHeader(tag);
// 		xml = tag;
		//set all statuses to UKN for refresh
// 		forceAllVaschToUKN();
		// delay(1);
// 	}
	// Commut command
// 	else if (strpos(commandOutValue, "Commut") != -1 )
// 	{
// 		dpGet("VASCH.VASCH" + gVaschId + ".ServerStatus.Status", serverStatus);
//
		// DebugTN("sylexOutput:  user request chain switch");
// 		sgHistoryAddEvent("VASCH.History", SEVERITY_COMMAND, "user request chain switch");
//
// 		tag = XMLcreateTag("Command", makeDynString("Name"), makeDynString("Commut"), "");
// 		tag = XMLcreateTag("SubSystem", makeDynString("Name"), makeDynString("VASCH"), tag);
// 		tag = XMLcreateTag("System", makeDynString("Name"), makeDynString("VASCH" + gVaschId), tag);
// 		tag = XMLcreateTag("ISupCommand", makeDynString("Version"), makeDynString("1.0"), tag);
		// xml = XMLaddHeader(tag);
// 		xml = tag;
// 	}
// 	else
// 	{
// 		xml = commandOutValue;
// 	}
//
// 	if (gContinueThread)
// 	{
		// DebugTN("sylexOutput >> Will send: " + xml);
// 		if(isServerA(getHostname()))
// 			dpSet("VASCH.VASCH" + gVaschId + ".SocketConnectionA.Payload.Out.Message", xml);
//
// 		if(isServerB(getHostname()))
// 			dpSet("VASCH.VASCH" + gVaschId + ".SocketConnectionB.Payload.Out.Message", xml);
// 	}
// 	dpSet("VASCH.VASCH" + gVaschId + ".CommandOut", "");
//
// }	// void vaschOutput(string commandOutDpName, string commandOutValue)

void sendVaschAnswer(string commandOutValue, int processorId)
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
		tag = XMLcreateTag("SubSystem", makeDynString("Name"), makeDynString("VASCH"), tag);
		tag = XMLcreateTag("System", makeDynString("Name"), makeDynString("VASCH" + processorId), tag);
		tag = XMLcreateTag("ISupCommand", makeDynString("Version"), makeDynString("1.0"), tag);
		xml = tag;
	}
	// Commut command
	else if (strpos(commandOutValue, "Commut") != -1 )
	{
		// DebugTN("sylexOutput:  user request chain switch");
		sgHistoryAddEvent("VASCH.SystemHistory", SEVERITY_COMMAND, "user request chain switch");

		tag = XMLcreateTag("Command", makeDynString("Name"), makeDynString("Commut"), "");
		tag = XMLcreateTag("SubSystem", makeDynString("Name"), makeDynString("VASCH"), tag);
		tag = XMLcreateTag("System", makeDynString("Name"), makeDynString("VASCH" + processorId), tag);
		tag = XMLcreateTag("ISupCommand", makeDynString("Version"), makeDynString("1.0"), tag);
		// xml = XMLaddHeader(tag);
		xml = tag;
	}
	else
	{
		xml = commandOutValue;
	}
	sgProcessorsSendMessage(VASCH_PROCESSOR + processorId, xml);
}

void updateVaschTimeOuts(int vaschId)
{
	string vaschDpName;
	vaschDpName = "VASCH.VASCH" + vaschId + ".ServerStatus.PreStatus";

	bool isMessageReceived;
	isMessageReceived = sgGenericProcessorUpdateTimeout(VASCH_PROCESSOR + vaschId, "VASCH.References.VASCH" + vaschId);

// 	if (isMessageReceived)
// 	{
// 		string status;
// 		dpGet(vaschDpName, status);
//
// 		if (isSBY(status))
// 		{
			// 04.01.2006 aj Commutation is only in GVA not in ZRH anymore
// 			if (dpExists("VASCH.Commutation.PreStatus") && dpExists("VASCH.References.Commutation"))
// 				dpSet("VASCH.References.Commutation", true);
// 		}
//
// 		if(isOPS(status))
// 		{
// 			dpSet("VASCH.Lines.LinesReference", true);
// 		}
// 	}
}
