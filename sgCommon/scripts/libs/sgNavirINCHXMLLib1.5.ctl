// MODIFICATIONS:
// 1.0 Creation (PW)
// 1.1 (PW) Modification to have the system name in XML Config file to permit
// 1.2 (PW) LLZ-LOC Modifications 
// 1.3 (PW) LLZDME LOC last Modifications 
// 1.4 (PW) Added GLS Approach possibility

const int queryTimeOut = 200; // ms dpQuery timeout

int XMLINCHPort;  // port will be defined at start with file : D:\XMLINCHNavirConfig\XMLINCHNavirConfig.txt
string XMLINCHA; // will be defined at start with file : D:\XMLINCHNavirConfig\XMLINCHNavirConfig.txt
string XMLINCHB; // will be defined at start with file : D:\XMLINCHNavirConfig\XMLINCHNavirConfig.txt
int tcpIdINCHA = -1; // Tcp connection identifier to INCH A
int tcpIdINCHB = -1; // Tcp connection identifier to INCH B
string lastActiveChainINCHA; // to compare at Navir switchover to send to INCH A
string lastActiveChainINCHB; // to compare at Navir switchover to send to INCH B
bool INCHAXMLLibIsActiveChain; //true if is active chain to send to INCH A
bool INCHBXMLLibIsActiveChain; //true if is active chain to send to INCH B
bool connectionINCHAExecuted;  // to wait after the connection before sending the heartbeat
bool connectionINCHBExecuted; // to wait after the connection before sending the heartbeat
dyn_string ILSNavirNames; // ILS CAT names in Navir -> convert to INCH OPS Names
dyn_string ILSINCHNames; // ILS CAT names in Navir -> convert to INCH OPS Names
dyn_string INCHXMLSystems; // Navir XMLsystems 
dyn_string lastStatusesINCHA; // Memo of the last call
dyn_string lastDpINCHA;// Memo of the last call
dyn_string lastStatusesINCHB;// Memo of the last call
dyn_string lastDpINCHB;// Memo of the last call


// start the work function on active chain to connect/disconnect the INCH XML connection
void startINCHXML(string INCHChain)
{
	getILSNamesConversionTable();
	
	getINCHXMLConfig(INCHChain);  // INCH names and ports

	if(INCHChain == "A" && XMLINCHA != "") // connected only if available config file
	{
		// init memo
		lastStatusesINCHA =	makeDynString();
		lastDpINCHA =	makeDynString();

		lastActiveChainINCHA = "";  // to force the connection if chain doesn't changed
		
		dpConnect("connectDisconnectINCHAXML", ACTIVE_CHAIN);
//		dpConnect("connectDisconnectINCHAXML", ACTIVE_CHAIN, "_DistConnections.Dist.ManNums", "_DistConnections_2.Dist.ManNums");
	}
	if(INCHChain == "B" && XMLINCHB != "") // connected only if available config file
	{
		// init memo
		lastStatusesINCHB =	makeDynString();
		lastDpINCHB =	makeDynString();
		
		lastActiveChainINCHB = "";  // to force the connection if chain doesn't changed

		dpConnect("connectDisconnectINCHBXML", ACTIVE_CHAIN);
	}
}// startINCHXML

// disconnect the relative INCH XML connection
void disconnectINCHXML(string INCHChain)
{
	if(INCHChain == "A") 
	{
		lastActiveChainINCHA = "";
		dpDisconnect("connectDisconnectINCHAXML", ACTIVE_CHAIN);
//		DebugTN("disconnectINCHXML; connectDisconnectINCHAXML dpDisconnected");
	
		for(int i = 1; i <= dynlen(INCHXMLSystems);i++)
			{
				// if not active anymore, -> disconnect to avoid multiple connections
				int ret;
				ret = dpQueryDisconnect("composeAndSendINCHAXML", INCHXMLSystems[i]); 
				DebugTN("sgNavirINCHXMLLib; disconnectINCHXML; for INCH A dpQueryDisconnect ret: " + ret);	
				
				if(ret > -1) // if a second Query connect is started
				{
					int ret2 = dpQueryDisconnect("composeAndSendINCHAXML", INCHXMLSystems[i]); 
					DebugTN("sgNavirINCHXMLLib; disconnectINCHXML; for INCH A dpQueryDisconnect ret2: " + ret2);	
				}
			}
	

	}
	if(INCHChain == "B") 
	{
		lastActiveChainINCHB = "";
		dpDisconnect("connectDisconnectINCHBXML", ACTIVE_CHAIN);
//		DebugTN("disconnectINCHXML; connectDisconnectINCHBXML dpDisconnected");

		for(int i = 1; i <= dynlen(INCHXMLSystems);i++)
			{
				// if not active anymore, -> disconnect to avoid multiple connections
				int ret;
				ret = dpQueryDisconnect("composeAndSendINCHBXML", INCHXMLSystems[i]); 
				//DebugTN("sgNavirINCHXMLLib; disconnectINCHXML; for INCH B dpQueryDisconnect ret: " + ret);	

				if(ret > -1) // if a second Query connect is started
				{
					int ret2 = dpQueryDisconnect("composeAndSendINCHBXML", INCHXMLSystems[i]); 
				//	DebugTN("sgNavirINCHXMLLib; disconnectINCHXML; for INCH B dpQueryDisconnect ret2: " + ret2);	
				}
	
			}


	}
}// disconnectINCHXML

// get the conversion table for ILSCAT names (from Navir Names to INCH names
void getILSNamesConversionTable()
{
	dyn_string remoteILSNavirNames;
	dyn_string remoteILSINCHNames;

	dpGet("NavirUtils.XMLINCH.ILSNamesTable.NavirNames", ILSNavirNames, 
				"NavirUtils.XMLINCH.ILSNamesTable.INCHNames", ILSINCHNames,
				"NavirUtils.XMLINCH.XMLSystems", INCHXMLSystems);

	if(dynlen(INCHXMLSystems) > 0)
	{
		for(int i=1; i<=dynlen(INCHXMLSystems) ; i++)
		{
			dpGet(INCHXMLSystems[i] + ":NavirUtils.XMLINCH.ILSNamesTable.NavirNames", remoteILSNavirNames, 
						INCHXMLSystems[i] + ":NavirUtils.XMLINCH.ILSNamesTable.INCHNames", remoteILSINCHNames);
			dynAppend(ILSNavirNames, remoteILSNavirNames);
			dynAppend(ILSINCHNames, remoteILSINCHNames);
		}
	}
}// getILSNamesConversionTable

// get the INCH machine Names and the port for XML connection
void getINCHXMLConfig(string INCHChain)
{
	file f;
	int fOK;
	string fileName;
	string contentString;	
	dyn_string contentDynString;
        string systemName;
        
        // PW 2009-JAN-21 added the system name in XMLConfig file to permit several system on the same machine (VALID)
        systemName = getSystemName();
        strreplace(systemName, ":", "; "); // to have only one ":" in the line
               
	fileName = "D:/XMLINCHNavirConfig/XMLINCHNavirConfig.txt";
	
	fOK = access(fileName,F_OK); // Does the file already exist ?
 
	if (fOK != 0)
	{
		DebugTN("XML INCH Navir config file: " + fileName + " doesn't exist!!! No XML available!!"); 
		XMLINCHPort = 0;
		XMLINCHA = "";
		XMLINCHB = "";
		exit; // exit the function
	}

	fileToString(fileName, contentString);  // get content of config file
	contentDynString = strsplit(contentString, "\n");

// process dyn_string to have the config values
	for(int j = 1; j <= dynlen(contentDynString); j++)
	{
          	//DebugTN("sgNavirINCHXMLLib; contentDynString[j]:" + contentDynString[j]);
		if(strpos(contentDynString[j], systemName + "INCH_A:") >= 0)
			XMLINCHA = substr(contentDynString[j], strpos(contentDynString[j], ":") + 1);

		if(strpos(contentDynString[j], systemName + "INCH_B:") >= 0)
			XMLINCHB = substr(contentDynString[j], strpos(contentDynString[j], ":") + 1);

		if(strpos(contentDynString[j], systemName + "port:") >= 0)
			XMLINCHPort = substr(contentDynString[j], strpos(contentDynString[j], ":") + 1);
	}
	//DebugTN("sgNavirINCHXMLLib; getINCHXMLConfig; name INCH_A:" + XMLINCHA + " for INCHChain:" + INCHChain);
 	//DebugTN("sgNavirINCHXMLLib; getINCHXMLConfig; name INCH_B:" + XMLINCHB + " for INCHChain:" + INCHChain);
 	//DebugTN("sgNavirINCHXMLLib; getINCHXMLConfig; port:" + XMLINCHPort + " for INCHChain:" + INCHChain);
}//getINCHXMLConfig()


// set the sgFw block with the INCH XML connection status
void setINCHConnectionStatus(string NavirChain, string INCHChain, string status)
{								
	dpSet("NavSup.Server" + NavirChain + ".Components.INCH" + INCHChain + "Connection" + PRE_STATUS_POSTFIX, status);
}//setINCHConnectionStatus

// Return the INCH Navaids datapoints
string getINCHNavaidsDps(string INCHXMLSystem)
{
	dyn_dyn_anytype interestingNavaids;
	string s;
	string INCHNavaidsDps;
	
	// compose Navaids Query
	s = "SELECT '_online.._value' FROM '*.Structured.Navaid_*.Type' REMOTE '" + INCHXMLSystem + "' WHERE '_online.._value' == \"VOR\" ";
	s = s + "OR '_online.._value' == \"DVOR\" OR  '_online.._value' == \"DME\" OR '_online.._value' == \"GP\" ";
	s = s + "OR  '_online.._value' == \"LOC\" OR '_online.._value' == \"NDB\" ";
        
	dpQuery(s, interestingNavaids);
	
	for (int i = 2; i <= dynlen(interestingNavaids); i++)  // 2 <- first position is the header
	{
		string dp;
		dp = interestingNavaids[i][1];
		strreplace(dp, ".Type", ".OperationalStatus" + PRE_STATUS_POSTFIX);
		
		if (INCHNavaidsDps == "")
			INCHNavaidsDps = dp;
		else 
			INCHNavaidsDps = INCHNavaidsDps + "," + dp;
	}
	return INCHNavaidsDps;
}  // getINCHNavaidsDps()

// Return the INCH ILS datapoints
string getINCHILSCATDps(string INCHXMLSystem)
{
	string INCHILSCATDps;
	dyn_string ILSNames;	
	ILSNames = dpNames(INCHXMLSystem + ":*", "sgNavirILS");
	//	DebugTN("INCHILSCATDps: " +INCHILSCATDps);	
	// Remove standard dummy ILS dp		
	dynRemove(ILSNames, dynContains(ILSNames, INCHXMLSystem + ":ILSDummyForHMICAT"));
		
	for (int i = 1; i <= dynlen(ILSNames); i++)  
	{
		INCHILSCATDps = INCHILSCATDps + "," + ILSNames[i] + ".HMIStatuses.CATIIIStatus" + PRE_STATUS_POSTFIX;
		INCHILSCATDps = INCHILSCATDps + "," + ILSNames[i] + ".HMIStatuses.CATIIStatus" + PRE_STATUS_POSTFIX;
		INCHILSCATDps = INCHILSCATDps + "," + ILSNames[i] + ".HMIStatuses.CATIStatus" + PRE_STATUS_POSTFIX;
       		INCHILSCATDps = INCHILSCATDps + "," + ILSNames[i] + ".HMIStatuses.LOCDMEStatus" + PRE_STATUS_POSTFIX;
	}
	return INCHILSCATDps;
} // getINCHILSCATDps()

// Return the INCH GLS datapoints
string getINCHGLSApproachDps(string INCHXMLSystem)
{
	string INCHGLSApproachDps;
	dyn_string GLSNames;	
	GLSNames = dpNames(INCHXMLSystem + ":*", "sgGBASGLS");

		
	for (int i = 1; i <= dynlen(GLSNames); i++)  
	{
  if (i==1)
    INCHGLSApproachDps = GLSNames[i] + ".OperationalStatus" + PRE_STATUS_POSTFIX;
  else
    INCHGLSApproachDps = INCHGLSApproachDps + "," + GLSNames[i] + ".OperationalStatus" + PRE_STATUS_POSTFIX;
	}
	// get SAT Status (only one per System) PW 9.2015 SAT Constellation Alert
  string SATStatusDps = INCHXMLSystem + ":SAT.OperationalStatus" + PRE_STATUS_POSTFIX;
  INCHGLSApproachDps = INCHGLSApproachDps + "," + SATStatusDps;  
    
  DebugTN("getINCHGLSApproachDps; INCHGLSApproachDps: " + INCHGLSApproachDps);	
  
  	return INCHGLSApproachDps;
} // INCHGLSApproachDps()


// Return all INCH XML datapoints
dyn_dyn_string getAllINCHXMLDps(string sysname)
{
  dyn_dyn_anytype INCHDpsAndStatuses;
  dyn_string dps;
  string allDps;
  allDps = getINCHILSCATDps(sysname);
  allDps = allDps + "," + getINCHGLSApproachDps(sysname);
	
	dps = strsplit(allDps, ",");
	dynRemove(dps, 1);
	
	dynAppend(dps, dpNames(sysname + ":*.Structured.Navaid_*.OperationalStatus", "sgNavirStation"));

//PW March 2007 special case for Les Eplatures. Must be removed when Les Eplatures install through Network OPS!	
	dynAppend(dps, dpNames(sysname + ":*.Structured.Navaid_*.OperationalStatus", "sgSpecialNavirStation"));
	
	for (int i = 1; i <= dynlen(dps); i++)
	{
		INCHDpsAndStatuses[i+1][1] = dps[i];
		INCHDpsAndStatuses[i+1][2] = U_S_STATUS;		
	}
//	DebugTN("getAllINCHXMLDps: INCHDpsAndStatuses in test:" + INCHDpsAndStatuses);
	return INCHDpsAndStatuses;
}	// getAllINCHXMLDps

// Compose and send to INCH A the XML message
void composeAndSendINCHAXML(string sysname, dyn_dyn_anytype INCHDpsAndStatuses)
{
	composeAndSendINCHXML(sysname, INCHDpsAndStatuses, "A");
}// composeAndSendINCHAXML

// Compose and send to INCH B the XML message
void composeAndSendINCHBXML(string sysname, dyn_dyn_anytype INCHDpsAndStatuses)
{
	composeAndSendINCHXML(sysname, INCHDpsAndStatuses, "B");
}// composeAndSendINCHBXML
	
// Compose and send the INCH XML message
void composeAndSendINCHXML(string sysname, dyn_dyn_anytype INCHDpsAndStatuses, string INCHChain)
{
	string XMLMessage;
	
	// if distributed system gets disconnected work funktion is called without any data
	// as "_online.._invalid" doesn't work for dpQueryConnectSingle use this work funktion call without data
	// to set all navaids to UKN
	// if FrameWork doesn't correctly work, this work function is separately called
	int dynlength;
	dynlength = dynlen(INCHDpsAndStatuses);
	
	// case distributed system unconnection
	if (dynlength <= 0) 
		INCHDpsAndStatuses = getAllINCHXMLDps(sysname);
	else
	// case framework isn't ok 
		if(strpos((string)INCHDpsAndStatuses[dynlength][1], ACTIVE_FW_OK) >= 0)
		{
			if((int)(INCHDpsAndStatuses[dynlength][2]) == 0)
				return;
			else
				INCHDpsAndStatuses = getAllINCHXMLDps(sysname);
		}	
				
	for (int i = 2; i <= dynlen(INCHDpsAndStatuses); i++)  // first position is the header
	{
		string dp;
		// dps are in the first column
		dp = INCHDpsAndStatuses[i][1];

		string status;
		// statuses in the second column
		status = INCHDpsAndStatuses[i][2];
		
		string alarmMessage;
		
    if(strpos(dp, "SAT.OperationalStatus") >= 0) // Case SAT status //PW 9.2015
    {
      string labelDp = dp;
      strreplace(labelDp, PRE_STATUS_POSTFIX, LABEL1_POSTFIX);  // Label 1 contains HH:MM
      string label1;
      dpGet(labelDp, label1); 
//      DebugTN("label1:" + label1);
      alarmMessage = getAlarmMessage(INCHDpsAndStatuses[i][1], INCHDpsAndStatuses[i][2], INCHChain);
      if (alarmMessage == "ALARM")
        alarmMessage = alarmMessage + "," + label1;   // add time if U/S or DEG
      
//      DebugTN("alarmMessage:" + alarmMessage);
    }
    else    
    		alarmMessage = getAlarmMessage(INCHDpsAndStatuses[i][1], INCHDpsAndStatuses[i][2], INCHChain);
		
		strreplace(dp, PRE_STATUS_POSTFIX, "");  // to have root dp

		string description;
		description =	dpGetDescription(dp, -2);  // mode -2 to have an empty description if not defined
		
		// if ILS CAT status
		if( (strpos(description, "CAT") >= 0 )||(strpos(description, "LOC/DME") >= 0 ) )
		{
			description = dpSubStr(dp, DPSUB_DP) + " " + description;
						
			// CONVERSION TO INCH DEFINED NAMES THROUGH TABLE
			description = ILSINCHNames[dynContains(ILSNavirNames, description)];
		}
		// dpnames (for setting all navaids to UKN if system gets disconnected)
		// returns all navaids, also the ones which are not used -> remove them
		if ( (description == "NOT USED") || (description == "") )
			continue;
		
		// labels currently not used, send empty label
//		string label = "";
		
		// compose subsystem XML frames
		XMLMessage += XMLcreateTag("SubSystem", makeDynString("Name", "Status"), makeDynString(description, status), // status
								//	XMLcreateTag("Label", "Name", "Label1", label)  + // label
									"<Message>" + alarmMessage + "</Message>"  // alarm message
									);
	}	// End for

	// Add XML header and system
	XMLMessage = XMLaddHeader(XMLcreateTag("NavirStatus", "Version", "1.0",
								XMLcreateTag("System", makeDynString("Name", "Source"), makeDynString("Navir", ""), XMLMessage)  
							)) + "|";

//		DebugTN("INCHXMLLib; composeAndSendINCHXML; XMLMessage: " + XMLMessage);
	
//	 logging of XML message
	string s;
        s = XMLMessage;
	strreplace(s, "II", "ll");  // sgFw history doesn't support "II"
      	strreplace(s, "|", "#");  // sgFw history doesn't support "|"
        sgHistoryAddEvent("NavirUtils.XMLINCH.XMLHistory", SEVERITY_SYSTEM, s);								

//	 Send the XML message
	bool ok;
	ok = writeTCPXMLmessage(INCHChain, XMLMessage, true);
	
	if(ok)
	{}
	//	DebugTN("INCHXMLLib; composeAndSendINCHXML; XMLMessage: " + XMLMessage);
	else
		DebugTN("INCHXMLLib; composeAndSendINCHXML; Following XML message not sent! " + XMLMessage);
}

// return true if condition are ok to send an alarm
bool isAlarmCondition(string lastStatus, string status)
{
	bool alarmCondition;
	
	if( (lastStatus == OPS_STATUS) && (status == U_S_STATUS) || 
			(lastStatus == OPS_STATUS) && (status == WIP_STATUS) || 
			(lastStatus == OPS_STATUS) && (status == UKN_STATUS) || 
			(lastStatus == OPS_STATUS) && (status == DEG_STATUS) ||

 			(lastStatus == INI_STATUS) && (status == U_S_STATUS) || 
			(lastStatus == INI_STATUS) && (status == WIP_STATUS) || 
			(lastStatus == INI_STATUS) && (status == UKN_STATUS) || 
			(lastStatus == INI_STATUS) && (status == DEG_STATUS) ||

			(lastStatus == UKN_STATUS) && (status == UKN_STATUS) || 
	
			(lastStatus == WIP_STATUS) && (status == UKN_STATUS) || 
			(lastStatus == WIP_STATUS) && (status == DEG_STATUS) || 
			(lastStatus == WIP_STATUS) && (status == WIP_STATUS) || 
			(lastStatus == WIP_STATUS) && (status == U_S_STATUS) || 

			(lastStatus == U_S_STATUS) && (status == U_S_STATUS) || 

			(lastStatus == DEG_STATUS) && (status == UKN_STATUS) ||
			(lastStatus == DEG_STATUS) && (status == WIP_STATUS) ||
			(lastStatus == DEG_STATUS) && (status == U_S_STATUS) )
		alarmCondition = true;
	else
		alarmCondition = false;

	return alarmCondition;
}// is Alarm condition

// return the value of the alarm message
string getAlarmMessage(string dp, string status, string INCHChain)
{
	int index;
	string lastStatus;
	string alarmMessage;
//		DebugTN("INCHXMLLib; getAlarmMessage;1 alarmConditions:" + alarmConditions);
//		DebugTN("INCHXMLLib; getAlarmMessage;1 lastStatusesINCHA:" + lastStatusesINCHA);
//		DebugTN("INCHXMLLib; getAlarmMessage;1 dp:" + dp);
//		DebugTN("INCHXMLLib; getAlarmMessage;1 status:" + status);
				
	if (INCHChain == "A") 
	{
		index = dynContains (lastDpINCHA, dp);
		if (index > 0) // contain dp
		{
			lastStatus = lastStatusesINCHA[index]; // get last status
			
		if(isAlarmCondition(lastStatus, status))
				alarmMessage = "ALARM"; 
			else
				alarmMessage = "NO ALARM"; 
		//update last status
			lastStatusesINCHA[index] = status;
		}
		else // doesn't contain dp
		{
//			update table with current status
			dynAppend(lastDpINCHA, dp);
			dynAppend(lastStatusesINCHA, status);

			if( (status == OPS_STATUS) ||	(status == SBY_STATUS) )
				alarmMessage = "NO ALARM"; 
			else
				alarmMessage = "ALARM"; 
		}
	}	// was INCH Chain A
		
	if (INCHChain == "B") 
	{
		index = dynContains (lastDpINCHB, dp);
		if (index > 0) // contain dp
		{
			lastStatus = lastStatusesINCHB[index]; // get last status
			
		if(isAlarmCondition(lastStatus, status))
				alarmMessage = "ALARM"; 
			else
				alarmMessage = "NO ALARM"; 
		//update last status
			lastStatusesINCHB[index] = status;
		}
		else // doesn't contain dp
		{
//			update table with current status
			dynAppend(lastDpINCHB, dp);
			dynAppend(lastStatusesINCHB, status);

			if( (status == OPS_STATUS) ||	(status == SBY_STATUS) )
				alarmMessage = "NO ALARM"; 
			else
				alarmMessage = "ALARM"; 
		}
	}	// was INCH Chain B
	
	return alarmMessage;
} //getAlarmMessage

// connect or disconnect the XML TCP connection if chain is active or not to INCH A
void connectDisconnectINCHAXML(string activeChainDp, string activeChain) //, string connDp, dyn_string manNums, string connDp_2, dyn_string manNums_2)
{
  string INCHNavaidsDps;
  string INCHILSCATDps;
  string INCHGLSApproachDps;

	if(dynlen(INCHXMLSystems) < 1 ) // no systems or error -> exit
		exit;

	if( (lastActiveChainINCHA != activeChain) ) // chain changed
	{
		lastActiveChainINCHA = activeChain;
		
		if(isActiveChain()) // if switchover and active -> connections
		{
			INCHAXMLLibIsActiveChain = true;
		
			tcpIdINCHA = tcpOpen(XMLINCHA, XMLINCHPort);
			DebugTN("sgNavirINCHXMLLib; connectDisconnectINCHAXML; 1st tcpIdINCHA: " + tcpIdINCHA);
			
			if(tcpIdINCHA < 0) //if tcpopen failed try a second time before restarting all the connection processus
			{
				delay (0,200);
				tcpIdINCHA = tcpOpen(XMLINCHA, XMLINCHPort);
				//DebugTN("sgNavirINCHXMLLib; connectDisconnectINCHAXML; 2nd tcpIdINCHA: " + tcpIdINCHA);
			}
			if(tcpIdINCHA > -1)// QueryConnect only if TCP connection ok
			{
			  //DebugTN("sgNavirINCHXMLLib; INCHXMLSystems; " + INCHXMLSystems);        
        
				for(int i = 1; i <= dynlen(INCHXMLSystems);i++)
				{
        INCHNavaidsDps = getINCHNavaidsDps(INCHXMLSystems[i]);
        INCHILSCATDps = getINCHILSCATDps(INCHXMLSystems[i]);
        INCHGLSApproachDps = getINCHGLSApproachDps(INCHXMLSystems[i]);
							
        //DebugTN("sgNavirINCHXMLLib; INCHGLSApproachDps; " + INCHGLSApproachDps);        
        
					// pass systemname as identifier for setting navaids to UKN when getting disconnected
					dpQueryConnectSingle("composeAndSendINCHAXML", true, INCHXMLSystems[i], 
																"SELECT '_online.._value' FROM '{" + INCHNavaidsDps + INCHILSCATDps + INCHGLSApproachDps + "}' REMOTE '" + INCHXMLSystems[i] + "'",
																queryTimeOut);
			
					// To check the respective framework
					string fwOkDp;
					fwOkDp = INCHXMLSystems[i] + ":" + ACTIVE_FW_OK;
					dpQueryConnectSingle("composeAndSendINCHAXML", true, INCHXMLSystems[i], 
																"SELECT '_alert_hdl.._act_prior' FROM '{" + fwOkDp + "}' REMOTE '" + INCHXMLSystems[i] + "'", 
																queryTimeOut);
				}
			}
			connectionINCHAExecuted = true;
		}
		else  // not active anymore -> close connections
		{
			for(int i = 1; i <= dynlen(INCHXMLSystems);i++)
			{
				// if not active anymore, -> disconnect to avoid multiple connections
				int ret;
				ret = dpQueryDisconnect("composeAndSendINCHAXML", INCHXMLSystems[i]); 
				//DebugTN("sgNavirINCHXMLLib; connectDisconnectINCHAXML; dpQueryDisconnect ret: " + ret);	
			}
			
			//DebugTN("sgNavirINCHXMLLib; connectDisconnectINCHAXML; Close tcp connection A!");
			tcpClose(tcpIdINCHA);
			tcpIdINCHA = -1;
			
			INCHAXMLLibIsActiveChain = false;
			connectionINCHAExecuted = false;
		}// if chain active inactive
	}// if chain changed	
//	lastActiveChainINCHA = activeChain;
}

// connect or disconnect the XML TCP connection if chain is active or not to INCH B
void connectDisconnectINCHBXML(string activeChainDp, string activeChain)
{
  string INCHNavaidsDps;
  string INCHILSCATDps;
  string INCHGLSApproachDps;

	if(dynlen(INCHXMLSystems) < 1 ) // no systems or error -> exit
		exit;

	if( (lastActiveChainINCHB != activeChain) ) // if active chain changed
	{
		if(isActiveChain()) // if switchover and active -> connections
		{
			INCHBXMLLibIsActiveChain = true;
		
			tcpIdINCHB = tcpOpen(XMLINCHB, XMLINCHPort);
			//DebugTN("sgNavirINCHXMLLib; connectDisconnectINCHBXML; 1st tcpIdINCHB: " + tcpIdINCHB);

			if(tcpIdINCHB < 0) // if tcpopen failed try a second time before restarting all the connection processus
			{
				delay (0,500);
				tcpIdINCHB = tcpOpen(XMLINCHB, XMLINCHPort);
				//DebugTN("sgNavirINCHXMLLib; connectDisconnectINCHBXML; 2nd tcpIdINCHB: " + tcpIdINCHB);
			}
			
			if(tcpIdINCHB > -1)// QueryConnect only if TCP connection ok
			{
				for(int i = 1; i <= dynlen(INCHXMLSystems);i++)
				{
        INCHNavaidsDps = getINCHNavaidsDps(INCHXMLSystems[i]);
        INCHILSCATDps = getINCHILSCATDps(INCHXMLSystems[i]);
        INCHGLSApproachDps = getINCHGLSApproachDps(INCHXMLSystems[i]);

							
					// pass systemname as identifier for setting navaids to UKN when getting disconnected
					dpQueryConnectSingle("composeAndSendINCHBXML", true, INCHXMLSystems[i], 
																"SELECT '_online.._value' FROM '{" + INCHNavaidsDps + INCHILSCATDps + INCHGLSApproachDps + "}' REMOTE '" + INCHXMLSystems[i] + "'",
																queryTimeOut);
			
					// To check the respective framework
					string fwOkDp;
					fwOkDp = INCHXMLSystems[i] + ":" + ACTIVE_FW_OK;
					dpQueryConnectSingle("composeAndSendINCHBXML", true, INCHXMLSystems[i], 
																"SELECT '_alert_hdl.._act_prior' FROM '{" + fwOkDp + "}' REMOTE '" + INCHXMLSystems[i] + "'", 
																queryTimeOut);
				}
			}
			connectionINCHBExecuted = true;
		}
		else  // not active anymore -> close connections
		{
			for(int i = 1; i <= dynlen(INCHXMLSystems);i++)
			{
				// if not active anymore, -> disconnect to avoid multiple connections
				int ret;
				ret = dpQueryDisconnect("composeAndSendINCHBXML", INCHXMLSystems[i]); 
				//DebugTN("sgNavirINCHXMLLib; connectDisconnectINCHBXML; dpQueryDisconnect ret: " + ret);	
			}
			
			//DebugTN("sgNavirINCHXMLLib; connectDisconnectINCHBXML; Close tcp connection B!");
			tcpClose(tcpIdINCHB);
			tcpIdINCHB = -1;
			
			INCHBXMLLibIsActiveChain = false;
			connectionINCHBExecuted = false;
		}// if chain active
	}// if chain changed	
	lastActiveChainINCHB = activeChain;
}//connectDisconnectINCHBXML

// heartbeat script loop to write the hearbeat message periodically
void heartbeatLoopCore(string INCHChain)
{
	bool lastTCPWriteOK;
	
	lastTCPWriteOK = true; // to force the loop at least one time
	
	if(INCHChain == "A")	
	{	
		while(!connectionINCHAExecuted)  // wait on connection status from tcpopen
			delay (0,200);
	}
	
	if(INCHChain == "B")	
	{	
		while(!connectionINCHBExecuted)  // wait on connection status from tcpopen
			delay (0,200);
	}
		
	// heartbeat loop
	while(lastTCPWriteOK)
	{
		string heartbeatMessage;
							
		// Add XML header and system
		heartbeatMessage = XMLaddHeader(XMLcreateTag("NavirStatus", "Version", "1.0",
												XMLcreateTag("System", makeDynString("Name", "Source"), makeDynString("Navir", ""), "")
												)) + "|"; 
	
		lastTCPWriteOK = writeTCPXMLmessage(INCHChain, heartbeatMessage, false);
		delay(0, 500); // heartbeat delay
	}//heartbeat loop
	
	if(INCHChain == "A")
			connectionINCHAExecuted = false; // after heartbeat error re initialize the connection
	
	if(INCHChain == "B")
			connectionINCHBExecuted = false; // after heartbeat error re iniatilize the connection
		
//	DebugTN("sgNavirINCHXMLLib.ctl;heartbeatLoopCore; INCHChain: " + INCHChain + " lastTCPWriteOK: " + lastTCPWriteOK);
}//heartbeatLoopCore


// write on TCP the given message and set the INCH Navir connections statuses. Return TRUE if last write was ok, else FALSE
bool writeTCPXMLmessage(string INCHChain, string XMLmessage, bool historyTrace)
{
	bool lastTCPWriteOK;

	if( (INCHAXMLLibIsActiveChain && INCHChain == "A") || (INCHBXMLLibIsActiveChain && INCHChain == "B"))
	{
		// Send the XML message
		int XMLSentBytes;	
		XMLSentBytes = -1;	
		

		if (tcpIdINCHA > -1 && INCHChain == "A")
			XMLSentBytes = tcpWrite(tcpIdINCHA, XMLmessage);
		if (tcpIdINCHB > -1 && INCHChain == "B")
			XMLSentBytes = tcpWrite(tcpIdINCHB, XMLmessage);

		if(historyTrace)
		{
			string logString;
			
			if(INCHChain == "A")
				logString = getHostname() + ": sgNavirINCHXMLLib; writeTCPXMLmessage; XMLSentBytes: " + XMLSentBytes 
 																+ " Bytes sent to INCH " + INCHChain + " tcpIdINCHA: " + tcpIdINCHA + " XMLmessage: " + XMLmessage;
			if(INCHChain == "B")
				logString = getHostname() + ": sgNavirINCHXMLLib; writeTCPXMLmessage; XMLSentBytes: " + XMLSentBytes 
																+ " Bytes sent to INCH " + INCHChain + " tcpIdINCHB: " + tcpIdINCHB + " XMLmessage: " + XMLmessage;
	
			DebugTN("sgNavirINCHXML.ctl; " + logString);
                        strreplace(logString, "|", "#");  // sgFw history doesn't support "|"
			sgHistoryAddEvent("NavirUtils.XMLINCH.XMLHistory", SEVERITY_SYSTEM, logString);	
		}
		
		if(isChainA())
		{	
			if(XMLSentBytes > -1)
			{
				setINCHConnectionStatus("A", INCHChain, OPS_STATUS);
				lastTCPWriteOK = true; // last send ok
			}
			else
			{
				setINCHConnectionStatus("A", INCHChain, U_S_STATUS);
				lastTCPWriteOK = false; // to force the main loop to retry the connection
			}
		
		}// is chain A
		if(isChainB())
		{	
			if(XMLSentBytes > -1)
			{
				setINCHConnectionStatus("B", INCHChain, OPS_STATUS);
				lastTCPWriteOK = true; // last send ok
			}
			else
			{
				setINCHConnectionStatus("B", INCHChain, U_S_STATUS);
				lastTCPWriteOK = false; // to force the main loop to retry the connection
			}
		}// is chain B
	}
	return lastTCPWriteOK;
}// writeTCPXMLmessage









