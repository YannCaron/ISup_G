const string WAGO_STATUS_POSTFIX = ".Status_%1";

string getWAGOStatus(string WAGOInput)
{

	string WAGOName;
	string WAGOStatus;

	WAGOName = dpSubStr(WAGOInput, DPSUB_DP);
	WAGOStatus = WAGOName + strplace(WAGO_STATUS_POSTFIX, getActiveChain());

	return WAGOStatus;

}

void sgFwSpecificConnections(string input, string output, string rule, string params)
{
//  DebugTN("sgFwSpecificConnections called: input:" + input    + "  rule:" + rule); 

	if(rule == "ConnectWAGOWithConvertTable")
	{
		dpConnect("connectWAGOWithConvertTable", false, input, output, getWAGOStatus(input),
									params + ".Input", params + ".Output");
		return;
	}

	if(rule == "ConnectCTC")
	{
		dpConnect("connectCTC", false, input, output);
		return;
	}

	if(rule == "ConnectPRIMUS")
	{
		dpConnect("connectPRIMUS", false, input, output);
		return;
	}

        // 20071009 aj
        // the same as ConnectWithConvertTabel but with initialisation!! (needed for recording)
	if(rule == "ConnectWithConvertTableInit")
	{
		dpConnect("writeConvertedValue", false, input, output, params + ".Input", params + ".Output");
                // initialise all sessions and therefore call work function
                // if not done at all, not existing sessions stay UKN (fw init)
                // if work function triggered via "true" in dpConnect sessions may be OPS at startup (from before)
                // "-1" to make watchdog delete labels when deleting comptext (wd sets "0")
                dpSet(input,-1);

		return;
	}
        // PW: november 2008, new connection for Rec Voice ZRH in Dub
	if(rule == "ConnectRecVoiceLoggerIDToDescription")
	{
		dpConnect("connectRecVoiceLoggerIDToDescription", true, input, output);
		return;
	}

	if(rule == "ConnectVOLATISRx")
	{
		dpConnectVOLATISRx(input, output, rule, params);
		return;
	}        
        
	if(rule == "ConnectVOLATISTx")
	{
		dpConnectVOLATISTx(input, output, rule, params);
		return;
	}        
      
  if(rule == "ConnectCPDLCSITAATN")
	{
		dpConnectCPDLCSITAATN(input, output, rule, params);
		return;
	}   
  
  if(rule == "ConnectCPDLCATNStack")
	{
		dpConnectCPDLCATNStack(input, output, rule, params);
		return;
	}   
    
  if(rule == "ConnectRDPARTASActiveChain")
	{
		dpConnectRDPARTASActiveChain(input, output, rule, params);
		return;
	}   
  
  if(rule == "ConnectRDPARTAS4Entries")
 	{ 
		dpConnectRDPARTAS4Entries(input, output, rule, params);
		return;
	}   

  if(rule == "ConnectRDPARTASChainComponents")
 	{ 
		dpConnectRDPARTASChainComponents(input, output, rule, params);
		return;
	}   
  
  if(rule == "ConnectRDPARTASUserLabel")
 	{ 
		dpConnectRDPARTASUserLabel(input, output, rule, params);
		return;
	}   
  
  if(rule == "ConnectRDPARTASRadarStatus")
 	{ 
		dpConnectRDPARTASRadarStatus(input, output, rule, params);
		return;
	}   

  if(rule == "ConnectRDPARTASRadarLabel")
 	{ 
		dpConnectRDPARTASRadarLabel(input, output, rule, params);
		return;
	}   
  
   if(rule == "ConnectRDPUsedChannel")
 	{ 
		dpConnectRDPUsedChannel(input, output, rule, params);
		return;
	}
  
   if(rule == "ConnectRDPARTASNode")
 	{ 
		dpConnectRDPARTASNode(input, output, rule, params);
		return;
	}

  if(rule == "ConnectDCLLines")
 	{ 
		dpConnectDCLLines(input, output, rule, params);
		return;
	}   
 
  if(rule == "ConnectSmartRadioDescriptionMessage")
 	{ 
			int res =	dpConnect("connectSmartRadioDescriptionMessage", true, input, output);
//  DebugTN("ConnectSmartRadioDescriptionMessage res: " + res);
  return;
	}   

  if(rule == "ConnectSplitTACOTraps")
 	{ 
			int res =	dpConnect("connectSplitTACOTraps", true, input, output, params + ".Input", params + ".Output");
//  DebugTN("connectSplitTACOTraps res: " + res);
  return;
	}    
  
//Navir connections Rules
	if(rule == "ConnectNavirWithConvertTable")
	{
	//	 Same rule as writeConvertedValue but refreshed at restart and check the userbit (OPC status)
		dpConnect("writeNavirConvertedValue", true, input, output, params + ".Input", params + ".Output");

		return;
	}
	
	// Station connection Rule
	if(rule == "ConnectNavirStation")
	{
		// Specific connection for Navir Stations
                
                //Get nr navaids in station      
                string nrNavaidsDpDname;
	        int nrNavaids; 
                nrNavaidsDpDname = substr( input, 0, strpos(input, ".RawDatas"));
                dpGet(nrNavaidsDpDname + ".General.NrNavaids", nrNavaids);
                
 		// Station
		dpConnect("writeNavirConvertedStatusAndTS", true, input + ".Station.Station.Status", input + ".TimeStamp", 
			output + ".Station.Station.Status.PreStatus", output + ".Station.Station.Status.Message", params + ".Input", params + ".Output");

		// Environment
		dpConnect("writeNavirConvertedStatusAndTS", true, input + ".Station.Environment.Status", input + ".TimeStamp", 
			output + ".Station.Environment.Status.PreStatus", output + ".Station.Environment.Status.Message", params + ".Input", params + ".Output");

		// //Plc
		dpConnect("writeNavirConvertedStatusAndTS", true, input + ".Station.Plc.Status", input + ".TimeStamp", 
			output + ".Station.Plc.Status.PreStatus", output + ".Station.Plc.Status.Message",params + ".Input", params + ".Output");

		// Specifics
		dpConnect("writeNavirConvertedStatusAndTS", true, input + ".Station.Specifics.Status", input + ".TimeStamp", 
			output + ".Station.Specifics.Status.PreStatus", output + ".Station.Specifics.Status.Message",params + ".Input", params + ".Output");

		// Navaid 1
		dpConnect("writeNavirConvertedStatusAndTS", true, input + ".Navaid_1.Status", input + ".TimeStamp", 
			output + ".Navaid_1.Status.PreStatus", output + ".Navaid_1.Status.Message", params + ".Input", params + ".Output");

                if (nrNavaids > 1)            										
		  // Navaid 2
		  dpConnect("writeNavirConvertedStatusAndTS", true, input + ".Navaid_2.Status", input + ".TimeStamp", 
			  output + ".Navaid_2.Status.PreStatus", output + ".Navaid_2.Status.Message", params + ".Input", params + ".Output");

                if (nrNavaids > 2)            										
  		  // Navaid 3
		  dpConnect("writeNavirConvertedStatusAndTS", true, input + ".Navaid_3.Status", input + ".TimeStamp", 
			  output + ".Navaid_3.Status.PreStatus", output + ".Navaid_3.Status.Message", params + ".Input", params + ".Output");

		// Link A		
		dpConnect("writeNavirConvertedValue", true, input + ".Links.LinkAStatus", 
			output + ".Links.LinkAStatus.PreStatus", params + ".Input", params + ".Output");
		// Link B		
		dpConnect("writeNavirConvertedValue", true, input + ".Links.LinkBStatus",
			output + ".Links.LinkBStatus.PreStatus", params + ".Input", params + ".Output");

		// TS Clock A		
		dpConnect("writeNavirConvertedValue", true, input + ".Links.TSAStatus",
			output + ".Links.TSAStatus.PreStatus", params + ".Input", params + ".Output");

		// TS Clock B		
		dpConnect("writeNavirConvertedValue", true, input + ".Links.TSBStatus",
			output + ".Links.TSBStatus.PreStatus", params + ".Input", params + ".Output");

		// Operational Status Navaid 1		
		dpConnect("writeNavirConvertedValue", true, input + ".Navaid_1.OperationalStatus",
                           output + ".Navaid_1.OperationalStatus.PreStatus", "StdNavirOPSStatus.Input", "StdNavirOPSStatus.Output");
			
               if (nrNavaids > 1)            										
		  // Operational Status Navaid 2		
    		  dpConnect("writeNavirConvertedValue", true, input + ".Navaid_2.OperationalStatus",
													output + ".Navaid_2.OperationalStatus.PreStatus", "StdNavirOPSStatus.Input", "StdNavirOPSStatus.Output");
               if (nrNavaids > 2)            										
		  // Operational Status Navaid 3		
		  dpConnect("writeNavirConvertedValue", true, input + ".Navaid_3.OperationalStatus",
													output + ".Navaid_3.OperationalStatus.PreStatus", "StdNavirOPSStatus.Input", "StdNavirOPSStatus.Output");
		return;
	}

		// P.W. Navir connection rule 28012005
	if(rule == "ConnectTSToAllMessages")
	{
		dpConnect("connectTSToAllMessages", true, input, output, params + ".PostFixes"); // no params, no specified outputs
	
		return;
	}

	// P.W. Navir connection rule 28042005 to connect the phone Nr at Fw Start
	if(rule == "ConnectNavirCopy")
	{
		dpConnect("connectCopy", true, input, output);
		return;
	}
  
  
 	if(rule == "SetGBASDCPActiveChannel")
 	{
 		dpConnect("setGBASDCPActiveChannel", true, input + ".Bits1.Bit2", input + ".Bits1.Bit3", 
                                              input + ".Bits2.Bit2", input + ".Bits2.Bit3", 
                                              input + ".DCP1IPAddress",              
                                              input + ".DCP2IPAddress",
                                              output);
 		return;
 	}

 	if(rule == "ConnectNavirGBASDCP1")
 	{
 		dpConnect("connectNavirGBASDCP", true, input + ".DefaultBits.Bit0", input + ".DefaultBits.Bit2", 
                                          output);
 		return;
 	}
    
  if(rule == "ConnectNavirGBASDCP2")
 	{
 		dpConnect("connectNavirGBASDCP", true, input + ".DefaultBits.Bit1", input + ".DefaultBits.Bit3", 
                                          output);              
 		return;
 	} 
 
  if(rule == "ConnectNavirGBASTX1")
 	{
 		dpConnect("connectNavirGBASTX", true, input + ".Bit0", input + ".Bit7", output);
 		return;
 	} 
  
  if(rule == "ConnectNavirGBASTX2")
 	{
 		dpConnect("connectNavirGBASTX", true, input + ".Bit2", input + ".Bit8", output);
 		return;
 	} 
  
  if(rule == "ConnectNavirGBASOtherWarnings")
 	{
 		dpConnect("connectNavirGBASOtherWarnings", true, input + ".Bit1", input + ".Bit2", input + ".Bit3", 
              input + ".Bit5", input + ".Bit6", output);
 		return;
 	}   

 if(rule == "ConnectNavirGBASPS")
 	{
 		dpConnect("connectNavirGBASPS", true, input, output);
 		return;
 	}   
  

  
  if(rule == "ConnectNavirGBASINCH")
 	{
  int res =	dpConnect("connectNavirGBASINCH", true, 
              input + ".Mode.Bits.Bit0", 
              input + ".Mode.Bits.Bit1", 
              input + ".Mode.Bits.Bit2", 
              input + ".Mode.Bits.Bit5", 
              input + ".Mode.Bits.Bit6", 
              input + ".ConstAlerts.Bits.Bit0",
              input + ".FAS" + params + ".Config.Runway",
              input + ".FAS" + params + ".DefaultFASBroadcastStatus",
              output);
//      DebugTN("ConnectNavirGBASINCH res: " + res);

 		return;
 	} 
  
	if(rule == "ExtractNavirGBAS4Bits")
	{
	int res =	dpConnect("extractNavirGBAS4Bits", true, input, 
                      output + ".Bit0"  , 
                      output + ".Bit1", 
                      output + ".Bit2", 
                      output + ".Bit3");
//    DebugTN("extract4bits res: " + res);
  		return;
	}
  
  if(rule == "ExtractNavirGBAS8Bits")
	{
	int res =	dpConnect("extractNavirGBAS8Bits", true, input, 
                      output + ".Bit0", 
                      output + ".Bit1", 
                      output + ".Bit2", 
                      output + ".Bit3",
                      output + ".Bit4", 
                      output + ".Bit5", 
                      output + ".Bit6", 
                      output + ".Bit7");
//    DebugTN("extract8bits res: " + res);
  		return;
	}

  
 if(rule == "ExtractNavirGBAS16Bits")
	{
	int res =	dpConnect("extractNavirGBAS16Bits", true, input, 
                      output + ".Bit0", 
                      output + ".Bit1", 
                      output + ".Bit2", 
                      output + ".Bit3",
                      output + ".Bit4", 
                      output + ".Bit5", 
                      output + ".Bit6", 
                      output + ".Bit7",  
                      output + ".Bit8", 
                      output + ".Bit9", 
                      output + ".Bit10", 
                      output + ".Bit11",
                      output + ".Bit12", 
                      output + ".Bit13", 
                      output + ".Bit14", 
                      output + ".Bit15");
//    DebugTN("extract16bits res: " + res);
  		return;
	}  

if(rule == "GBASGetDefaultModeFromActiveChannel")
	{
	int res =	dpConnect("GBASGetDefaultValueFromActiveChannel", true, 
                      input + ".Mode1Status", 
                      input + ".Mode2Status", 
                      params,
                      output);
//  DebugTN("GetDefaultValueFromActiveChannel res: " + res);
  return;
	}  

if(rule == "GBASGetDefaultVDBFromActiveChannel")
	{
	int res =	dpConnect("GBASGetDefaultValueFromActiveChannel", true, 
                      input + ".VDB1Status", 
                      input + ".VDB2Status", 
                      params,
                      output);
//  DebugTN("GBASGetDefaultVDBFromActiveChannel res: " + res);
  return;
	}  

if(rule == "GBASGetDefaultPSFromActiveChannel")
	{
	int res =	dpConnect("GBASGetDefaultValueFromActiveChannel", true, 
                      input + ".PS1Status", 
                      input + ".PS2Status", 
                      params,
                      output);
//  DebugTN("GBASGetDefaultPSFromActiveChannel res: " + res);
  return;
	}  

if(rule == "GBASGetDefaultRSMUFromActiveChannel")
	{
	int res =	dpConnect("GBASGetDefaultValueFromActiveChannel", true, 
                      input + ".RSMU1Status", 
                      input + ".RSMU2Status", 
                      params,
                      output);
//  DebugTN("GBASGetDefaultPSFromActiveChannel res: " + res);
  return;
	}  

if(rule == "GBASGetDefaultFASBroadcastStatusFromActiveChannel")
	{
	int res =	dpConnect("GBASGetDefaultValueFromActiveChannel", true, 
                      input + ".FASBroadcastStatus1", 
                      input + ".FASBroadcastStatus2", 
                      params,
                      output);
//  DebugTN("GBASGetDefaultFASBroadcastStatusFromActiveChannel res: " + res);
  return;
	}  

if(rule == "GBASGetDefaultConstAlertsFromActiveChannel")
	{
	int res =	dpConnect("GBASGetDefaultValueFromActiveChannel", true, 
                      input + ".ConstAlerts1Status", 
                      input + ".ConstAlerts2Status", 
                      params,
                      output + ".DefaultConstAlertsStatus");
//  DebugTN("GBASGetDefaultPSFromActiveChannel res: " + res);
	int res =	dpConnect("GBASGetDefaultValueFromActiveChannelForConstAlertTime", true, 
                      input + ".StartGPSSeconds1", 
                      input + ".StartGPSSeconds2", 
                      params,
                      output + ".DefaultStartGPSSeconds");

	int res =	dpConnect("GBASGetDefaultValueFromActiveChannelForConstAlertTime", true, 
                      input + ".StartGPSWeek1", 
                      input + ".StartGPSWeek2", 
                      params,
                      output + ".DefaultStartGPSWeek");  

	int res =	dpConnect("GBASGetDefaultValueFromActiveChannelForConstAlertTime", true, 
                      input + ".EndGPSSeconds1", 
                      input + ".EndGPSSeconds2", 
                      params,
                      output + ".DefaultEndGPSSeconds");

	int res =	dpConnect("GBASGetDefaultValueFromActiveChannelForConstAlertTime", true, 
                      input + ".EndGPSWeek1", 
                      input + ".EndGPSWeek2", 
                      params,
                      output + ".DefaultEndGPSWeek");  
  
  
  //  DebugTN("GBASGetDefaultPSFromActiveChannel res: " + res);
  return;
	}  

if(rule == "ConnectNavirGBASConstAlertStart")
	{
	int res =	dpConnect("connectNavirGBASEstimatedTime", true, 
                      input + ".DefaultStartGPSSeconds", 
                      input + ".DefaultStartGPSWeek", 
                      params + ".Template",
                      output);
//  DebugTN("ConnectNavirGBASStartTime res: " + res);
  return;
	}  

if(rule == "ConnectNavirGBASConstAlertEnd")
	{
	int res =	dpConnect("connectNavirGBASEstimatedTime", true, 
                      input + ".DefaultEndGPSSeconds", 
                      input + ".DefaultEndGPSWeek", 
                      params + ".Template",
                      output);
//  DebugTN("ConnectNavirGBASConstAlertEnd res: " + res);
  return;
	}  

if(rule == "GBASGetDefaultDCPFromActiveChannel")
	{
	int res =	dpConnect("GBASGetDefaultValueFromActiveChannel", true, 
                      input + ".DCP1Status", 
                      input + ".DCP2Status", 
                      params,
                      output);
//  DebugTN("GBASGetDefaultPSFromActiveChannel res: " + res);
  return;
	}  

if(rule == "ConnectNavirINCHConstAlert")
	{
	int res =	dpConnect("connectNavirINCHConstAlert", true, 
                      input + ".PredConstAlertStatus" + STATUS_POSTFIX, 
                      input + ".PredConstAlertStatus" + LABEL1_POSTFIX, 
                      input + ".ConstAlertStatus" + STATUS_POSTFIX, 
                      input + ".ConstAlertStatus" + LABEL1_POSTFIX, 
                      output + PRE_STATUS_POSTFIX, 
                      output + LABEL1_POSTFIX);
//  DebugTN("ConnectNavirINCHConstAlert res: " + res);
  return;
	}  


if(rule == "InfraConnectSerialAgentStatus")
	{
  string agentDPName;
  string busName;
  int resGet1 = dpGet(input + ".Bus", busName);  

  if (resGet1 < 0)
  {  
    DebugTN("InfraConnectSerialAgentStatus; <" + input + ".Bus> not correctly configured (no or false Bus Name)");
    return;
  }
  int resGet2 = dpGet(busName + ".ModbusAgent", agentDPName);  
  if (resGet2 < 0)
  {  
    DebugTN("InfraConnectSerialAgentStatus; <" + busName + ".ModbusAgent> for:<" + input + "> not correctly configured (nor false serialModbus agent)");
    return;
  }  
  int res =	dpConnect("infraConnectSerialAgentStatus", true, 
                      agentDPName + ".Address.Bus", 
                      agentDPName + ".Status.Bus", 
                      agentDPName + ".Status.Bus:_original.._userbit1", 
                      input + ".Address", 
                      input + ".WorkInProgress", 
                      output,
                      params + ".Input", 
                      params + ".Output");
//  DebugTN("InfraConnectSerialAgentStatus res: " + res);
  return;
	}  
  	
if(rule == "ISupConnectSerialAgentStatus")
	{
  int res =	dpConnect("iSupConnectSerialAgentStatus", true, 
                      input + ".Address.Bus", 
                      input + ".Status.Bus",
                      input + ".Status.Bus:_original.._userbit1", 
                      output,
                      params + ".Input", 
                      params + ".Output");
//  DebugTN("ISupConnectSerialAgentStatus res: " + res);
  return;
	}  

	if(rule == "ConnectInfraAlarms")
	{
    dpConnect("connectInfraAlarms", true, input + ".alert.sumalert:_alert_hdl.._act_state", input + ".WAGO.Status", 
              output, params + ".Input", params + ".Output");
//  DebugTN("connectInfraAlarms res: " + res);
		return;
	}


if(rule == "InfraConnectAckAllInputsAlarms")
	{
	  int res =	dpConnect("infraConnectAckAllInputsAlarms", true, input);
//  DebugTN("InfraConnectAckAllInputsAlarms res: " + res);
  return;
	}  

if(rule == "ConnectTELGATE2Lines")
	{
  dyn_string dsParams;
  int resGet1 = dpGet(params, dsParams);  

  if (resGet1 < 0)
  {  
    DebugTN("connectTELGATE2Lines; params:<" + params + "> not correctly configured for input" + input);
    return;
  }
  //DebugTN("connectTELGATE2Lines; dsParams[1]: " + dsParams[1]);         
  
  int res = dpConnect("connectTELGATE2Lines", true, input + dsParams[1], input + dsParams[3], 
              output, params);
 // DebugTN("connectTELGATE2Lines res: " + res);
		return;
	}
    
if(rule == "ConnectTELGATE2Components")
	{
  dyn_string dsParams;
  int resGet1 = dpGet(params, dsParams);  

  if (resGet1 < 0)
  {  
    DebugTN("ConnectTELGATE2ComponentsWithParams; params:<" + params + "> not correctly configured for input" + input);
    return;
  }
  //DebugTN("ConnectTELGATE2ComponentsWithParams; dsParams[1]: " + dsParams[1]);         
  
  int res = dpConnect("connectTELGATE2Components", true, input + dsParams[1], input + dsParams[3], 
              output, params);
 // DebugTN("ConnectTELGATE2ComponentsWithParams res: " + res);
		return;
	}

if(rule == "ConnectTELGATE4Components")
	{
  dyn_string dsParams;
  int resGet1 = dpGet(params, dsParams);  

  if (resGet1 < 0)
  {  
    DebugTN("ConnectTELGATE4Components; params:<" + params + "> not correctly configured for input" + input);
    return;
  }
 // DebugTN("ConnectTELGATE4Components; dsParams[1]: " + dsParams[1]);         
  
		int res = dpConnect("connectTELGATE4Components", true, input + dsParams[1], input + dsParams[3], input + dsParams[5], input + dsParams[7], output, params);
  //DebugTN("ConnectTELGATE4Components res: " + res);
		return;
	}

if(rule == "ConnectTELGATESBCEsip")
	{
  int res = dpConnect("connectTELGATESBCEsip", true, input + ".ESip_1",  input + ".ESip_2", output);
//DebugTN("ConnectTELGATESBCEsip res: " + res);
		return;
	}


	if(rule == "ConnectEMRADIOStatus") { 
		int res = dpConnect("connectEMRADIOStatus", true, input, output);
		return;
	}   

  if(rule == "ConnectEMRADIODescriptionMessage") { 
		int res = dpConnect("connectEMRADIODescriptionMessage", true, 
                        input + ".LocalInfo", 
                        input + ".Station", 
                        input + ".Frequency", 
                        input + ".RadioID", 
                        output);
		return;
	}   

if(rule == "ConnectAMSCHSelectActiveCSS") { 
		int res = dpConnect("connectAMSCHSelectActiveCSS", true, 
                        input + ".CSSAStates", input + ".CSSBStates",    
                        input + ".CSSA_UpTime", input + ".CSSB_UpTime",                        
                        output + "CSSActiveStates", output + "CSSActive"); 
    
//  DebugTN("ConnectAMSCHSelectActiveCSS res: " + res);
   return;
	}   

if(rule == "ConnectAMSCHSelectActiveRSS") { 
		int res = dpConnect("connectAMSCHSelectActiveRSS", true, 
                        input + ".LT.RawDatas.RSSAStates", input + ".LT.RawDatas.RSSBStates",                      
                        input + ".TWR.RawDatas.RSSAStates", input + ".TWR.RawDatas.RSSBStates",
                        input + ".LT.RawDatas.RSSAIdentifiers", input + ".LT.RawDatas.RSSBIdentifiers",                      
                        input + ".TWR.RawDatas.RSSAIdentifiers", input + ".TWR.RawDatas.RSSBIdentifiers",
                        output + ".RSSActiveStates", output + ".RSSActiveIdentifiers", output + ".RSSActive"); 
    
//  DebugTN("ConnectAMSCHSelectActiveRSS res: " + res);
   return;
	}   

if(rule == "ConnectAMSCHSetCSSStatuses") { 
		int res = dpConnect("connectAMSCHSetCSSStatuses", true, input,
                        output + ".Structureds.CSS.CSSA.PreStatus", output + ".Structureds.CSS.CSSB.PreStatus",                      
                        params + ".Input", params + ".Output" ); 
    
//  DebugTN("ConnectAMSCHSetCSSStatuses res: " + res);
                        
  return;
	}   

if(rule == "ConnectAMSCHSetRSSState") { 
		int res = dpConnect("connectAMSCHSetRSSState", true, input, output); 
    
//  DebugTN("ConnectAMSCHSetRSSState res: " + res);

  return;
	}   

if(rule == "ConnectAMSCHSetRSSLabel") { 
		int res = dpConnect("connectAMSCHSetRSSLabel", true, input + ".RSSActiveStates", input + ".RSSActiveIdentifiers", 
                        output, params + ".Input", params + ".Output"); 
    
//  DebugTN("ConnectAMSCHSetRSSLabel res: " + res);

  return;
	}   

if(rule == "ConnectAMSCHSetCADASMH") { 
//  DebugTN("ConnectAMSCHSetCADASMH input: " + input);
  
  int res1 = dpConnect("connectAMSCHSetCADASMH", true, input + ".CADAS1_MH1", input + ".CADAS1_MH2", output + ".Chain1.GlobalStatus.PreStatus"); 
//  DebugTN("ConnectAMSCHSetCADASMH res: " + res1);

  int res2 = dpConnect("connectAMSCHSetCADASMH", true, input + ".CADAS2_MH1", input + ".CADAS2_MH2", output + ".Chain2.GlobalStatus.PreStatus"); 
//  DebugTN("ConnectAMSCHSetCADASMH res: " + res2);
  
  return;
	}   

	if(rule == "ConnectCopyStringWithDelay")
	{
		dpConnect("connectCopyStringWithDelay", true, input, output, params + ".Delay", params + ".DelayedStatus");
		return;
	}


	DebugN("sgSpecificConnectionsLib.ctl; sgFwSpecificConnections; Connection Rule : " + rule + " not found for input : " + input + " and output : " + output);
	sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "fwConnect: Connect Rule : " + rule + " not found for input : " + input + " and output : " + output);

}

//------------------------ RULES CONNECTIONS ------------------------------

void dpConnectVOLATISRx(string input, string output, string rule, string params) {
    string vcxAActiveDP = input + ".VCXA.Active";
    string vcxBActiveDP = input + ".VCXB.Active";
    string vcxADP = input + ".VCXA.Rx*";
    string vcxBDP = input + ".VCXB.Rx*";
    string outputDP = output + ".Rx*";

    dyn_string vcxADPNames = dpNames(vcxADP);
    dyn_string vcxBDPNames = dpNames(vcxBDP);
    dyn_string outputDPNames = dpNames(outputDP);
  
    for (int i=1; i<=dynlen(vcxADPNames); i++) {
      dpConnect("connectVOLATISRx", true, 
                vcxAActiveDP, vcxADPNames[i], 
                vcxBActiveDP, vcxBDPNames[i], 
                outputDPNames[i] + PRE_STATUS_POSTFIX,
                params + ".Input", params + ".Output");
    }
}

void dpConnectVOLATISTx(string input, string output, string rule, string params) {
    string vcxAActiveDP = input + ".VCXA.Active";
    string vcxBActiveDP = input + ".VCXB.Active";
    string vcxADP = input + ".VCXA.Tx*Select";
    string vcxAStatusDP = input + ".VCXA.Tx*Status";
    string vcxBDP = input + ".VCXB.Tx*Select";
    string vcxBStatusDP = input + ".VCXB.Tx*Status";
    string outputDP = output + ".Tx*";
    string paramTxStatus = params + ".TxStatus";
    string paramTxSelect = params + ".TxSelect";

    dyn_string vcxADPNames = dpNames(vcxADP);
    dyn_string vcxAStatusDPNames = dpNames(vcxAStatusDP);
    dyn_string vcxBDPNames = dpNames(vcxBDP);
    dyn_string vcxBStatusDPNames = dpNames(vcxBStatusDP);
    dyn_string outputDPNames = dpNames(outputDP);
  
    for (int i=1; i<=dynlen(vcxADPNames); i++) {
      dpConnect("connectVOLATISTx", true, 
                vcxAActiveDP, vcxAStatusDPNames[i], vcxADPNames[i],
                vcxBActiveDP, vcxBStatusDPNames[i], vcxBDPNames[i],
                outputDPNames[i] + PRE_STATUS_POSTFIX,
                paramTxStatus + ".Input", paramTxStatus + ".Output", 
                paramTxSelect + ".Input", paramTxSelect + ".Output");
    }
}

void dpConnectCPDLCSITAATN(string input, string output, string rule, string params)
{
  string inputAtnAvailable = input + ".AtnAvailable";
  string inputAtnPriority = input + ".AtnPriority";
  dpConnect("connectCPDLCSITAATN", true, inputAtnAvailable, inputAtnPriority, output);
}

void dpConnectCPDLCATNStack(string input, string output, string rule, string params)
{
  string inputProcessName = input + ".ProcessName";
  string inputProcessState = input + ".ProcessState";
  dpConnect("connectCPDLCATNStack", true, inputProcessName, inputProcessState, output);
}

void dpConnectRDPARTASActiveChain (string input, string output, string rule, string params){
  string inputAPrim = input + ".APrim";
  string inputASec = input + ".ASec";
  string inputBPrim = input + ".BPrim";
  string inputBSec = input + ".BSec";
  int res=dpConnect("connectRDPARTASActiveChain", true, inputAPrim, inputASec, inputBPrim, inputBSec, output);
 // DebugTN("connectRDPARTASActiveChain; res= " + res);
}

void dpConnectRDPARTAS4Entries (string input, string output, string rule, string params){
  string activeChainDP = "RDP.RawData.ARTASComputedValue.ActiveChain";
  string primaryLANADP = "RDP.RawData.ARTASComputedValue.ISupSidePrimaryLANA";
  string secondaryLANADP = "RDP.RawData.ARTASComputedValue.ISupSideSecondaryLANA";
  string primaryLANBDP = "RDP.RawData.ARTASComputedValue.ISupSidePrimaryLANB";
  string secondaryLANBDP = "RDP.RawData.ARTASComputedValue.ISupSideSecondaryLANB";

  string APrimDP = input + ".APrim";
  string ASecDP = input + ".ASec";
  string BPrimDP = input + ".BPrim";
  string BSecDP = input + ".BSec";

  int res=dpConnect("connectRDPARTAS4Entries", true, APrimDP, ASecDP, BPrimDP, BSecDP, activeChainDP, 
            primaryLANADP, secondaryLANADP, primaryLANBDP, secondaryLANBDP, params + ".Input", params + ".Output", output);  
// DebugTN("connectRDPARTAS4Entries; res= " + res);
}

void dpConnectRDPARTASChainComponents(string input, string output, string rule, string params){
  string activeChainDP = "RDP.RawData.ARTASComputedValue.ActiveChain";
  string primaryLANADP = "RDP.RawData.ARTASComputedValue.ISupSidePrimaryLANA";
  string secondaryLANADP = "RDP.RawData.ARTASComputedValue.ISupSideSecondaryLANA";
  string primaryLANBDP = "RDP.RawData.ARTASComputedValue.ISupSidePrimaryLANB";
  string secondaryLANBDP = "RDP.RawData.ARTASComputedValue.ISupSideSecondaryLANB";

  string APrimDP = input + ".APrim";
  string ASecDP = input + ".ASec";
  string BPrimDP = input + ".BPrim";
  string BSecDP = input + ".BSec";

  string outputADP = output;
  strreplace(outputADP, "Chain[AB]", "ChainA");
                     
  string outputBDP = output;
  strreplace(outputBDP, "Chain[AB]", "ChainB");
  
  int res=dpConnect("connectRDPARTASChainComponents", true, APrimDP, ASecDP, activeChainDP, 
            primaryLANADP, secondaryLANADP, params + ".Input", params + ".Output", outputADP);  
// DebugTN("connectRDPARTASChainComponents I; res= " + res);

  
  int res=dpConnect("connectRDPARTASChainComponents", true, BPrimDP, BSecDP, activeChainDP, 
            primaryLANBDP, secondaryLANBDP, params + ".Input", params + ".Output", outputBDP);  
// DebugTN("connectRDPARTASChainComponents II; res= " + res);
}

void dpConnectRDPARTASUserLabel(string input, string output, string rule, string params){
  string activeChainDP = "RDP.RawData.ARTASComputedValue.ActiveChain";
  string primaryLANADP = "RDP.RawData.ARTASComputedValue.ISupSidePrimaryLANA";
  string secondaryLANADP = "RDP.RawData.ARTASComputedValue.ISupSideSecondaryLANA";
  string primaryLANBDP = "RDP.RawData.ARTASComputedValue.ISupSidePrimaryLANB";
  string secondaryLANBDP = "RDP.RawData.ARTASComputedValue.ISupSideSecondaryLANB";

  string APrimDP = input + ".APrim";
  string ASecDP = input + ".ASec";
  string BPrimDP = input + ".BPrim";
  string BSecDP = input + ".BSec";

  int res=dpConnect("connectRDPARTASUserLabel", true, APrimDP, ASecDP, BPrimDP, BSecDP, activeChainDP, 
            primaryLANADP, secondaryLANADP, primaryLANBDP, secondaryLANBDP, params + TEMPLATE_POSTFIX, output);  
 //  DebugTN("connectRDPARTASUserLabel; res= " + res);
}


void dpConnectRDPUsedChannel(string input, string output, string rule, string params){
  string channel1DP = input + ".Channel1" + STATUS_POSTFIX;
  string channel2DP = input + ".Channel2" + STATUS_POSTFIX;
  string channel3DP = input + ".Channel3" + STATUS_POSTFIX;
  string channel4DP = input + ".Channel4" + STATUS_POSTFIX;

  int res=dpConnect("connectRDPUsedChannel", true, channel1DP, channel2DP, channel3DP, channel4DP, output);  
//  DebugTN("dpConnectRDPUsedChannel; res= " + res + "; channel1DP:" + channel1DP );
}

void dpConnectRDPARTASNode(string input, string output, string rule, string params){
  string activeChainDP = "RDP.RawData.ARTASComputedValue.ActiveChain";
  string primaryDP;
  string secondaryDP;
  
  if (params == "A" || params == "B")
  {  
    primaryDP = "RDP.RawData.ARTASComputedValue.ISupSidePrimaryLAN" + params;
    secondaryDP = "RDP.RawData.ARTASComputedValue.ISupSideSecondaryLAN" + params;
  }
  else 
    DebugTN("dpConnectRDPARTASNode; Connection params not correctly defined");
  
  string nodeOperationalPrimDP = input + ".NodeOperational." + params + "Prim";
  string nodeOperationalSecDP = input + ".NodeOperational." + params + "Sec";
  string nodeRedundancyPrimDP = input + ".NodeRedundancy." + params + "Prim";
  string nodeRedundancySecDP = input + ".NodeRedundancy." + params + "Sec";

 int res=dpConnect("connectRDPARTASNode", true, nodeOperationalPrimDP, nodeOperationalSecDP, 
                   nodeRedundancyPrimDP, nodeRedundancySecDP, activeChainDP, primaryDP, secondaryDP, output);  
 //DebugTN("dpConnectRDPARTASNode; res= " + res + "; nodeOperationalPrimDP:" + nodeOperationalPrimDP );
}

void dpConnectRDPARTASRadarStatus (string input, string output, string rule, string params){
  string radarStatusDP = input + ".TmpStatus";
  string radarConnectDP = input + ".TmpConnect";
    
  int res=dpConnect("connectRDPARTASRadarStatus", true, radarStatusDP, radarConnectDP, output);  
  //DebugTN("connectRDPARTASRadarStatus; radarConnectDP= " + radarConnectDP);
}

void dpConnectRDPARTASRadarLabel (string input, string output, string rule, string params){
  string radarStatusDP = input + ".TmpStatus";
  string radarConnectDP = input + ".TmpConnect";
    
  int res=dpConnect("connectRDPARTASRadarLabel", true, radarStatusDP, radarConnectDP, output);  
  //DebugTN("dpConnectRDPARTASRadarLabel; radarConnectDP= " + radarConnectDP);
}
 
void dpConnectDCLLines(string input, string output, string rule, string params){
  string gatewayStatusADP = "DCL.Structureds.DCLGWAStatus.PreStatus";
  string gatewayStatusBDP = "DCL.Structureds.DCLGWBStatus.PreStatus";
    
  int res=dpConnect("connectDCLLine", true, gatewayStatusADP, gatewayStatusBDP, input + ".DCLGWA.ARINC", input + ".DCLGWB.ARINC", 
                    params + ".DCLGWLines.Input", params + ".DCLGWLines.Output", output + ".ARINC.PreStatus");  

  int res=dpConnect("connectDCLLine", true, gatewayStatusADP, gatewayStatusBDP, input + ".DCLGWA.SITA", input + ".DCLGWB.SITA", 
                    params + ".DCLGWLines.Input", params + ".DCLGWLines.Output", output + ".SITA.PreStatus");  

  int res=dpConnect("connectDCLLine", true, gatewayStatusADP, gatewayStatusBDP, input + ".DCLGWA.RECDATA_GVA", input + ".DCLGWB.RECDATA_GVA", 
                    params + ".DCLGWLines.Input", params + ".DCLGWLines.Output", output + ".RECDATA_GVA.PreStatus");  

  int res=dpConnect("connectDCLLine", true, gatewayStatusADP, gatewayStatusBDP, input + ".DCLGWA.RECDATA_ZRH", input + ".DCLGWB.RECDATA_ZRH", 
                    params + ".DCLGWLines.Input", params + ".DCLGWLines.Output", output + ".RECDATA_ZRH.PreStatus");  

  int res=dpConnect("connectDCLLine", true, gatewayStatusADP, gatewayStatusBDP, input + ".DCLGWA.SYLEX", input + ".DCLGWB.SYLEX", 
                    params + ".DCLGWSYLEX.Input", params + ".DCLGWSYLEX.Output", output + ".SYLEX.PreStatus");  
}

