// Process and write the CRYSTAL output
// Version strongly inspired on sgINCHLib (search and replace...)
// PW July 2010

const string CRYSTAL_PROCESSOR = "CRYSTAL processor";

void sgCRYSTALRun()
{
	//DebugTN("start sgCRYSTALRun for site: ", site);
	sgDBWaitForInit();
	
	sgCRYSTALForceToUKN(); // Library
	
	// Th.V 06.16.05 do not start if XML matching table are wrong
	if (!initISupXMLLib())
		return;
		
	

	dpConnect("CRYSTALOutput", false, "CRYSTAL.CommandOut");
		
	string hostAddress1, hostAddress2;
	int port1, port2, timeout, CRYSTALSeparator;
	dpGet("CRYSTAL.Config.Server1.HostAddress", hostAddress1,
	      "CRYSTAL.Config.Server2.HostAddress", hostAddress2,
	      "CRYSTAL.Config.Timeout", timeout,
	      "CRYSTAL.Config.Separator", CRYSTALSeparator);
        
 	port1 = getConfigValue(hostAddress1);
	port2 = getConfigValue(hostAddress2);
	      
	string processorName1 = CRYSTAL_PROCESSOR + "1";
	string processorName2 = CRYSTAL_PROCESSOR + "2";
	     	 		
	sgProcessorCreate(processorName1, hostAddress1, port1, timeout, CRYSTALSeparator, true);
	sgProcessorCreate(processorName2, hostAddress2, port2, timeout, CRYSTALSeparator, true);
	
	bool b = sgDBSet(DBKEY_PROCESSOR_PREFIX + processorName1, DB_KEY_PROCESSOR_OLDSTATUS, 0);
	if (!b)
	{
		DebugTN("sgCRYSTALProcessor >> unable to add DB_KEY_PROCESSOR_OLDSTATUS variable to the table" +  processorName1);
		return;
	}
	
	bool b = sgDBSet(DBKEY_PROCESSOR_PREFIX + processorName2, DB_KEY_PROCESSOR_OLDSTATUS, 0);
	if (!b)
	{
		DebugTN("sgCRYSTALProcessor >> unable to add DB_KEY_PROCESSOR_OLDSTATUS variable to the table" +  processorName2);
		return;
	}
	
	string thisChain = getThisChain();
	
	// DebugTN("Start of CRYSTAL processor");	
	while(true)
	{	
		// DebugTN("Will update processor status");
		//updateProcessor(thisChain, "CRYSTAL.CRYSTAL" + 1 + ".Interface" + thisChain + "Status.PreStatus", processorName1, "CRYSTAL.Heartbeat", "CRYSTAL.History", processorName2);
		updateProcessor(thisChain, "CRYSTAL.CRYSTAL" + 1 + ".Interface" + thisChain + "Status.PreStatus", processorName1, "CRYSTAL.History", processorName2);
		//updateProcessor(thisChain, "CRYSTAL.CRYSTAL" + 2 + ".Interface" + thisChain + "Status.PreStatus", processorName2, "CRYSTAL.Heartbeat", "CRYSTAL.History", processorName1);
		updateProcessor(thisChain, "CRYSTAL.CRYSTAL" + 2 + ".Interface" + thisChain + "Status.PreStatus", processorName2, "CRYSTAL.History", processorName1);
		
		sgGenericProcessorUpdateTimeout(processorName1, "CRYSTAL.Heartbeat");
		sgGenericProcessorUpdateTimeout(processorName2, "CRYSTAL.Heartbeat");
		
		delay(1);
	}
}


void CRYSTALOutput(string commandOutDpName, string commandOutValue)
{
	int res;
	string xml;
	string tag;
	string subSystemName;
	string command;
	
	//DebugTN("CRYSTALLib", site);
	
	if(commandOutValue == "")
		return;
	
	// DebugN("sgCRYSTALLib Output starts for message " + commandOutValue);
	
	// Refresh command
	if(commandOutValue == "Refresh")
	{
		tag = XMLcreateTag("Command", makeDynString("Name"), makeDynString("Refresh"), "");	
		tag = XMLcreateTag("System", makeDynString("Name"), makeDynString("CRYSTAL"), tag);	
		tag = XMLcreateTag("ISupCommand", makeDynString("Version"), makeDynString("1.0"), tag);	
		xml = tag;
		// delay(1);
//		DebugTN("sgCRYSTALLib CRYSTALOutput: end of the delay befor sending the refresh command to CRYSTAL");
	}
	// Connect or Disconnect command
	else if(strpos(commandOutValue, "Restart") != -1 )
	{
          // PW July 2010
          //  Only 2 x 2 client for CRYSTAL -> following treatment not necessary

                    
		subSystemName = substr(commandOutValue, strpos(commandOutValue, " ") + 1, (strlen(commandOutValue) - strpos(commandOutValue, " ")) - 1);
	
                /*
                if(strpos(subSystemName, "client") != -1)
		{
			// we must match client name from XML matching table
//			DebugTN("CRYSTALLIb: client name is " + subSystemName);
			
			string output;
			output = "CRYSTAL.Components.Clients.0" + substr(subSystemName, 6);
//			DebugTN("CRYSTALLib: output is " + output);
			
			dyn_string inputs;
			dyn_string outputs;
			
			dpGet("CRYSTAL.XMLMatchingTableClients.Input", inputs,
						"CRYSTAL.XMLMatchingTableClients.Output", outputs);
						
			int clientIndex = dynContains(outputs, output);
			if(clientIndex != 0)
			{
				subSystemName = inputs[clientIndex];
				subSystemName = substr(subSystemName, strpos(subSystemName, ".") + 1); // remove "CRYSTAL." or "CRYSTAL_L." ..
//				DebugTN("CRYSTALLIb: subSystemName is " + subSystemName);
			}
			else
			{
//				DebugTN("CRYSTALLib: can not find client name to restart client " + subSystemName);
			}
			
		}
                */ //PW july 2010
          
          
		command = substr(commandOutValue, 0, strpos(commandOutValue, " ")); 
		
		tag = XMLcreateTag("Command", makeDynString("Name"), makeDynString(command), "");	
		tag = XMLcreateTag("SubSystem", makeDynString("Name"), makeDynString(subSystemName), tag);	
		tag = XMLcreateTag("System", makeDynString("Name"), makeDynString("CRYSTAL"), tag);	
		tag = XMLcreateTag("ISupCommand", makeDynString("Version"), makeDynString("1.0"), tag);	
		xml = tag;
	}
	else
	{
		xml = commandOutValue;
	}
	
	// xml = xml + (char)0x7C;
	//DebugTN("CRYSTALLib: send command " + xml);
	sgHistoryAddEvent("CRYSTAL.SystemHistory", SEVERITY_SYSTEM, "send command " + xml);
	

	sgProcessorsSendMessage(CRYSTAL_PROCESSOR + "1", xml);
	sgProcessorsSendMessage(CRYSTAL_PROCESSOR + "2", xml);
//	DebugTN("CRYSTALOutput: will send: " + xml);
}


void sgCRYSTALForceToUKN()
{
	dyn_string names, ds, ds1;

  // YCA 14-09-2010 only one pattern
  names = getPointsFromPattern("CRYSTAL.Components.{Interfaces.*.Instance*,Clients.*,Broker.*}.PreStatus");
	
	for(int cpt = 1; cpt <= dynlen(names); cpt++)
	{
		dynAppend(ds, names[cpt]);
		dynAppend(ds1, "UKN");
	}

 	names = getPointsFromPattern("CRYSTAL.Components.{Clients,Broker}.*.Label1");
	
	for(int cpt = 1; cpt <= dynlen(names); cpt++)
	{
		dynAppend(ds, names[cpt]);
		dynAppend(ds1, "");
	}
	
	dpSetWait(ds, ds1);
	// delay(2);
	
	dpSet("CRYSTAL.GlobalStatus.CommandOut", "Refresh");
}
