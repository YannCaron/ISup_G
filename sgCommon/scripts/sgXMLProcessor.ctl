main()
{

	sgDBWaitForInit();

	sgProcessorsLibInit();
		
	// Th.V check if xmlmatching table are ok
	if (!initISupXMLLib())
	{
		DebugTN("sgXMLProcessor >> Because of an error in initISupXMLLib the XML processor will not start");
		return;
	}

	//DebugTN("Will create XML Server");
	string processorName = "XMLServer";
	
	int port, timeout;
	dpGet("XMLServer.Config.Port", port, 
				"XMLServer.Config.Timeout", timeout);
				
  // DebugTN("XML serveur >> port: " + port + ", timeout: " + timeout);
	sgProcessorServerCreate(processorName, port, timeout, "0", true);

	string thisChain;
	string statusDpName;
	
	if(isServerA(getHostname()))
	{
		thisChain = "A";
		statusDpName = "XMLServer.StatusA.PreStatus";
	}
	else if(isServerB(getHostname()))
	{
		thisChain = "B";
		statusDpName = "XMLServer.StatusB.PreStatus";
	}
	
	string activeChain;
	
	int status;
	int oldStatus = -1;	
	
	while(true)
	{
		status = sgProcessorsGetStatus(processorName);
// VL: do not empty the XML cache as we don't make any force to UKN on switchover 19-APR-05

//		if(status == PROC_STATUS_CLOSED)
//		{
//			sgXMLPrepareForceToUKN();
//		}

		dyn_string messages;
		
		messages = sgProcessorsGetMessages(processorName);
		for(int cpt = 1; cpt <= dynlen(messages); cpt += 2)
		{
//			DebugTN("XMLProcessor: received message:" + messages[cpt + 1]);
//			DebugTN("    on connection id " + messages[cpt]);
	
				dyn_dyn_string xmls;
				int xmlsIndex;
				string res;
				// send a response to the sender (xml processor emulator)	
                                if (dynlen(messages) < (cpt+1))
                                {
                                   DebugTN((cpt+1), messages);
                                   break;        
                                }
                                
                                xmls = XMLsplit(messages[cpt + 1]);
                                //DebugTN("after xmlsplit", dynlen(messages),cpt);
				for(xmlsIndex = 1; xmlsIndex <= dynlen(xmls); xmlsIndex++)
				{
					res = XMLanalyseISupStatus(xmls[xmlsIndex], false);
					
					sgProcessorsServerSendMessage(processorName, messages[cpt], res);
					
				}			
				sgProcessorsCloseConnection(processorName, messages[cpt]);
				//DebugTN("will call sgProcessorsCloseConnection for: ", messages[cpt]);
				
		}
		
		dpSet("XMLServer.References.Chain" + thisChain, true);
		

		string currentStatus;
		dpGet("FwUtils.Framework.ActiveChain", activeChain,
					statusDpName, currentStatus);
		
		// VL,AJ: 24-JUN-2005: added this check to re-write status in case of timeout after a switchover			
		if(isUKN(currentStatus))
		{
			if(thisChain == activeChain)
			{
				if (status == PROC_STATUS_OPEN)
					dpSet(statusDpName, OPS_STATUS);
				else
					dpSet(statusDpName, U_S_STATUS);
			}
			else
			{
				dpSet(statusDpName, SBY_STATUS);
			}
		}


		// VL: 22-JUN-2005: added the old / new status comparison
		if(status != oldStatus)
		{
			if(status == PROC_STATUS_OPEN)
			{
				dpSet(statusDpName, OPS_STATUS);
			}
			else
			{
				// AJ: 24.06.2005 removed because it is done before already
				// VL: 22-JUN-2005: moved the dpGet in the else block, as it is not needed if processor is OPEN
				//dpGet("FwUtils.Framework.ActiveChain", activeChain);
	
				if(thisChain == activeChain)
					dpSet(statusDpName, U_S_STATUS);
				else
					dpSet(statusDpName, SBY_STATUS);
			}		
			oldStatus = status;
		}
		// 20070111 aj changed to 500ms instead of 1 second - faster response to messages
		delay(0,500);
	}
	
}

