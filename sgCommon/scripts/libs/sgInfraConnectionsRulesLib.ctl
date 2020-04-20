void infraConnectSerialAgentStatus(string agentDPNamedAddressDp, dyn_int agentDPNamedAddressVal, 
                                  string agentDPNamedStatusesDp, dyn_int agentDPNamedStatusesVal, 
                                  string agentDPNamedInvalidDp, bool agentDPNamedInvalidVal,
                                  string ownAddressDp, int ownAddressVal,
                                  string workInProgressDp, bool workInProgressVal,
                                  string destName, string destVal,
                                  string inpTableName, dyn_string inpTableVal,
                                  string outpTableName, dyn_string outpTableVal)
{
 	string dpe = dpSubStr(destName, DPSUB_SYS_DP_EL);
	string value = UKN_STATUS;
//  DebugTN("InfraConnectSerialAgentStatus called");
  if (workInProgressVal)  
    value = WIP_STATUS;
  else if (dynlen(agentDPNamedAddressVal) != dynlen(agentDPNamedStatusesVal) || agentDPNamedInvalidVal == TRUE )  // case for WatchDog
  {
    value = U_S_STATUS;  // case for WatchDog
  }
  else
  {  
    int index = dynContains(agentDPNamedAddressVal, ownAddressVal);

    if (index < 1)
      DebugTN("InfraConnectSerialAgentStatus; Serial Modbus address not configured for :" + ownAddressDp);
    else
    {
      int intValue = agentDPNamedStatusesVal[index];
      value = getConvertTableValue(inpTableVal, outpTableVal, (string)intValue);
    }  
  }    
  if (destVal != value)
    sgConnectionDpSet(dpe, value);
}


void infraConnectAckAllInputsAlarms(string ackAllDp, bool ackAllValue)
{
  dyn_dyn_anytype values;  
  
  dpQuery("SELECT ALERT '_alert_hdl.._ack' " +
        "FROM '**.Components.*.{Inputs.*,AnalogInputs.*.Value}' " +
        "WHERE '_alert_hdl.._oldest_ack' == 1 ", values);     

//  DebugTN(values);

  dyn_string dps;
  dyn_int vs;
  for (int i = 2; i <= dynlen(values); i++) {
    dynAppend(dps, values[i][1] + ":_alert_hdl.._ack");
    dynAppend(vs, 2);  //2 value to ack
  }
//  DebugTN(dps);
  dpSet(dps, vs);
}

void connectInfraAlarms(string sourceName, string sourceVal, string WagoStatusDp, string WagoStatusVal, 
                        string destName, string destVal,
						string inpTableName, dyn_string inpTableVal, string outpTableName, dyn_string outpTableVal)
{
	int	tableIndex;
	string formattedValue;
	string destFormattedName;
//	DebugN("connectInfraAlarms for: destVal" + destVal);

  if (WagoStatusVal == OPS_STATUS)  // if WAGO OPS, normal conversion
  {
    	// search the source value in the right row of the table to have the index
    	tableIndex	= dynContains(inpTableVal, sourceVal);
	
    if(tableIndex > 0)
    		formattedValue = outpTableVal[tableIndex];
    	else
    		formattedValue = UKN_STATUS;	
  }
  else if (WagoStatusVal == WIP_STATUS)  // if WAGO WIP, alarm WIP toon
  {	
    	formattedValue = WIP_STATUS;	
  }
    else
      formattedValue = UKN_STATUS;	
  
  if(destVal != formattedValue)
	{
		destFormattedName = dpSubStr(destName, DPSUB_SYS_DP_EL);

		dpSet(destFormattedName, formattedValue);
	}
	else
	{
//		DebugN("Conversion to structured done before. No dpSet for: " + destFormattedName);
	}
}
