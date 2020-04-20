// ISup specific connection rules

void iSupConnectSerialAgentStatus(string agentDPNamedAddressDp, dyn_int agentDPNamedAddressVal, 
                                  string agentDPNamedStatusesDp, dyn_int agentDPNamedStatusesVal, 
                                  string agentDPNamedInvalidDp, bool agentDPNamedInvalidVal,
                                  string destName, string destVal,
                                  string inpTableName, dyn_string inpTableVal,
                                  string outpTableName, dyn_string outpTableVal)
{
  string dpe = dpSubStr(destName, DPSUB_SYS_DP_EL);
  string value = UKN_STATUS;
//  DebugTN("iSupConnectSerialAgentStatus called");

  if (dynlen(agentDPNamedAddressVal) != dynlen(agentDPNamedStatusesVal)  || agentDPNamedInvalidVal == TRUE )  // case for WatchDog
  {
    value = U_S_STATUS;  // case for WatchDog
  }
  else
  {  
      int intValue = agentDPNamedStatusesVal[1];  //RS 232, only address 1
//      DebugTN("iSupConnectSerialAgentStatus intValue:" + intValue);
  
      value = getConvertTableValue(inpTableVal, outpTableVal, (string)intValue);
    }     
  if (destVal != value)
    sgConnectionDpSet(dpe, value);
}

void connectRecVoiceLoggerIDToDescription(string dpLoggerID, string LoggerID, string dpEventText, string eventText)
{
  string description;
  string oldDescription;
  string dpDescription;
  string strippedText;    
        
 // DebugTN("connectRecVoiceLoggerIDToDescription; eventText: " + eventText);
  dpDescription = sgStripDpName(dpEventText, EVENT_TEXT_POSTFIX);
  oldDescription = dpGetDescription(dpDescription);
  
  strippedText = substr(LoggerID,  strpos(LoggerID, "#") + 1); // Only the ID after # is interesting
  description = eventText + " (" + strippedText + ")";
//  DebugTN("connectRecVoiceLoggerIDToDescription; description: " + description);

  if(description == oldDescription)
    return;

  dpSetDescription(dpDescription, description);
        
}//connectRecVoiceLoggerIDToDescription
    
void connectWAGOWithConvertTable(
	string sourceName, int sourceVal,
	string destName, string destVal,
	string statusName, int statusVal,
	string inpTableName, dyn_string inpTableVal,
	string outpTableName, dyn_string outpTableVal)
{

	string dpe = dpSubStr(destName, DPSUB_SYS_DP_EL);
	string value = UKN_STATUS;

	if (statusVal == 3)
		value = getConvertTableValue(inpTableVal, outpTableVal, (string)sourceVal);

	if (destVal != value)
		sgConnectionDpSet(dpe, value);

}

void connectCTC(string inputName, string inputValue)
{
	// if the framework is not initialized, do nothing !
	if (!gInitFinished)
	{
		//DebugTN("Traps for CTC are ignored because the framework is not initialized");
		return;
	}

	// verify the config
	string rootName = substr(inputName, 0, strlen(inputName) - 32);
	//DebugTN("rootName: " + rootName);

	// slot number from the connection
	char slotNumber = inputName[strlen(inputName) - 17];
	// DebugTN("slot number: " + (string)slotNumber);

	// get slot received:
	int slotConfig;
	dpGet(rootName + ".RawConfig.Slot_" + slotNumber, slotConfig);
	// DebugTN("slot config received: " + slotConfigReceived);

	if (gCTCTablesLoaded == false)
	{
		sgCTCLoadTables();
		if (gCTCAlreadyConnected == false)
		{
			gCTCAlreadyConnected = true;
			dpConnect("sgCTCActiveChainChanged", "FwUtils.Framework.ActiveChain");
			// DebugTN("dpConnect");
		}
	}

	sgUpdateCTCSubComponent(rootName, slotConfig, slotNumber, inputValue);
}


void connectPRIMUS(string sourceName, string sourceVal, string destName, string destVal)
{
	string trueNameStatus;
	string trueNameMessage;
	string status;
	string message;

//	DebugTN("connectPRIMUS");


//	DebugN("connectPRIMUS(" + sourceName + "," + sourceVal + "," + destName + "," + destVal + ")");

	int spaceIndex = strpos(sourceVal, " ");

	status = substr(sourceVal, 0, spaceIndex);
	// if status is a label, remove _ and replace with spaces
	strreplace(status, "_", " ");
//	DebugN("writeStatusText; status: " + status);

	if(status == destVal)
	{
//		DebugN("connectPRIMUS exit without copying");
// Write only one time (dpConnect).
		return;
	}

	message = substr(sourceVal,spaceIndex + 1);
//	DebugN("message: " + message);

// Source name type		: System1:PRIMUS.Structured.ARTAS.GlobalStatus.PreStatus:...
// Destination name type: PRIMUS.Structured.ARTAS.GlobalStatus.PreStatus
//	trueNameStatus = substr(destName, strpos(destName, ":") + 1);
//	trueNameStatus = substr(trueNameStatus, 0, strpos(trueNameStatus, ":"));
//	DebugN("trueNameStatus: " + trueNameStatus);

	trueNameStatus = sgStripDpName(destName, "");

	// VL: replaced status postfix with pre status postfix on 6th of April 2003
	trueNameMessage = substr(trueNameStatus, 0, strpos(trueNameStatus, PRE_STATUS_POSTFIX));
	if(trueNameMessage != "") // messages can be present only for statuses, not for labels
	{
		trueNameMessage = trueNameMessage + MESSAGE_POSTFIX;
		// Writing new value in destination for message
		sgConnectionDpSet(trueNameMessage, message);
	}


//	DebugN("trueNameMessage: " + trueNameMessage);


// Writing new value in destination for Status
//	DebugN("connectPRIMUS will write " + status + " in " + trueNameStatus);
	sgConnectionDpSet(trueNameStatus, status);
}

void connectVOLATISRx(
  string vcxAActiveDP, int vcxAActive, 
  string vcxARxTxDP, int vcxARxTx, 
  string vcxBActiveDP, int vcxBActive, 
  string vcxBRxTxDP, int vcxBRxTx,
  string outputDP, string output,
  string convInputDP, dyn_string convInputs,
  string convOutputDP, dyn_string convOutputs) {

  int rawStatus = -1;
  string status;
  string outputDPName = dpSubStr(outputDP, DPSUB_SYS_DP_EL);
   
  if (vcxAActive == 1) {
    rawStatus = vcxARxTx;
  } else if (vcxBActive == 1) {
    rawStatus = vcxBRxTx;
  }

  status = getConvertTableValue(convInputs, convOutputs, rawStatus);

  if (output != status) {
    sgConnectionDpSet(outputDPName, status);
  }
  
}

void connectVOLATISTx(
  string vcxAActiveDP, int vcxAActive, 
  string vcxATxStatusDP, int vcxATxStatus, 
  string vcxATxSelectDP, int vcxATxSelect, 
  string vcxBActiveDP, int vcxBActive, 
  string vcxBTxStatusDP, int vcxBTxStatus, 
  string vcxBTxSelectDP, int vcxBTxSelect,
  string outputDP, string output,
  string convInputStatusDP, dyn_string convInputsStatus,
  string convOutputStatusDP, dyn_string convOutputsStatus,
  string convInputSelectDP, dyn_string convInputsSelect,
  string convOutputSelectDP, dyn_string convOutputsSelect) {

  int rawStatus = -1;
  int rawSelect = -1;
  string status, select;
  string result = "UKN";
  string outputDPName = dpSubStr(outputDP, DPSUB_SYS_DP_EL);
   
  if (vcxAActive == 1) {
    rawStatus = vcxATxStatus;
    rawSelect = vcxATxSelect;
  } else if (vcxBActive == 1) {
    rawStatus = vcxBTxStatus;
    rawSelect = vcxBTxSelect;
  }

  status = getConvertTableValue(convInputsStatus, convOutputsStatus, rawStatus);
  select = getConvertTableValue(convInputsSelect, convOutputsSelect, rawSelect);

  if (status == "OPS") {
    result = select;
  } else if (status == "U/S") {
    result = "U/S";
  }
  
  if (output != result) {
    sgConnectionDpSet(outputDPName, result);
  }
  
}

void connectCPDLCSITAATN( string inputAvailableDp, int AtnAvailableValue, string inputPriorityDp, int AtnPriorityValue, string outputDP, string output)
{
  string outputDPName = dpSubStr(outputDP, DPSUB_SYS_DP_EL);
  string status; 

  if  (AtnAvailableValue == 2 && AtnPriorityValue == 1)
    status = OPS_STATUS;
  else if  (AtnAvailableValue == 1)
    status = U_S_STATUS;
  else if  (AtnAvailableValue == 2 && AtnPriorityValue == 2)
    status = DEG_STATUS;
  else
    status = UKN_STATUS;

  if (output != status) {
    sgConnectionDpSet(outputDPName, status);
  }  
}  

void connectCPDLCATNStack( string inputProcessNameDp, dyn_string inputProcessNameValues, string inputProcessStateDp, dyn_int inputProcessStateValues, string outputDP, string output)
{
  string outputDPName = dpSubStr(outputDP, DPSUB_SYS_DP_EL);
  string status; 

  if (dynlen(inputProcessNameValues) == 1 && inputProcessStateValues[1] == -1)
    status = SBY_STATUS;
  else if (dynlen(inputProcessNameValues) < 2)
    status = UKN_STATUS;
  else if (inputProcessNameValues[1] == "idrp" && inputProcessStateValues[1] == 1 &&
      inputProcessNameValues[2] == "lower" && inputProcessStateValues[2] == 1)
    status = OPS_STATUS;
  else
    status = U_S_STATUS;
  
  if (output != status) {
    sgConnectionDpSet(outputDPName, status);
  }  
}  

void connectRDPARTASActiveChain(string inputAPrimDP, int inputAPrimValue, 
                                string inputASecDP, int inputASecValue, 
                                string inputBPrimDP, int inputBPrimValue, 
                                string inputBSecDP, int inputBSecValue, 
                                string outputDP, string outputvalue){
  string outputDPName = dpSubStr(outputDP, DPSUB_SYS_DP_EL);
  string status; 
  // 2 principal
 if (inputAPrimValue == 2 ||inputASecValue == 2)
    status = "A";
 else if (inputBPrimValue == 2 ||inputBSecValue == 2 )
    status = "B";
 // 3 single
 else if (inputAPrimValue == 3 ||inputASecValue == 3)
    status = "A";
 else if (inputBPrimValue == 3 ||inputBSecValue == 3 )
    status = "B";
 else
   status = "-";
 
  if (outputvalue != status) {
    sgConnectionDpSet(outputDPName, status);
  }  
}  

void connectRDPARTAS4Entries(string APrimDP, int APrimValue, string ASecDP, int ASecValue, 
                    string BPrimDP, int BPrimValue, string BSecDP, int BSecValue, 
                    string activeChainDP, string activeChainValue, 
                    string primaryDPA, string primaryValueA,
                    string secondaryDPA, string secondaryValueA,
                    string primaryDPB, string primaryValueB,
                    string secondaryDPB, string secondaryValueB,
                    string convInputStatusDP, dyn_string convInputsStatus,
                    string convOutputStatusDP, dyn_string convOutputsStatus,
                    string outputDP, string outputvalue){
//  DebugTN("connectRDPARTAS4Entries called");  
  string outputDPName = dpSubStr(outputDP, DPSUB_SYS_DP_EL);
  string status; 
  int rawStatus;
  
  if (activeChainValue == "A")
    if (isOPS(primaryValueA))
      rawStatus = APrimValue;
    else if (isOPS(secondaryValueA))
      rawStatus = ASecValue;
    else // case no LAN
      rawStatus = 0; //0 -> UKN
  else //  case "B" or "-"
  if (isOPS(primaryValueB))
    rawStatus = BPrimValue;
  else  if (isOPS(secondaryValueB))
    rawStatus = BSecValue;
    else // case no LAN
      rawStatus = 0; //0 -> UKN
      
 status = getConvertTableValue(convInputsStatus, convOutputsStatus, rawStatus);
 
 if (outputvalue != status) {
    sgConnectionDpSet(outputDPName, status);
  }  
}  

void connectRDPARTASChainComponents(string PrimDP, int PrimValue, string SecDP, int SecValue, 
                    string activeChainDP, string activeChainValue, 
                    string primaryDP, string primaryValue,
                    string secondaryDP, string secondaryValue,
                    string convInputStatusDP, dyn_string convInputsStatus,
                    string convOutputStatusDP, dyn_string convOutputsStatus,
                    string outputDP, string outputvalue){
//  DebugTN("connectRDPARTASChainComponents called");  
  string outputDPName = dpSubStr(outputDP, DPSUB_SYS_DP_EL);
  bool isChainAComponent = false; 
  bool isChainBComponent = false; 
  string status; 
  int rawStatus;

  if (isOPS(primaryValue))
    rawStatus = PrimValue;
  else if (isOPS(secondaryValue))
    rawStatus = SecValue;
  else 
    rawStatus = 0; //0 -> UKN
  
  status = getConvertTableValue(convInputsStatus, convOutputsStatus, rawStatus);
  
// get on what chain is this component
  if (strpos(outputDPName , "ChainA") >= 0)
    isChainAComponent = true;
  if (strpos(outputDPName , "ChainB") >= 0)
    isChainBComponent = true;
    
 // if ok and not active chain -> status SBY
  if (isOPS(status) && (((activeChainValue == "A") && !isChainAComponent )|| ((activeChainValue == "B") && !isChainBComponent )))
    status = SBY_STATUS;
    
 if (outputvalue != status) {
    sgConnectionDpSet(outputDPName, status);
  }  
}  

void connectRDPARTASUserLabel(string APrimDP, int APrimValue, string ASecDP, int ASecValue, 
                    string BPrimDP, int BPrimValue, string BSecDP, int BSecValue, 
                    string activeChainDP, string activeChainValue, 
                    string primaryDPA, string primaryValueA,
                    string secondaryDPA, string secondaryValueA,
                    string primaryDPB, string primaryValueB,
                    string secondaryDPB, string secondaryValueB,
                    string templateName, string templateVal,
                    string outputDP, string outputvalue){
//  DebugTN("dpConnectRDPARTASUserLabel called");  
  string outputDPName = dpSubStr(outputDP, DPSUB_SYS_DP_EL);
  string label; 
  string rawLabel;
  
  if (activeChainValue == "A")
    if (isOPS(primaryValueA))
      rawLabel = APrimValue;
    else if (isOPS(secondaryValueA))
      rawLabel = ASecValue;
    else // case no LAN
      rawLabel = 0; //0 -> UKN
  else //  case "B" or "-"
  if (isOPS(primaryValueB))
    rawLabel = BPrimValue;
  else  if (isOPS(secondaryValueB))
    rawLabel = BSecValue;
    else // case no LAN
      rawLabel = 0; //0 -> UKN
      
  label = templateVal;
  strreplace(label, "%X", rawLabel);
 
 if (outputvalue != label) {
    sgConnectionDpSet(outputDPName, label);
  }  
}      

void connectRDPUsedChannel(string channel1DP, string channel1Status, 
                           string channel2DP, string channel2Status, 
                           string channel3DP, string channel3Status, 
                           string channel4DP, string channel4Status, 
                           string outputDP, string output){
  string outputDPName = dpSubStr(outputDP, DPSUB_SYS_DP_EL);
  string usedChannel; //panel radar use string type

  if (isOPS(channel1Status))
    usedChannel = "1";
  else if (isOPS(channel2Status))
    usedChannel = "2";
  else if (isOPS(channel3Status))
    usedChannel = "3";
  else if (isOPS(channel4Status))
    usedChannel = "4";
  else
    usedChannel = "0";  
  
  if (output != usedChannel) {
    sgConnectionDpSet(outputDPName, usedChannel);
  }  
}  

void connectRDPARTASNode(string nodeOperationalPrimDP, int nodeOperationalPrimValue, 
                          string nodeOperationalSecDP, int nodeOperationalSecValue, 
                          string nodeRedundancyPrimDP, int nodeRedundancyPrimValue, 
                          string nodeRedundancySecDP, int nodeRedundancySecValue, 
                          string activeChainDP, string activeChainValue, 
                          string primaryDP, string primaryValue,
                          string secondaryDP, string secondaryValue,
                          string outputDP, string outputvalue){        
  string outputDPName = dpSubStr(outputDP, DPSUB_SYS_DP_EL);
  string status; 
  int nodeOperational;
  int nodeRedundancy;
    
  if (isOPS(primaryValue) || isDEG(primaryValue))  {    
    nodeOperational = nodeOperationalPrimValue;
    nodeRedundancy = nodeRedundancyPrimValue;
  } else if (isOPS(secondaryValue) || isDEG(secondaryValue)){    
    nodeOperational = nodeOperationalSecValue;
    nodeRedundancy = nodeRedundancySecValue;
  } else{    
    nodeOperational = 0;
    nodeRedundancy = 0;
  }  
  if (nodeOperational == 1 || nodeOperational == 4)
    status = STP_STATUS;
  else if (nodeOperational == 2 && (nodeRedundancy == 2 || nodeRedundancy == 3))
    status = OPS_STATUS;
  else if (nodeOperational == 2 && (nodeRedundancy == 4 || nodeRedundancy == 5))
    status = SBY_STATUS;
  else if (nodeOperational == 3)
    status = INI_STATUS;
  else if (nodeOperational == 5)
    status = U_S_STATUS;
  else
    status = UKN_STATUS;
      
  if (outputvalue != status) {
    sgConnectionDpSet(outputDPName, status);
  }  
}  

void connectRDPARTASRadarStatus(string radarStatusDP, string radarStatusValue, 
                          string radarConnectDP, string radarConnectDPValue, 
                          string outputDP, string outputvalue){        
 
  string outputDPName = dpSubStr(outputDP, DPSUB_SYS_DP_EL);
  string status; 
  
  if (radarConnectDPValue == "disconnect")
    status = STP_STATUS;
  else if (radarStatusValue == OPS_STATUS)
    status = radarStatusValue;
  else if (radarStatusValue == U_S_STATUS)
    status = radarStatusValue;
  else if (radarStatusValue == INI_STATUS)
    status = radarStatusValue;
  else
    status = radarStatusValue;   
        
  if (outputvalue != status) {
    sgConnectionDpSet(outputDPName, status);
  }  
}  

void connectRDPARTASRadarLabel(string radarStatusDP, string radarStatusValue, 
                          string radarConnectDP, string radarConnectDPValue, 
                          string outputDP, string outputvalue){        

  string outputDPName = dpSubStr(outputDP, DPSUB_SYS_DP_EL);
  string label;    
  
  if (radarConnectDPValue == "disconnect")
    label = "disconnect";
  else if (radarStatusValue == OPS_STATUS)
    label = "operational";
  else if (radarStatusValue == U_S_STATUS)
    label = "failed";
  else if (radarStatusValue == INI_STATUS)
    label = "init";
  else
    label = "-";
        
  if (outputvalue != label) {
    sgConnectionDpSet(outputDPName, label);
  }  
}  

void connectDCLLine(string gatewayStatusADP, string gatewayStatusADPValue, 
                          string gatewayStatusBDP, string gatewayStatusBDPValue, 
                          string inputADP, string inputAValue, 
                          string inputBDP, string inputBValue, 
                          string convInputStatusDP, dyn_string convInputsStatus,
                          string convOutputStatusDP, dyn_string convOutputsStatus,
                          string outputDP, string outputValue){
 // DebugTN("connectDCLLine called");  
  string outputDPName = dpSubStr(outputDP, DPSUB_SYS_DP_EL);
  string status; 
  int rawStatus;

  if (isOPS(gatewayStatusADPValue))
    rawStatus = inputAValue;
  else if (isOPS(gatewayStatusBDPValue))
    rawStatus = inputBValue;
  else 
    rawStatus = 0; //0 -> UKN
  
  status = getConvertTableValue(convInputsStatus, convOutputsStatus, rawStatus);
   
 if (outputValue != status) {
    sgConnectionDpSet(outputDPName, status);
  }  
}  

void connectSmartRadioDescriptionMessage(string dataDP, string dataValue,
                                          string outputDP, string outputValue){

//  DebugTN("connectSmartRadioDescriptionMessage called");  
//  DebugTN("dataDP: " + dataDP);  
  string outputDPName = dpSubStr(outputDP, DPSUB_SYS_DP_EL);
  
  dyn_string ds = strsplit(dataValue, ";");

  if (dynlen(ds) < 6) {
    return;
  }
  
  string  message = ds[3] + " " + ds[4] + " " + ds[5] + " " + ds[6];
//  DebugTN("connectSmartRadioDescriptionMessage; message: " + message);  
    
  if (outputValue != message) {
    sgConnectionDpSet(outputDPName, message);
  }  
}

void connectSplitTACOTraps(string dataDP, string dataValue,
                              string outputDP, string outputValue,
                              string inpTableName, dyn_string inpTableVal,
                              string outpTableName, dyn_string outpTableVal) {
  //Format of Trap: zstactexp02-TACO-HM3UPKP Major reason: reporting status ...
  
    string outputDPName = dpSubStr(outputDP, DPSUB_SYS_DP_EL);
    string outputDPName2;
    string hostName;
    
  if(dataValue != "0") // 0 = WatchDogs do nothing
  {
    dyn_string ds = strsplit(dataValue, "-");
    dyn_string ds2 = strsplit(ds[3], " ");
    string objectName = ds2[1];
    string severity = ds2[2];
    
    if (objectName == "SLAVE")  // slave status come from master 
    {
      string hostNameFromTACO = ds[1];   
      int index = dynContains(inpTableVal, hostNameFromTACO);

      if (index <= 0) 
        DebugTN("connectSplitTACOTraps: hostName in trap doesn't match in TACOHostMatching table for traps: " + dataValue);

      string genericHostname = outpTableVal[index];
      dyn_string dpNameSplit = strsplit(outputDPName, ".");
      for (int i=1; i <= (dynlen(dpNameSplit)-2); i++)
      {
        if (i == 1)
          outputDPName2 = dpNameSplit[i];
        else  
          outputDPName2 = outputDPName2 + "." + dpNameSplit[i]; 
      }
    outputDPName2 = outputDPName2 + "." + genericHostname + "." + objectName;
    }
    else{
      outputDPName2 = outputDPName;      
      strreplace(outputDPName2, ".LDR", "");  
      outputDPName2 = outputDPName2 + "." + objectName;
    }
    if(dpExists(outputDPName2) ){
      if( outputDPName == outputDPName2) {
        if (outputValue != severity) {
          sgConnectionDpSet(outputDPName2, severity);
        }
      }else
        sgConnectionDpSet(outputDPName2, severity);  
    }  
    else 
      DebugTN("connectSplitTACOTraps: outputDPName2: " + outputDPName2 + " doesn't exist for traps: " + dataValue);
  }
  else
  {
    if (outputValue != "0")  // case of watchdog
      sgConnectionDpSet(outputDPName, "0");

  }  
}// connectSplitTACOTraps


void connectTELGATE2Components(string sourceNameA, int sourceValA, string sourceNameB, int sourceValB, 
                               string destName, string destVal, string paramsName, dyn_string dsParams)
{
	string formattedValue;
	string destFormattedName;
  int OPSValueA = dsParams[2];
  int OPSValueB = dsParams[4];

//	DebugN("ConnectTELGATE2Components for: sourceValA:" + sourceValA + " sourceValB:" + sourceValB + " OPSValueA:" + OPSValueA +" OPSValueB:" + OPSValueB);
  
  
  
  if (sourceValA == OPSValueA && sourceValB == OPSValueB)
    formattedValue = OPS_STATUS;	
  else if (sourceValA == OPSValueA || sourceValB == OPSValueB)
    formattedValue = DEG_STATUS;	
  else if (sourceValA == (-1) && sourceValB == (-1)) // -1 -> WatchDog
    formattedValue = UKN_STATUS;	
  else 
    formattedValue = U_S_STATUS;	
  
  if(destVal != formattedValue)
	{
		destFormattedName = dpSubStr(destName, DPSUB_SYS_DP_EL);

//  	DebugN("ConnectTELGATE2Components for: formattedValue: " + formattedValue);
		dpSet(destFormattedName, formattedValue);
	}
	else
	{
//		DebugN("Conversion to structured done before. No dpSet for: " + destFormattedName);
	}
}

void connectTELGATE2Lines(string sourceNameA, int sourceValA, string sourceNameB, int sourceValB, 
                               string destName, string destVal, string paramsName, dyn_string dsParams)
{
	string formattedValue;
	string destFormattedName;
  int OPSValueA = dsParams[2];
  int OPSValueB = dsParams[4];

//	DebugN("connectTELGATE2Lines for: sourceValA:" + sourceValA + " sourceValB:" + sourceValB + " OPSValueA:" + OPSValueA +" OPSValueB:" + OPSValueB);
  
  if (sourceValA == OPSValueA && sourceValB == OPSValueB)
    formattedValue = OPS_STATUS;	
  else if (sourceValA == (-1) && sourceValB == (-1)) // -1 -> WatchDog
    formattedValue = UKN_STATUS;	
  else 
    formattedValue = U_S_STATUS;	
  
  if(destVal != formattedValue)
	{
		destFormattedName = dpSubStr(destName, DPSUB_SYS_DP_EL);

//  	DebugN("connectTELGATE2Lines for: formattedValue: " + formattedValue);
		dpSet(destFormattedName, formattedValue);
	}
	else
	{
//		DebugN("Conversion to structured done before. No dpSet for: " + destFormattedName);
	}
}


void connectTELGATE4Components(string sourceNameA, int sourceValA, string sourceNameB, int sourceValB, 
                               string sourceNameC, int sourceValC, string sourceNameD, int sourceValD, 
                               string destName, string destVal, string paramsName, dyn_string dsParams){
  string formattedValue;
  string destFormattedName;
  int OPSValueA = dsParams[2];
  int OPSValueB = dsParams[4];
  int OPSValueC = dsParams[6];
  int OPSValueD = dsParams[8];
	//DebugN("connectTELGATE4Components for: sourceValA:" + sourceValA + " sourceValB:" + sourceValB + " OPSValueA:" + OPSValueA +" OPSValueB:" + OPSValueB);
  
  if (sourceValA == OPSValueA && sourceValB == OPSValueB && sourceValC == OPSValueC && sourceValD == OPSValueD)
    formattedValue = OPS_STATUS;	
  else if (sourceValA == OPSValueA || sourceValB == OPSValueB || sourceValC == OPSValueC || sourceValD == OPSValueD)
    formattedValue = DEG_STATUS;	
  else if (sourceValA == (-1) && sourceValB == (-1) && sourceValC == (-1) && sourceValD == (-1)) // -1 -> WatchDog
    formattedValue = UKN_STATUS;	
  else 
    formattedValue = U_S_STATUS;	
  
  if(destVal != formattedValue)
	{
		destFormattedName = dpSubStr(destName, DPSUB_SYS_DP_EL);

//  	DebugN("connectTELGATE4Components for: formattedValue: " + formattedValue);
		dpSet(destFormattedName, formattedValue);
	}
	else
	{
//		DebugN("Conversion to structured done before. No dpSet for: " + destFormattedName);
	}
}

void connectTELGATESBCEsip(string input_1DP, int input_1Value, 
                          string input_2DP, int input_2Value, 
                          string outputDP, string outputValue){
//  DebugTN("connectTELGATESBCEsip called");  
  string outputDPName = dpSubStr(outputDP, DPSUB_SYS_DP_EL);

  string status; 
  int rawStatus;

  if (input_1Value == 3 && input_2Value == 3 )  // 3: InService
    status = OPS_STATUS;
  else if (input_1Value == 3 || input_2Value == 3 ) // 3: InService
    status = DEG_STATUS;
  else if (input_1Value == -1 && input_2Value == -1 ) // -1: WatchDog
    status = UKN_STATUS;
  else 
    status = U_S_STATUS;
    
 if (outputValue != status) {
    sgConnectionDpSet(outputDPName, status);
  }  
}

void connectEMRADIOStatus(string inputDP, string inputStatus,
                          string outputDP, string outputValue){

	string outputDPName = dpSubStr(outputDP, DPSUB_SYS_DP_EL);
	string status; 
	dyn_string rawStatus = strsplit(inputStatus, ",");

	if (dynlen(rawStatus) == 3 && rawStatus[2] == 1 && rawStatus[3] == 0)
		status = OPS_STATUS;
	else if (dynlen(rawStatus) == 3 && rawStatus[2] == 1 && rawStatus[3] == 1)
		status = DEG_STATUS;
	else if (dynlen(rawStatus) == 3)
		status = U_S_STATUS;
	else 
		status = UKN_STATUS;

	if (outputValue != status) {
		sgConnectionDpSet(outputDPName, status);
	}  
}  

void connectEMRADIODescriptionMessage(string LocalInfoDP, string LocalInfoValue,
                                      string StationDP, string StationValue,
                                      string FrequencyDP, string FrequencyValue,
                                      string RadioIDDP, string RadioIDValue,
                                      string outputDP, string outputValue){

  string outputDPName = dpSubStr(outputDP, DPSUB_SYS_DP_EL);

  string  message = FrequencyValue + " - " + StationValue + " - " + RadioIDValue + " - " + LocalInfoValue;
  
  if (outputValue != message) {
    sgConnectionDpSet(outputDPName, message);
  }
}


void connectAMSCHSelectActiveRSS(string inputLTRSSAStatesDp, dyn_int inputLTRSSAStates,
                                  string inputLTRSSBStatesDp, dyn_int inputLTRSSBStates,
                                  string inputTWRRSSAStatesDp, dyn_int inputTWRRSSAStates, 
                                  string inputTWRRSSBStatesDp, dyn_int inputTWRRSSBStates, 
                                  string inputLTRSSAIdentifiersDp, dyn_string inputLTRSSAIdentifiers,
                                  string inputLTRSSBIdentifiersDp, dyn_string inputLTRSSBIdentifiers,
                                  string inputTWRRSSAIdentifiersDp, dyn_string inputTWRRSSAIdentifiers, 
                                  string inputTWRRSSBIdentifiersDp, dyn_string inputTWRRSSBIdentifiers, 
                                  string outputActiveStatesDp, dyn_int outputActiveStates, 
                                  string outputActiveIdentifiersDp, dyn_string outputActiveIdentifiers, 
                                  string outputRSSActiveNameDp, string outputRSSActiveName){
   
  string outputStatesDPName = dpSubStr(outputActiveStatesDp, DPSUB_SYS_DP_EL);
  string outputIdentifiersDPName = dpSubStr(outputActiveIdentifiersDp, DPSUB_SYS_DP_EL);
  dyn_int RSSStates = makeDynInt("0");
  dyn_string RSSIdentifiers = makeDynString("-");
  
  string outputRSSActiveNameDPName = dpSubStr(outputRSSActiveNameDp, DPSUB_SYS_DP_EL);
  string outputRSSActiveNameToWrite = "ConnectAMSCHSelectActiveRSS; No CSS Active";
	
//  DebugTN("ConnectAMSCHSelectActiveRSS called; dynContains(inputTWRRSSBStates, 7) ==0  " + (dynContains(inputTWRRSSBStates, 7) ));    
//  DebugTN("ConnectAMSCHSelectActiveRSS called; dynContains(inputTWRRSSBStates, 0)  ==0  " + (dynContains(inputTWRRSSBStates, 0)) );      
  
  if((dynContains(inputLTRSSAStates, 7)  == 0) && (dynContains(inputLTRSSAStates, 0) == 0 )){  // "" 7: unknown COMSOFT 0: unknown skyguide (WD)
    RSSStates = inputLTRSSAStates;
    RSSIdentifiers = inputLTRSSAIdentifiers;
    outputRSSActiveNameToWrite = dpSubStr(inputLTRSSAStatesDp, DPSUB_SYS_DP_EL);}

  if((dynContains(inputLTRSSBStates, 7)  == 0) && (dynContains(inputLTRSSBStates, 0) == 0 )){// 7: unknown COMSOFT 0: unknown skyguide (WD)
    RSSStates = inputLTRSSBStates;
    RSSIdentifiers = inputLTRSSBIdentifiers;
    outputRSSActiveNameToWrite = dpSubStr(inputLTRSSBStatesDp, DPSUB_SYS_DP_EL);}

  if((dynContains(inputTWRRSSAStates, 7)  == 0) && (dynContains(inputTWRRSSAStates, 0) == 0 )){// 7: unknown COMSOFT 0: unknown skyguide (WD)
    RSSStates = inputTWRRSSAStates;
    RSSIdentifiers = inputTWRRSSAIdentifiers;
    outputRSSActiveNameToWrite = dpSubStr(inputTWRRSSAStatesDp, DPSUB_SYS_DP_EL);}

  if((dynContains(inputTWRRSSBStates, 7)  == 0) && (dynContains(inputTWRRSSBStates, 0) == 0 )){// 7: unknown COMSOFT 0: unknown skyguide (WD)
    RSSStates = inputTWRRSSBStates;
    RSSIdentifiers = inputTWRRSSBIdentifiers;
    outputRSSActiveNameToWrite = dpSubStr(inputTWRRSSBStatesDp, DPSUB_SYS_DP_EL);}
  
//  DebugTN("ConnectAMSCHSelectActiveRSS called; RSSStates " + RSSStates);  
//  DebugTN("ConnectAMSCHSelectActiveRSS called; outputActiveStates " + outputActiveStates);  

	if (outputActiveStates != RSSStates) {
    dpSet(outputStatesDPName, RSSStates);}

	if (outputActiveIdentifiers != RSSIdentifiers) {
    dpSet(outputIdentifiersDPName, RSSIdentifiers);}
 
  
//  DebugTN("ConnectAMSCHSelectActiveRSS called; outputRSSActiveNameToWrite: " + outputRSSActiveNameToWrite );      
  
  if (outputRSSActiveNameToWrite != outputRSSActiveName) {
    sgConnectionDpSet(outputRSSActiveNameDPName, outputRSSActiveNameToWrite);}
}  

void connectAMSCHSelectActiveCSS(string inputCSSAStatesDp, dyn_int inputCSSAStates,
                                  string inputCSSBStatesDp, dyn_int inputCSSBStates,
                                  string inputCSSAUpTimeDp, int inputCSSUpTimeAStates,
                                  string inputCSSBUpTimeDp, int inputCSSUpTimeBStates,
                                  string outputActiveStatesDp, dyn_int outputActiveStates, 
                                  string outputCSSActiveNameDp, string outputCSSActiveName){
   
  string outputDPName = dpSubStr(outputActiveStatesDp, DPSUB_SYS_DP_EL);
  dyn_int CSSStates = makeDynInt("0", "0");
  
  string outputCSSActiveNameDPName = dpSubStr(outputCSSActiveNameDp, DPSUB_SYS_DP_EL);
  string outputCSSActiveNameToWrite = "ConnectAMSCHSelectActiveCSS; No CSS Active";
	
//  DebugTN("ConnectAMSCHSelectActiveCSS called; dynContains(inputTWRCSSBStates, 7) ==0  " + (dynContains(inputTWRCSSBStates, 7) ));    
//  DebugTN("ConnectAMSCHSelectActiveCSS called; dynContains(inputTWRCSSBStates, 0)  ==0  " + (dynContains(inputTWRCSSBStates, 0)) );      
  
  
  if((dynContains(inputCSSAStates, 7) == 0) && (dynContains(inputCSSAStates, 0) == 0 )){  // "" 7: unknown COMSOFT 0: unknown skyguide (WD)
    CSSStates = inputCSSAStates;
    outputCSSActiveNameToWrite = dpSubStr(inputCSSAStatesDp, DPSUB_SYS_DP_EL);}
  else if((dynContains(inputCSSBStates, 7) == 0) && (dynContains(inputCSSBStates, 0) == 0 )){// 7: unknown COMSOFT 0: unknown skyguide (WD)
    CSSStates = inputCSSBStates;
    outputCSSActiveNameToWrite = dpSubStr(inputCSSBStatesDp, DPSUB_SYS_DP_EL);}
 
    
  if((inputCSSAStates[1] == 0) && (inputCSSUpTimeAStates != 0))  // case of no answer of CSS but machine SysUptime ok
    CSSStates [1] = 99;
    
  if((inputCSSBStates[1] == 0) && (inputCSSUpTimeBStates != 0))  // case of no answer of CSS but machine SysUptime ok
    CSSStates [2] = 99;

//  DebugTN("ConnectAMSCHSelectActiveCSS called; CSSStates " + CSSStates);  
//  DebugTN("ConnectAMSCHSelectActiveCSS called; outputActiveStates " + outputActiveStates);  

  if (outputActiveStates != CSSStates) {
    dpSet(outputDPName, CSSStates);}

//  DebugTN("ConnectAMSCHSelectActiveCSS called; outputCSSActiveNameToWrite: " + outputCSSActiveNameToWrite );      
  
  if (outputCSSActiveNameToWrite != outputCSSActiveName) {
    sgConnectionDpSet(outputCSSActiveNameDPName, outputCSSActiveNameToWrite);}
}  

void connectAMSCHSetRSSState(string inputDP, dyn_int inputValue, string outputDP, string outputValue){
//  DebugTN("connectAMSCHSetRSSState called; inputValue " + inputValue);  

  string outputDPName = dpSubStr(outputDP, DPSUB_SYS_DP_EL);
  string status; 
  int rawStatus;
  int count1;
  int count2;

  for(int i = 1; i <= dynlen(inputValue); i++)
  {
    if(inputValue[i] == 1)  //OP+
      count1 ++;
    if(inputValue[i] == 2)  //OP-
      count2 ++; 
  }  

//  DebugTN("connectAMSCHSetRSSState called; count1: " + count1);  
//  DebugTN("connectAMSCHSetRSSState called; count2: " + count2);  
 if ((count1 == 2) && (count2 >= 1))  /// Normal case 2 x OP+ and at least 1 OP-
    status = OPS_STATUS;
  else if ( (count1 >= 1) || (count2 >= 1) )
    status =  DEG_STATUS;
  else if ((dynlen(inputValue) == 1) && (inputValue[1] == 0)) // WD
    status = UKN_STATUS; 
  else
    status = U_S_STATUS; 
  
 if (outputValue != status) {
    sgConnectionDpSet(outputDPName, status);
  }  
}      

void connectAMSCHSetRSSLabel(string inputStatesDP, dyn_int inputStatesValue, 
                             string inputIdDP, dyn_string inputIdValue,
                             string outputDP, string outputValue,   
                             string convInputStatusDP, dyn_string convInputsStatus,
                              string convOutputStatusDP, dyn_string convOutputsStatus){
//  DebugTN("connectAMSCHSetRSSLabel called; inputStatesValue " + inputStatesValue);  

//  DebugTN("connectAMSCHSetRSSLabel called; inputIdValue " + inputIdValue);  

  string outputDPName = dpSubStr(outputDP, DPSUB_SYS_DP_EL);
  string label = "" ; 
  bool isFirstElement = true; 

  for(int i = 1; i <= dynlen(inputIdValue); i++)
  {
    if(inputIdValue[i] != "0" || inputIdValue[i] != "") 
    {
      if (isFirstElement)
      {
        
        label = inputIdValue[i] + ":" + getConvertTableValue(convInputsStatus, convOutputsStatus, inputStatesValue[i]);   
        isFirstElement = false;
      }
      else
        label = label + ", " + inputIdValue[i] + ":" + getConvertTableValue(convInputsStatus, convOutputsStatus, inputStatesValue[i]);   
    }
  }  
  
//  DebugTN("connectAMSCHSetRSSLabel called; label: " + label);  
  if (outputValue != label) {
    sgConnectionDpSet(outputDPName, label);
  }  
}      

void connectAMSCHSetCSSStatuses(string inputDP, dyn_string inputCSSStates,
                                string outputDP1, string outputValue1,
                                string outputDP2, string outputValue2,
                                string convInputStatusDP, dyn_string convInputsStatus,
                                string convOutputStatusDP, dyn_string convOutputsStatus){
 
  string outputDPName1 = dpSubStr(outputDP1, DPSUB_SYS_DP_EL);
  string outputDPName2 = dpSubStr(outputDP2, DPSUB_SYS_DP_EL);
  dyn_string CSSStatesNormed = inputCSSStates;
 
//  DebugTN("connectAMSCHSetCSSStatuses called; inputCSSStates: " + inputCSSStates);    
 
  for(int i = dynlen(CSSStatesNormed) + 1; i <= 2; i++)
  {
    CSSStatesNormed[i] = 0;
  }
 
//  DebugTN("connectAMSCHSetCSSStatuses called; CSSStatesNormed:" +  CSSStatesNormed);  
  
  string status1 = getConvertTableValue(convInputsStatus, convOutputsStatus, CSSStatesNormed[1]);  
  string status2 = getConvertTableValue(convInputsStatus, convOutputsStatus, CSSStatesNormed[2]);  
  
//  DebugTN("connectAMSCHSetCSSStatuses called; status1:" +  status1);  
//  DebugTN("connectAMSCHSetCSSStatuses called; status2:" +  status2);  

  if (outputValue1 != status1) {
    sgConnectionDpSet(outputDPName1, status1);
	}  
  if (outputValue2 != status2) {
    sgConnectionDpSet(outputDPName2, status2);
	}  
}  

void connectAMSCHSetCADASMH(string inputDP1, int inputCADASMH1Value, string inputDP2, int inputCADASMH2Value,
                                string outputDP1, string outputValue1){
 
  string outputDPName1 = dpSubStr(outputDP1, DPSUB_SYS_DP_EL);
  string status;  
  
//  DebugTN("connectAMSCHSetCADASMH called; ");    
 
  if (inputCADASMH1Value == 2 || inputCADASMH2Value == 2)  // case one answer is U/S
    status = U_S_STATUS;
  else if (inputCADASMH1Value == 1 || inputCADASMH2Value == 1)  // case one answer is OPS
    status = OPS_STATUS;
  else
    status = UKN_STATUS; 
  
//  DebugTN("connectAMSCHSetCSSStatuses called; status2:" +  status2);  

  if (outputValue1 != status) {
    sgConnectionDpSet(outputDPName1, status);
	}  
}  

void connectCopyStringWithDelay(string inputDP, string inputValue, string outputDP, string outputValue, 
                                   string delayDP, int delayValue, string delayedStatusDP, string delayedStatus)
{
  string status; 
  string destFormattedName = dpSubStr(outputDP, DPSUB_SYS_DP_EL);
  int currentDelay;
  string inputNewStatus;
  
  if ( (inputValue != delayedStatus) || (outputValue == delayedStatus))
  {
    status = inputValue;
  }
  else // to wait the delay
  {
    currentDelay = delayValue;

    while (currentDelay > 0 ){
      delay(1);
      currentDelay = currentDelay - 1 ;
    }
    dpGet(inputDP, inputNewStatus);
    status = inputNewStatus; // update with current value
  }  
  
  if (outputValue != status) {
    sgConnectionDpSet(destFormattedName, status);
  }
}//connectCopyStringWithDelay
