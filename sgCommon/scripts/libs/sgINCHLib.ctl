// Process and write the INCH output

const string INCH_PROCESSOR = "INCH processor";

void sgINCHRun(string site = "")
{
	//DebugTN("start sgINCHRun for site: ", site);
	sgDBWaitForInit();
	
	sgINCHForceToUKN(site); // Library
	
	// Th.V 06.16.05 do not start if XML matching table are wrong
	if (!initISupXMLLib())
		return;
		
	

	dpConnect("inchOutput", false, "INCH" + site + ".CommandOut");
		
	string hostAddress1, hostAddress2;
	int port1, port2, timeout, INCHSeparator;
        
	dpGet("INCH" + site + ".Config.Server1.HostAddress", hostAddress1,
	      "INCH" + site + ".Config.Server2.HostAddress", hostAddress2,
	      "INCH" + site + ".Config.Timeout", timeout,
	      "INCH" + site + ".Config.Separator", INCHSeparator);

	port1 = getConfigValue(hostAddress1);
	port2 = getConfigValue(hostAddress2);
	      
	string processorName1 = INCH_PROCESSOR + site + "1";
	string processorName2 = INCH_PROCESSOR + site + "2";
	     	 		
	sgProcessorCreate(processorName1, hostAddress1, port1, timeout, INCHSeparator, true);
	sgProcessorCreate(processorName2, hostAddress2, port2, timeout, INCHSeparator, true);
	
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
	
	string thisChain = getThisChain();
	
	// DebugTN("Start of INCH processor");	
	while(true)
	{	
		// DebugTN("Will update processor status");
		//updateProcessor(thisChain, "INCH.INCH" + 1 + ".Interface" + thisChain + "Status.PreStatus", processorName1, "INCH.Heartbeat", "INCH.History", processorName2);
		updateProcessor(thisChain, "INCH" + site + ".INCH" + 1 + ".Interface" + thisChain + "Status.PreStatus", processorName1, "INCH" + site + ".History", processorName2);
		//updateProcessor(thisChain, "INCH.INCH" + 2 + ".Interface" + thisChain + "Status.PreStatus", processorName2, "INCH.Heartbeat", "INCH.History", processorName1);
		updateProcessor(thisChain, "INCH" + site + ".INCH" + 2 + ".Interface" + thisChain + "Status.PreStatus", processorName2, "INCH" + site + ".History", processorName1);
		
		sgGenericProcessorUpdateTimeout(processorName1, "INCH" + site + ".Heartbeat");
		sgGenericProcessorUpdateTimeout(processorName2, "INCH" + site + ".Heartbeat");
		
		delay(1);
	}
}


void inchOutput(string commandOutDpName, string commandOutValue)
{
	int res;
	string xml;
	string tag;
	string subSystemName;
	string command;
	string site;
	
	site = strltrim(dpSubStr(commandOutDpName,DPSUB_DP), "INCH");
	//DebugTN("INCHLib", site);
	
	if(commandOutValue == "")
		return;
	
	// DebugN("sgINCHLib Output starts for message " + commandOutValue);
	
	// Refresh command
	if(commandOutValue == "Refresh")
	{
		tag = XMLcreateTag("Command", makeDynString("Name"), makeDynString("Refresh"), "");	
		tag = XMLcreateTag("System", makeDynString("Name"), makeDynString("INCH"), tag);	
		tag = XMLcreateTag("ISupCommand", makeDynString("Version"), makeDynString("1.0"), tag);	
		xml = tag;
		// delay(1);
//		DebugTN("sgINCHLib inchOutput: end of the delay befor sending the refresh command to INCH");
	}
	// Connect or Disconnect command
	else if(strpos(commandOutValue, "Restart") != -1 )
	{
		// interface
		// Get system name
		subSystemName = substr(commandOutValue, strpos(commandOutValue, " ") + 1, (strlen(commandOutValue) - strpos(commandOutValue, " ")) - 1);
		if(strpos(subSystemName, "client") != -1)
		{
			// we must match client name from XML matching table
//			DebugTN("INCHLIb: client name is " + subSystemName);
			
			string output;
			output = "INCH" + site + ".Components.Clients.0" + substr(subSystemName, 6);
//			DebugTN("INCHLib: output is " + output);
			
			dyn_string inputs;
			dyn_string outputs;
			
			dpGet("INCH" + site + ".XMLMatchingTableClients.Input", inputs,
						"INCH" + site + ".XMLMatchingTableClients.Output", outputs);
						
			int clientIndex = dynContains(outputs, output);
			if(clientIndex != 0)
			{
				subSystemName = inputs[clientIndex];
				subSystemName = substr(subSystemName, strpos(subSystemName, ".") + 1); // remove "INCH." or "INCH_L." ..
//				DebugTN("INCHLIb: subSystemName is " + subSystemName);
			}
			else
			{
//				DebugTN("INCHLib: can not find client name to restart client " + subSystemName);
			}
			
		}
		command = substr(commandOutValue, 0, strpos(commandOutValue, " ")); 
		
		tag = XMLcreateTag("Command", makeDynString("Name"), makeDynString(command), "");	
		tag = XMLcreateTag("SubSystem", makeDynString("Name"), makeDynString(subSystemName), tag);	
		tag = XMLcreateTag("System", makeDynString("Name"), makeDynString("INCH"), tag);	
		tag = XMLcreateTag("ISupCommand", makeDynString("Version"), makeDynString("1.0"), tag);	
		xml = tag;
	}
	else
	{
		xml = commandOutValue;
	}
	
	// xml = xml + (char)0x7C;
	//DebugTN("INCHLib: send command " + xml);
	sgHistoryAddEvent("INCH" + site + ".SystemHistory", SEVERITY_SYSTEM, "send command " + xml);
	

	sgProcessorsSendMessage(INCH_PROCESSOR + site + "1", xml);
	sgProcessorsSendMessage(INCH_PROCESSOR + site  + "2", xml);
//	DebugTN("inchOutput: will send: " + xml);
}


void sgINCHForceToUKN(string site = "")
{
	dyn_string names, ds, ds1;

	names = getPointsFromPattern("INCH" + site + ".Components.Interfaces.*.Instance1.PreStatus");
	
	for(int cpt = 1; cpt <= dynlen(names); cpt++)
	{
		dynAppend(ds, names[cpt]);
		dynAppend(ds1, "UKN");
	}

	names = getPointsFromPattern("INCH" + site + ".Components.Interfaces.*.Instance2.PreStatus");
	
	for(int cpt = 1; cpt <= dynlen(names); cpt++)
	{
		dynAppend(ds, names[cpt]);
		dynAppend(ds1, "UKN");
	}
	
	// meteo has 4 instances...
	names = getPointsFromPattern("INCH" + site + ".Components.Interfaces.*.Instance3.PreStatus");
	
	for(int cpt = 1; cpt <= dynlen(names); cpt++)
	{
		dynAppend(ds, names[cpt]);
		dynAppend(ds1, "UKN");
	}
	
	names = getPointsFromPattern("INCH" + site + ".Components.Interfaces.*.Instance4.PreStatus");
	
	for(int cpt = 1; cpt <= dynlen(names); cpt++)
	{
		dynAppend(ds, names[cpt]);
		dynAppend(ds1, "UKN");
	}
	
	

	names = getPointsFromPattern("INCH" + site + ".Components.Clients.*.PreStatus");
	
	for(int cpt = 1; cpt <= dynlen(names); cpt++)
	{
		dynAppend(ds, names[cpt]);
		dynAppend(ds1, "UKN");
	}
	
	names = getPointsFromPattern("INCH" + site + ".Components.Clients.*.Label1");
	
	for(int cpt = 1; cpt <= dynlen(names); cpt++)
	{
		dynAppend(ds, names[cpt]);
		dynAppend(ds1, "");
	}

	names = getPointsFromPattern("INCH" + site + ".Components.{Broker.*.PreStatus, DRA.PreStatus}");

	for(int cpt = 1; cpt <= dynlen(names); cpt++)
	{
		dynAppend(ds, names[cpt]);
		dynAppend(ds1, "UKN");
	}

	dpSetWait(ds, ds1);
	// delay(2);
	
	dpSet("INCH" + site + ".GlobalStatus.CommandOut", "Refresh");
}	
