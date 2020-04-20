// File: sgNavirConnectionRulesLib.ctl
// 
// Version 1.1
//
// Date 1-MAR-05
//
// This file contains the connection functions dedicated for Navir
// History
// =======
// 01-MAR-05 : First version (PW)
// 03-MAR-05 : Modified for performance problem when copying the timeStamp -> own rule to copy the timestamp
// 11-SEP-06 : Modified to set the TimeStamp without an new connection
// 27-SEP-06 : Version without double line with a dpGet for timeStamp (PW)

global dyn_string navirConnectionDpNames;
global dyn_string navirConnectionsLastStatuses;

// set the status after convert Table and set the TimeStamp
void writeNavirConvertedStatusAndTS(string rawStatusName, string rawStatusVal, string TSDPName, string TSDPVal, 
										string destName, string destVal,string destMessageName, string destMessageVal,	
									 	string inpTableName, dyn_string inpTableVal, string outpTableName, dyn_string outpTableVal)
{
	int	tableIndex;
	string formattedValue;
	string statusDestFormattedName;
	string messageDestFormattedName;

	// Get last status in the global table. it possible to have to call in parallel -> dpSet in database isn't fast enough
	int index;
	string lastStatus;

	// get dpNames index in table
	index = dynContains(navirConnectionDpNames, rawStatusName);

	// if it doesn't exist, create it
	if (index != 0)
	{
		// get last status to compare
		lastStatus = navirConnectionsLastStatuses[index];
	}
	else // case where it doesn't exists, update the table with current values
	{
		dynAppend(navirConnectionDpNames, rawStatusName);
		dynAppend(navirConnectionsLastStatuses, "");
		
		// no last status
		lastStatus = "";
		index = dynlen(navirConnectionDpNames);
	} 

	// search the source value in the right row of the table to have the index
	tableIndex	= dynContains(inpTableVal, rawStatusVal);
	
	// if the index is possible, take the respective value in the left row
	if(tableIndex > 0)
	{
		formattedValue = outpTableVal[tableIndex];
	}
	// or set the value to defined error value from the table (first line = index [1] )
	else
	{
		formattedValue = UKN_STATUS;	
	}

	// write only if Status change
	if (lastStatus != formattedValue)
	{
		string newTS;
		string newTSDpName;

		// get fresh TimeStamp because it wasn't garanted to be updated at the first dpConnect call.
		newTSDpName = dpSubStr(TSDPName, DPSUB_SYS_DP_EL);
		dpGet(newTSDpName, newTS);
			
	// format destinations names
		statusDestFormattedName = dpSubStr(destName, DPSUB_SYS_DP_EL);
		messageDestFormattedName = dpSubStr(destMessageName, DPSUB_SYS_DP_EL);

		// only one dpSet to garantee only one call for the framework Event generator
		dpSet(statusDestFormattedName, formattedValue, messageDestFormattedName, newTS);

		//	update tables only if status & timeStamp have changed
		navirConnectionsLastStatuses[index] = formattedValue;
	} 
	else
	{
		//		DebugTN("writeNavirConvertedStatusAndTS; if destination value = formatted value. No dpSet");
	}// if destination value = formatted value
}

// std Navir connection function through a conversion table
void writeNavirConvertedValue(string sourceName, string sourceVal, string destName, string destVal,
						string inpTableName, dyn_string inpTableVal, string outpTableName, dyn_string outpTableVal)
{
	int	tableIndex;
	string formattedValue;
	string destFormattedName;

	// search the source value in the right row of the table to have the index
	tableIndex	= dynContains(inpTableVal, sourceVal);
	
	// if the index is possible, take the respective value in the left row
	if(tableIndex > 0)
	{
		formattedValue = outpTableVal[tableIndex];
	}
	// or set the value to defined error value from the table (first line = index [1] )
	else
	{
		formattedValue = UKN_STATUS;	
	}

	// with the dpConnect, we've the problem that if we write the value in the destination name, we do a 2nd time this function.
	// Then if the destination value is correct, we don't write a second time.
	if(destVal != formattedValue)
	{
		// format the destination name, because we have ..online_value at the end
		destFormattedName = dpSubStr(destName, DPSUB_SYS_DP_EL);

		dpSet(destFormattedName, formattedValue);
	}
	else
	{
//		DebugN("Conversion to structured done before. No dpSet for: " + destFormattedName);
	}
}

void connectTSToAllMessages(string dpName, string TSValue, string messageDpName, string messageValue, 
																																									string dpParamsName, dyn_string messagePostfixes)
{
	string stationName;
	dyn_string dp;
	dyn_string messages;

	// check if the value is the same ( can be called twice)
	if(TSValue != messageValue)
	{	
		stationName = substr(dpName, 0, strpos(dpName, ".RawDatas")); // get station name
	//	DebugTN("TimeStamp copied to message for station: " + stationName +"  TS: " + TSValue);
	
		for(int i = 1 ; i <= dynlen(messagePostfixes); i++)
		{
			dynAppend(dp, stationName + messagePostfixes[i]); // append dplist with station + postfix
			dynAppend(messages, TSValue);			// append message with timestamp
		}
//		dpSet(dp, messages); // only one dpSet per station
	}
}

void setGBASDCPActiveChannel(string inputDPDCP1Channel1NotActive, bool inputDCP1Channel1NotActiveValue,
                              string inputDPDCP1Channel2NotActive, bool inputDCP1Channel2NotActiveValue,
                              string inputDPDCP2Channel1NotActive, bool inputDCP2Channel1NotActiveValue,
                              string inputDPDCP2Channel2NotActive, bool inputDCP2Channel2NotActiveValue,
                              string inputDPDCP1IP, string inputDCP1IPAddress,
                              string inputDPDCP2IP, string inputDCP2IPAddress,
                              string outputDP, int destVal)
{
  string dpe = dpSubStr(outputDP, DPSUB_SYS_DP_EL);
  int value = 0;
  int valueDCP1 = 0;
  int valueDCP2 = 0;
  string DCP1IPAddressFromHosts = getHostByName("GBAS-DCP-1");
  string DCP2IPAddressFromHosts = getHostByName("GBAS-DCP-2");
  
//DebugTN("connectNavirGBASDCP; inputDCP1ChannelActiveValue= " + inputDCP1ChannelActiveValue);    
//DebugTN("connectNavirGBASDCP; inputDCP2ChannelActiveValue= " + inputDCP2ChannelActiveValue);    
     
  if (inputDCP1IPAddress == DCP1IPAddressFromHosts)   
  {
    if (!inputDCP1Channel1NotActiveValue && inputDCP1Channel2NotActiveValue)
      valueDCP1 = 1;  
    else if (inputDCP1Channel1NotActiveValue && !inputDCP1Channel2NotActiveValue)
      valueDCP1 = 2;
    else
      valueDCP1 = 0;
  }
  
  if (inputDCP2IPAddress == DCP2IPAddressFromHosts)   
  {
    if (!inputDCP2Channel1NotActiveValue && inputDCP2Channel2NotActiveValue)
      valueDCP2 = 1;  
    else if (inputDCP2Channel1NotActiveValue && !inputDCP2Channel2NotActiveValue)
      valueDCP2 = 2;
    else
      valueDCP2 = 0;
  }
  
  if (inputDCP1IPAddress == DCP2IPAddressFromHosts)  // special case; if IP is the other the Channel 2 active but OID suffix is .1!
      value = 10; // to distinguish with 1
    else
      value = 99;

//DebugTN("connectNavirGBASDCP; valueDCP1= " + valueDCP1);    
//DebugTN("connectNavirGBASDCP; valueDCP2= " + valueDCP2);    
        
  if  ((valueDCP1 == 1) || (valueDCP2 == 1)  )
    value = 1;
  else if ((valueDCP1 == 2) || (valueDCP2 == 2))  
    value = 2;
    
//DebugTN("setGBASDCPActiveChannel; value= " + value);  
  if (destVal != value)
    sgConnectionDpSet(dpe, value);
}

void connectNavirGBASDCP(string inputDPDCPChannel, bool inputDCPChannelValue, 
                            string inputDPDCPChannelActive, bool inputDCPChannelActiveValue,
                            string outputDP, string destVal)
{
  string dpe = dpSubStr(outputDP, DPSUB_SYS_DP_EL);
  string value = UKN_STATUS;
  
//   DebugTN("connectNavirGBASDCP; inputDCPChannelValue= " + inputDCPChannelValue);    
//   DebugTN("connectNavirGBASDCP; inputDCPChannelActiveValue= " + inputDCPChannelActiveValue);    
     
  if (inputDCPChannelValue)
    value = U_S_STATUS;  
  else if (inputDCPChannelActiveValue)
    value = SBY_STATUS;
  else 
    value = OPS_STATUS;
  
//   DebugTN("connectNavirGBASDCP; value= " + value);  
  if (destVal != value)
		sgConnectionDpSet(dpe, value);
}

void connectNavirGBASTX(string inputDPChannel, bool inputFaultStatusValue, 
                            string inputDPChannelActive, bool inputTransmitStatusValue,
                            string outputDP, string destVal)
{
  string dpe = dpSubStr(outputDP, DPSUB_SYS_DP_EL);
  string value = UKN_STATUS;

  if (inputFaultStatusValue)
    value = U_S_STATUS;  
  else if (inputTransmitStatusValue)
    value = OPS_STATUS;
  else value = SBY_STATUS;
    
//    DebugTN("connectNavirGBASTX; value= " + value);  
//    DebugTN("connectNavirGBASTX; dpe= " + dpe);  
   
  if (destVal != value)
		sgConnectionDpSet(dpe, value);
}

void connectNavirGBASPS(string inputPSStatusDP, int inputPSStatusValue, 
                        string outputDP, string destVal)
{
  string dpe = dpSubStr(outputDP, DPSUB_SYS_DP_EL);
  string value = UKN_STATUS;

  bool bit0, bit1;
  
  if ((fmod(inputPSStatusValue, 2)) >= 1) 
    bit0 = true;
  else 
    bit0 = false;

  if ((fmod(inputPSStatusValue, 4)) >= 2) 
    bit1 = true;
  else 
    bit1 = false;  
   
  if (inputPSStatusValue == 0)
    value = OPS_STATUS;  
  else if (bit0 && bit1) // both PS failed
    value = U_S_STATUS;
  else 
    value = DEG_STATUS;
    
//    DebugTN("connectNavirGBASPS; value= " + value);  
  if (destVal != value)
		sgConnectionDpSet(dpe, value);
}

void connectNavirGBASOtherWarnings(string inputDPNotAvailable, bool inputNotAvailableValue, 
                            string inputDPTest, bool inputTestValue,
                            string inputDPServiceAlert, bool inputServiceAlertValue,
                            string inputDPPowerUp, bool inputDPPowerUpValue,
                            string inputDPPowerDown, bool inputDPPowerDownValue,                            
                            string outputDP, string destVal)
{
  string dpe = dpSubStr(outputDP, DPSUB_SYS_DP_EL);
  string value = UKN_STATUS;

  if (inputNotAvailableValue)
    value = U_S_STATUS;  
  else if (inputTestValue || inputDPPowerUpValue || inputDPPowerDownValue)
    value = WIP_STATUS;
  else if (inputServiceAlertValue)
    value = DEG_STATUS;
  else value = OPS_STATUS;
    
//    DebugTN("connectNavirGBASOtherWarnings; value= " + value);  
   
  if (destVal != value)
		sgConnectionDpSet(dpe, value);
}

void connectNavirGBASINCH(string dpModeBit0, bool modeBit0Value,
                          string dpModeBit1, bool modeBit1Value,
                          string dpModeBit2, bool modeBit2Value,
                          string dpModeBit5, bool modeBit5Value,
                          string dpModeBit6, bool modeBit6Value,
                          string dpConstAlertsBit0, bool ConstAlertsBit0Value,
                          string dpFASConfigRunway, string FASConfigRunwayValue,
                          string dpFASBroadcastStatus, string FASBroadcastStatusValue,
                          string outputDP, string destVal)
{
  string dpe = dpSubStr(outputDP, DPSUB_SYS_DP_EL);
  string value;
//     DebugTN("connectNavirGBASINCH; modeBit0Value= " + modeBit0Value);  
//     DebugTN("connectNavirGBASINCH; modeBit1Value= " + modeBit1Value);  
//     DebugTN("connectNavirGBASINCH; modeBit2Value= " + modeBit2Value);  
//     DebugTN("connectNavirGBASINCH; modeBit5Value= " + modeBit5Value);  
//     DebugTN("connectNavirGBASINCH; modeBit6Value= " + modeBit6Value);  
//     DebugTN("connectNavirGBASINCH; ConstAlertsBit0Value= " + ConstAlertsBit0Value);  
//     DebugTN("connectNavirGBASINCH; FASBroadcastStatusValue = " + FASBroadcastStatusValue );  
    
  string FASStatusValue = substr(FASBroadcastStatusValue, 37, 9);  //37-45: Configured status
  string FASRunwayNumberValue = substr(FASBroadcastStatusValue, 7, 2);  //7-9: Runway with position " 1L" or "28R".     

//  DebugTN("connectNavirGBASINCH; FASStatusValue= " + FASStatusValue);  
//  DebugTN("connectNavirGBASINCH; FASRunwayNumberValue= " + FASRunwayNumberValue);  
                              
  if (FASBroadcastStatusValue == "-")  // from WatchDog 
    value = U_S_STATUS;
  else if (modeBit2Value || modeBit5Value || modeBit6Value)
    value = WIP_STATUS;  
  else if (modeBit1Value || ConstAlertsBit0Value || (FASConfigRunwayValue != FASRunwayNumberValue) || !(strpos(FASStatusValue, "Enabled") >= 0) ) 
    value = U_S_STATUS;
  else if (modeBit0Value)
    value = OPS_STATUS;
  else
    value = UKN_STATUS;
     
//    DebugTN("connectNavirGBASINCH; value= " + value);  
   
  if (destVal != value)
		sgConnectionDpSet(dpe, value);
} 

void connectNavirGBASEstimatedTime(string inputDPSeconds, int inputSeconds, // inputSeconds are the number of 1/100 seconds. 3600 = 36 seconds
                                   string inputDPWeeks, int inputWeeks,
                                   string paramsDP, string paramsVal, 
                                   string outputDP, string destVal)
{
  string dpe = dpSubStr(outputDP, DPSUB_SYS_DP_EL);
  time originalTime = makeTime(1980, 1, 6);  // HoneyWell Time format start the 6 January 1980
  time estimatedStartTime;
  string value = " ";

  if (inputSeconds != 0 || inputWeeks != 0) //  0 & 0 -> time invalid
  {
    int intOriginalTime = originalTime;  //format time in integer 
 
    long secondsFromWeeks =  7 * 24 * 3600 * inputWeeks; // 7 days * 24 hours * 3600 seconds = 604800;
//    DebugTN("secondsFromWeeks: " + secondsFromWeeks)  ;
    
    time estimatedTimeToCheck = originalTime + secondsFromWeeks + inputSeconds; 
 
    time currentTime = getCurrentTime();    
     
    estimatedStartTime = inputSeconds;  // format to time    
    
    if (estimatedTimeToCheck > currentTime)  // display only if time is in the future
    {
      value = paramsVal + formatTime("%H:%M", estimatedStartTime); // HH:MM only hour and minutes are interesting + format to string
 //     DebugTN("value: " + value)  ;
    }
  }   
//  DebugTN("value: " + value)  ;
//  DebugTN("destVal: " + destVal)  ;
  
  if (destVal != value)
		sgConnectionDpSet(dpe, value);
}

void extractNavirGBAS4Bits(string inputDP, int inputValue, 
                            string outputDPB0, bool outputValueBit0,
                            string outputDPB1, bool outputValueBit1,
                            string outputDPB2, bool outputValueBit2,
                            string outputDPB3, bool outputValueBit3
                            ){
  string outputDPBit0 = dpSubStr(outputDPB0, DPSUB_SYS_DP_EL);
  string outputDPBit1 = dpSubStr(outputDPB1, DPSUB_SYS_DP_EL);
  string outputDPBit2 = dpSubStr(outputDPB2, DPSUB_SYS_DP_EL);
  string outputDPBit3 = dpSubStr(outputDPB3, DPSUB_SYS_DP_EL);
  
//   DebugTN("extractNavirGBAS4Bits; inputValue= " + inputValue);
//   DebugTN("extractNavirGBAS4Bits; outputDPB0= " + outputDPB0);
//   DebugTN("extractNavirGBAS4Bits; outputDPB1= " + outputDPB1);
//   DebugTN("extractNavirGBAS4Bits; outputDPB2= " + outputDPB2);
//   DebugTN("extractNavirGBAS4Bits; outputDPB3= " + outputDPB3);
//   
  bool bit0, bit1, bit2, bit3;
  
  if ((fmod(inputValue, 2)) >= 1) 
    bit0 = true;
  else 
    bit0 = false;

  if ((fmod(inputValue, 4)) >= 2) 
    bit1 = true;
  else 
    bit1 = false;

  if ((fmod(inputValue, 8)) >= 4) 
    bit2 = true;
  else 
    bit2 = false;

  if ((fmod(inputValue, 16)) >= 8) 
    bit3 = true;
  else 
    bit3 = false;
  
  if (outputValueBit0 != bit0)
    dpSet(outputDPBit0, bit0);
  if (outputValueBit1 != bit1)
    dpSet(outputDPBit1, bit1);
  if (outputValueBit2 != bit2)
    dpSet(outputDPBit2, bit2);
  if (outputValueBit3 != bit3)
    dpSet(outputDPBit3, bit3);
  }  

void extractNavirGBAS8Bits(string inputDP, int inputValue, 
                            string outputDPB0, bool outputValueBit0,
                            string outputDPB1, bool outputValueBit1,
                            string outputDPB2, bool outputValueBit2,
                            string outputDPB3, bool outputValueBit3,
                            string outputDPB4, bool outputValueBit4,
                            string outputDPB5, bool outputValueBit5,
                            string outputDPB6, bool outputValueBit6,
                            string outputDPB7, bool outputValueBit7
                            ){
  string outputDPBit0 = dpSubStr(outputDPB0, DPSUB_SYS_DP_EL);
  string outputDPBit1 = dpSubStr(outputDPB1, DPSUB_SYS_DP_EL);
  string outputDPBit2 = dpSubStr(outputDPB2, DPSUB_SYS_DP_EL);
  string outputDPBit3 = dpSubStr(outputDPB3, DPSUB_SYS_DP_EL);
  string outputDPBit4 = dpSubStr(outputDPB4, DPSUB_SYS_DP_EL);
  string outputDPBit5 = dpSubStr(outputDPB5, DPSUB_SYS_DP_EL);
  string outputDPBit6 = dpSubStr(outputDPB6, DPSUB_SYS_DP_EL);
  string outputDPBit7 = dpSubStr(outputDPB7, DPSUB_SYS_DP_EL);
//   DebugTN("extractNavirGBAS8Bits; inputValue= " + inputValue);
//   DebugTN("extractNavirGBAS8Bits; outputDPB0= " + outputDPB0);
//   DebugTN("extractNavirGBAS8Bits; outputDPB1= " + outputDPB1);
//   DebugTN("extractNavirGBAS8Bits; outputDPB2= " + outputDPB2);
//   DebugTN("extractNavirGBAS8Bits; outputDPB3= " + outputDPB3);
//   
  bool bit0, bit1, bit2, bit3, bit4, bit5, bit6, bit7;
  
  if ((fmod(inputValue, 2)) >= 1) 
    bit0 = true;
  else 
    bit0 = false;

  if ((fmod(inputValue, 4)) >= 2) 
    bit1 = true;
  else 
    bit1 = false;

  if ((fmod(inputValue, 8)) >= 4) 
    bit2 = true;
  else 
    bit2 = false;

  if ((fmod(inputValue, 16)) >= 8) 
    bit3 = true;
  else 
    bit3 = false;
  
  if ((fmod(inputValue, 32)) >= 16) 
    bit4 = true;
  else 
    bit4 = false;
  
  if ((fmod(inputValue, 64)) >= 32) 
    bit5 = true;
  else 
    bit5 = false;
  
  if ((fmod(inputValue, 128)) >= 64) 
    bit6 = true;
  else 
    bit6 = false;
  
  if ((fmod(inputValue, 256)) >= 128) 
    bit7 = true;
  else 
    bit7 = false;
  
  if (outputValueBit0 != bit0)
    dpSet(outputDPBit0, bit0);
  if (outputValueBit1 != bit1)
    dpSet(outputDPBit1, bit1);
  if (outputValueBit2 != bit2)
    dpSet(outputDPBit2, bit2);
  if (outputValueBit3 != bit3)
    dpSet(outputDPBit3, bit3);
  if (outputValueBit4 != bit4)
    dpSet(outputDPBit4, bit4);
  if (outputValueBit5 != bit5)
    dpSet(outputDPBit5, bit5);
  if (outputValueBit6 != bit6)
    dpSet(outputDPBit6, bit6);
  if (outputValueBit7 != bit7)
    dpSet(outputDPBit7, bit7);  
  }  

void extractNavirGBAS16Bits(string inputDP, int inputValue, 
                            string outputDPB0, bool outputValueBit0,
                            string outputDPB1, bool outputValueBit1,
                            string outputDPB2, bool outputValueBit2,
                            string outputDPB3, bool outputValueBit3,
                            string outputDPB4, bool outputValueBit4,
                            string outputDPB5, bool outputValueBit5,
                            string outputDPB6, bool outputValueBit6,
                            string outputDPB7, bool outputValueBit7,
                            string outputDPB8, bool outputValueBit8,
                            string outputDPB9, bool outputValueBit9,
                            string outputDPB10, bool outputValueBit10,
                            string outputDPB11, bool outputValueBit11,
                            string outputDPB12, bool outputValueBit12,
                            string outputDPB13, bool outputValueBit13,
                            string outputDPB14, bool outputValueBit14,
                            string outputDPB15, bool outputValueBit15
                            ){
  string outputDPBit0 = dpSubStr(outputDPB0, DPSUB_SYS_DP_EL);
  string outputDPBit1 = dpSubStr(outputDPB1, DPSUB_SYS_DP_EL);
  string outputDPBit2 = dpSubStr(outputDPB2, DPSUB_SYS_DP_EL);
  string outputDPBit3 = dpSubStr(outputDPB3, DPSUB_SYS_DP_EL);
  string outputDPBit4 = dpSubStr(outputDPB4, DPSUB_SYS_DP_EL);
  string outputDPBit5 = dpSubStr(outputDPB5, DPSUB_SYS_DP_EL);
  string outputDPBit6 = dpSubStr(outputDPB6, DPSUB_SYS_DP_EL);
  string outputDPBit7 = dpSubStr(outputDPB7, DPSUB_SYS_DP_EL);
  string outputDPBit8 = dpSubStr(outputDPB8, DPSUB_SYS_DP_EL);
  string outputDPBit9 = dpSubStr(outputDPB9, DPSUB_SYS_DP_EL);
  string outputDPBit10 = dpSubStr(outputDPB10, DPSUB_SYS_DP_EL);
  string outputDPBit11 = dpSubStr(outputDPB11, DPSUB_SYS_DP_EL);
  string outputDPBit12 = dpSubStr(outputDPB12, DPSUB_SYS_DP_EL);
  string outputDPBit13 = dpSubStr(outputDPB13, DPSUB_SYS_DP_EL);
  string outputDPBit14 = dpSubStr(outputDPB14, DPSUB_SYS_DP_EL);
  string outputDPBit15 = dpSubStr(outputDPB15, DPSUB_SYS_DP_EL);

  bool bit0, bit1, bit2, bit3, bit4, bit5, bit6, bit7,
        bit8, bit9, bit10, bit11, bit12, bit13, bit14, bit15;

  if ((fmod(inputValue, 2)) >= 1) 
    bit0 = true;
  else 
    bit0 = false;

  if ((fmod(inputValue, 4)) >= 2) 
    bit1 = true;
  else 
    bit1 = false;

  if ((fmod(inputValue, 8)) >= 4) 
    bit2 = true;
  else 
    bit2 = false;

  if ((fmod(inputValue, 16)) >= 8) 
    bit3 = true;
  else 
    bit3 = false;
  
  if ((fmod(inputValue, 32)) >= 16) 
    bit4 = true;
  else 
    bit4 = false;
  
  if ((fmod(inputValue, 64)) >= 32) 
    bit5 = true;
  else 
    bit5 = false;
  
  if ((fmod(inputValue, 128)) >= 64) 
    bit6 = true;
  else 
    bit6 = false;
  
  if ((fmod(inputValue, 256)) >= 128) 
    bit7 = true;
  else 
    bit7 = false;
  
  if ((fmod(inputValue, 512)) >= 256) 
    bit8 = true;
  else 
    bit8 = false;

  if ((fmod(inputValue, 1024)) >= 512) 
    bit9 = true;
  else 
    bit9 = false;

  if ((fmod(inputValue, 2048)) >= 1024) 
    bit10 = true;
  else 
    bit10 = false;

  if ((fmod(inputValue, 4096)) >= 2048) 
    bit11 = true;
  else 
    bit11 = false;
  
  if ((fmod(inputValue, 8192)) >= 4096) 
    bit12 = true;
  else 
    bit12 = false;
  
  if ((fmod(inputValue, 16384)) >= 8192) 
    bit13 = true;
  else 
    bit13 = false;
  
  if ((fmod(inputValue, 32768)) >= 16384) 
    bit14 = true;
  else 
    bit14 = false;
  
  if ((fmod(inputValue, 65536)) >= 32768) 
    bit15 = true;
  else 
    bit15 = false;

 if (outputValueBit0 != bit0)
    dpSet(outputDPBit0, bit0);
  if (outputValueBit1 != bit1)
    dpSet(outputDPBit1, bit1);
  if (outputValueBit2 != bit2)
    dpSet(outputDPBit2, bit2);
  if (outputValueBit3 != bit3)
    dpSet(outputDPBit3, bit3);
  if (outputValueBit4 != bit4)
    dpSet(outputDPBit4, bit4);
  if (outputValueBit5 != bit5)
    dpSet(outputDPBit5, bit5);
  if (outputValueBit6 != bit6)
    dpSet(outputDPBit6, bit6);
  if (outputValueBit7 != bit7)
    dpSet(outputDPBit7, bit7);  
  if (outputValueBit8 != bit8)
    dpSet(outputDPBit8, bit8);
  if (outputValueBit9 != bit9)
    dpSet(outputDPBit9, bit9);
  if (outputValueBit10 != bit10)
    dpSet(outputDPBit10, bit10);
  if (outputValueBit11 != bit11)
    dpSet(outputDPBit11, bit11);
  if (outputValueBit12 != bit12)
    dpSet(outputDPBit12, bit12);
  if (outputValueBit13 != bit13)
    dpSet(outputDPBit13, bit13);
  if (outputValueBit14 != bit14)
    dpSet(outputDPBit14, bit14);
  if (outputValueBit15 != bit15)
    dpSet(outputDPBit15, bit15);   
 }  

void GBASGetDefaultValueFromActiveChannel(string dpStatus1, string statusValue1,
                                          string dpStatus2, string statusValue2,
                                          string dpActiveChannel, string ActiveChannel,                          
                                          string outputDP, string destVal)
{
  string dpe = dpSubStr(outputDP, DPSUB_SYS_DP_EL);
  string value;

//    DebugTN("GBASGetDefaultValueFromActiveChannel; dpModeStatus1= " + dpModeStatus1);  
if (ActiveChannel == "1" || ActiveChannel == "10") // 10 special case Channel 2 active but with suffix .1!
    value = statusValue1;
  else if (ActiveChannel == "2") 
    value = statusValue2; 
  else value = statusValue1;
     
//  DebugTN("GBASGetDefaultValueFromActiveChannel; value= " + value);  
  if (destVal != value)
		sgConnectionDpSet(dpe, value);
} 

void GBASGetDefaultValueFromActiveChannelForConstAlertTime(string dpStatus1, string statusValue1,
                                          string dpStatus2, string statusValue2,
                                          string dpActiveChannel, string ActiveChannel,                          
                                          string outputDP, string destVal)
{
  string dpe = dpSubStr(outputDP, DPSUB_SYS_DP_EL);
  string value;

//    DebugTN("GBASGetDefaultValueFromActiveChannelForConstAlertTime; dpModeStatus1= " + dpModeStatus1);  
if (ActiveChannel == "1" || ActiveChannel == "10") // 10 special case Channel 2 active but with suffix .1!
    value = statusValue1;
  else if (ActiveChannel == "2") 
    value = statusValue2; 
  else value = statusValue1;
     
//  DebugTN("GBASGetDefaultValueFromActiveChannelForConstAlertTime; value= " + value);  
		sgConnectionDpSet(dpe, value);
} 


void connectNavirINCHConstAlert(string dpPredStatus, string predStatus,
                                string dpPredLabel1, string predLabel1,
                                string dpConstStatus, string constStatus,
                                string dpConstLabel1, string constLabel1,
                                string outputStatusDP, string outputStatusVal,
                                string outputLabel1DP, string outputLabel1Val)
{
  string dpStatus = dpSubStr(outputStatusDP, DPSUB_SYS_DP_EL);
  string dpLabel1 = dpSubStr(outputLabel1DP, DPSUB_SYS_DP_EL);
  string statusValue = U_S_STATUS;
  string labelValue = "";
//  DebugTN("connectNavirINCHConstAlert" + "  constStatus:"  + constStatus);
//  DebugTN("connectNavirINCHConstAlert" + "  predStatus:" + predStatus);

  if((constStatus == OPS_STATUS) && (predStatus == OPS_STATUS))  // case no constellation alert
  {
    statusValue = OPS_STATUS;
    labelValue = "";
  }
  else if (constStatus == U_S_STATUS) // case constellation alert active 
  {
    statusValue = U_S_STATUS;
    labelValue = constLabel1;
  }
  else if (predStatus == DEG_STATUS) // case predicted constellation alert active 
  {
    statusValue = DEG_STATUS;
    labelValue = predLabel1;
  }
 
  if (outputStatusVal != statusValue)
		sgConnectionDpSet(dpStatus, statusValue );

  if (outputLabel1Val != labelValue)
		sgConnectionDpSet(dpLabel1, labelValue );
} 
