const string VASCH_PROCESSOR = "Vasch processor";

//int gVaschId;
//int gStatus1 = -1;
//int gStatus2 = -1;
//string gActivChain;

main()
{
	gVaschId = 2;

	sgDBWaitForInit();
	
	if (!initISupXMLLib())
		return;
	
	forceAllVaschToUKN();
	
	dpConnect("vaschCommandOutChanged", "VASCH.Commands.Out");
	
	string hostAddress1, hostAddress2;
	int port1, port2, timeout;
	dpGet("VASCH.Config.HostAddress1", hostAddress1,
	      "VASCH.Config.HostAddress2", hostAddress2,
	      "VASCH.Config.Timeout", timeout);
        
 	port1 = getConfigValue(hostAddress1);
	port2 = getConfigValue(hostAddress2);
	
	string processorName1 = VASCH_PROCESSOR + 1;
	string processorName2 = VASCH_PROCESSOR + 2;
	 	
	sgProcessorCreate(processorName1, hostAddress1, port1, timeout, "7", true);
	sgProcessorCreate(processorName2, hostAddress2, port2, timeout, "7", true);
		
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
	
//	dpConnect("vaschActivchainChanged", ACTIVE_CHAIN);
	
	while(true)
	{
		updateProcessor(thisChain, "VASCH.VASCH" + 1 + ".Interface" + thisChain + "Status.PreStatus", processorName1, "VASCH.History", processorName2);
		updateProcessor(thisChain, "VASCH.VASCH" + 2 + ".Interface" + thisChain + "Status.PreStatus", processorName2, "VASCH.History", processorName1);
		
		updateVaschTimeOuts(1);		
		updateVaschTimeOuts(2);		
		delay(1);
	}
}

// void vaschActivchainChanged(string dpName, string dpValue)
// {
	// DebugTN("vaschActivChainChanged >> new activ chain is: " + dpValue);
// 	gActivChain = dpValue;
// }
// 
// 

