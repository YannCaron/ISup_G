// File: sgFwConnectionRulesLib.ctl
//
// Version 1.1
//
// Date 24-JUL-03
//
// This file contains the connection functions of the framework
// History
// =======
// 24-JUL-03 : First version (VL)
// 28-AUG-03 : Added connectCopy rule (VL)
// 11-FEB-04 : Added ConnectWithSubstraction (Th.V)
// 25-JUN-04 : Added special connection for EMTEL
// 17 NOV-05 : Added special connection for CTC (Th.V)
// 28 JUL-06 : Deleted connection for EMTEL (aj)
// 23 MAR 07 : deleted project specific rules (aj,pw)

string getConvertTableValue(dyn_string inputs, dyn_string outputs, string inputValue)
{

	int index = dynContains(inputs, inputValue);
	string outputValue;

	if (index >= 1)
	{
		outputValue = outputs[index];
	} else {
		outputValue = UKN_STATUS;
	}

	return outputValue;

}


void writeConvertedValue(string sourceName, string sourceVal, string destName, string destVal,
						string inpTableName, dyn_string inpTableVal, string outpTableName, dyn_string outpTableVal)
{
	int	tableIndex;
	string formattedValue;
	string destFormattedName;



	// format the destination name, because we have ..online_value at the end
	destFormattedName = dpSubStr(destName, DPSUB_SYS_DP_EL);

	// search the source value in the right row of the table to have the index
	tableIndex	= dynContains(inpTableVal, sourceVal);
//	DebugN("tableIndex:  " + tableIndex);

	// if the index is possible, take the respective value in the left row
	if(tableIndex > 0)
	{
		formattedValue = outpTableVal[tableIndex];
	}
	// or set the value to defined error value from the table (first line = index [1] )
	else
	{
		// first line is the "else" value
		formattedValue = outpTableVal[1];
//		DebugN("fct writeConvertedValue: " + sourceName + " not in the conversion table: " + inpTableName + " !");
//		DebugN("Value set to " + formattedValue);
	}
//	DebugN("formattedValue: " + formattedValue);

	// with the dpConnect, we've the problem that if we write the value in the destination name, we do a 2nd time this function.
	// Then if the destination value is correct, we don't write a second time.
	if(destVal != formattedValue)
	{
		sgConnectionDpSet(destFormattedName, formattedValue);
	}
	else
	{
//		DebugN("Conversion to structured done before. No dpSet for: " + destFormattedName);
	}
}

void writeConvertedValueInvalid(string sourceName, string sourceVal, string userbitName, bool userbitVal, string destName, string destVal,
						string inpTableName, dyn_string inpTableVal, string outpTableName, dyn_string outpTableVal)
{
	int	tableIndex;
	string formattedValue;
	string destFormattedName;

  //DebugTN(userbitName, userbitVal);  
  
	// search the source value in the right row of the table to have the index
	tableIndex	= dynContains(inpTableVal, sourceVal);
	
	// if the index is possible, take the respective value in the left row
	if(tableIndex > 0 && userbitVal == FALSE)
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
void connectDescription(string sourceName, string sourceVal, string destName, string destVal)
{

	string destFormattedName;
	string oldDescription;
	string dpDescription;

	dpDescription = sgStripDpName(destName, DESCRIPTION_DUMMY);
	oldDescription = dpGetDescription(dpDescription);

	if (sourceVal == "")
		sourceVal = " ";

	if(sourceVal == oldDescription)
		return;

	dpSetDescription(dpDescription, sourceVal);
}

void connectCopy(string sourceName, string sourceVal, string destName, string destVal)
{


	string destFormattedName;

	if(sourceVal == destVal)
		return;

	// Thierry, dec 14 to break infinite loop when source is empty
	if (sourceVal == "" && destVal == " ")
		return;

	// format the destination name, because we have ..online_value at the end
	destFormattedName = dpSubStr(destName, DPSUB_SYS_DP_EL);

	sgConnectionDpSet(destFormattedName, sourceVal);


}

void connectStringInsertion(string sourceName, string sourceVal, string destName, string destVal,
						string templateName, string templateVal)
{
	string finalString;
	string destFormattedName;

//	DebugTN("connectStringInsertion");
//	DebugTN("sgFwConnectionRulesLib >> connectStringInsertion",sourceName,  sourceVal,  destName,  destVal,
//						 templateName,  templateVal);


	// format the destination name, because we have ..online_value at the end
	destFormattedName = dpSubStr(destName, DPSUB_SYS_DP_EL);

	finalString = templateVal;

	strreplace(finalString, "%X" , sourceVal);

	// set only if values are different to avoid looping problem
	if(finalString != destVal)
		sgConnectionDpSet(destFormattedName, finalString);
}
void convertIntRangeToStatus(string sourceName, int sourceVal, string destName, string destVal,
						string inpTableName, dyn_int inpTableVal, string outpTableName, dyn_string outpTableVal)
{
	int	tableIndex;
	int i;
	string resultString = "UKN";
	string destFormattedName;

//	DebugTN("connectIntRangeStatus");

	// format the destination name, because we have ..online_value at the end
	destFormattedName = dpSubStr(destName, DPSUB_SYS_DP_EL);

	for(i = 1; i <= dynlen(inpTableVal); i++)
	{
		if(sourceVal <= inpTableVal[i])
		{
			resultString = outpTableVal[i];
			// set only if values are different to avoid looping problem
			if(resultString != destVal)
				sgConnectionDpSet(destFormattedName, resultString);

			return;
		}
	}
	// In case of the source is out of the defined range
	// set only if values are different to avoid looping problem
	if(resultString != destVal)
		sgConnectionDpSet(destFormattedName, resultString);
}
void convertIntRangeToStatusInvalid(
    string sourceName, int sourceVal,
    string userbitName, bool userbitVal,
    string destName, string destVal,
    string inpTableName, dyn_int inpTableVal, 
    string outpTableName, dyn_string outpTableVal)
{
	int	tableIndex;
	int i;
	string resultString = "UKN";
	string destFormattedName;

//	DebugTN("connectIntRangeStatus");

	// format the destination name, because we have ..online_value at the end
	destFormattedName = dpSubStr(destName, DPSUB_SYS_DP_EL);

	for(i = 1; i <= dynlen(inpTableVal); i++) {
		if(sourceVal <= inpTableVal[i])	{
      if (userbitVal == false) {
    			resultString = outpTableVal[i];
      }
			// set only if values are different to avoid looping problem
			if(resultString != destVal)
				sgConnectionDpSet(destFormattedName, resultString);

			return;
		}
	}
	// In case of the source is out of the defined range
	// set only if values are different to avoid looping problem
	if(resultString != destVal)
		sgConnectionDpSet(destFormattedName, resultString);
}

void ConnectWithSubstraction(string sourceName, int sourceValue, string destName, int destValue, string paramName, int paramValue)
{
	string destFormattedName;
	int res;

//	DebugTN("connectSubstraction");


	// format the destination name, because we have ..online_value at the end
	destFormattedName = dpSubStr(destName, DPSUB_SYS_DP_EL);

	res = sourceValue - paramValue;
	//DebugN("ConnectWithSubstraction; source: " + sourceName + " (" + sourceValue + ") - param: " + paramName + " (" + paramValue + ") = " + res);

	if (res == destValue)
		return;

	sgConnectionDpSet(destFormattedName, res);
}


void ConnectDiskSpace(string sourceName, float sourceVal, string destName, string destVal,
						string inpTableName, dyn_int inpTableVal, string outpTableName, dyn_string outpTableVal,
						string reduLinkADP, bool reduLinkAOk, string reduLinkBDP, bool reduLinkBOk,
						string activeChainDP, string activeChain)
{
	string resultString = UKN_STATUS;
	string resultValue = "??? GB";
	string chain;
	string destPreStatusName;
	string destLabelName;

	//DebugTN("ConnectDiskSpace");

	// format the destination name, because we have ..online_value at the end
	destPreStatusName = dpSubStr(destName, DPSUB_SYS_DP_EL);
	// built label name
	destLabelName = sgStripDpName(destPreStatusName,PRE_STATUS_POSTFIX) + LABEL1_POSTFIX;

	// check if active or passive chaine
	sourceName = dpSubStr(sourceName, DPSUB_DP); // get DP only
	if ( strpos(sourceName, "_2") == (strlen(sourceName) -2)) // check if dpname has _2 at the end
		chain = "B";
	else
		chain = "A";

  // calculating for passive chain only if we are connected!
  // otherwise it will be set to ukn at the end
	if ( (chain == activeChain) || (reduLinkAOk && reduLinkBOk) )
	{

		if (chain != activeChain) // change OPS by SBY if for standby chain
		{
			for (int i = 1; i <= dynlen(outpTableVal); i++)
				if (outpTableVal[i] == OPS_STATUS)
					outpTableVal[i] = SBY_STATUS;
		}

		// change format of value
		if (sourceVal < (1048064)) // a bit less then 1024*1024 due to rounding of numbers
		{
			string format;
			if (sourceVal < (102349)) // a bit less than 1024*100 due to rounding of numbers
				format = "%3.1f";
			else
				format = "%4.0f";

			sprintf(resultValue, format, (sourceVal / (1024)));
			resultValue += " MB";
		}
		else
		{
			sprintf(resultValue, "%3.2f", (sourceVal / (1024*1024)));
			resultValue += " GB";
		}

		//DebugTN(sourceName, chain, outpTableVal, destPreStatusName, destLabelName, resultValue);

		for(int i = 1; i <= dynlen(inpTableVal); i++)
		{
			//DebugTN("forloop", i);
			if(sourceVal <= inpTableVal[i])
			{
				//DebugTN("forloop in if");
				resultString = outpTableVal[i];
				// set only if values are different to avoid looping problem
				if(resultString != destVal)
				{
					sgConnectionDpSet(destPreStatusName, resultString);
					// log disk space if state changes - otherweise written nowhere
					sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, sourceName + " on Server " + chain + " is " + resultValue + ", therefore changed from " + destVal + " to " + resultString);
				}

				// has to be written even if state doesn't change!!
				sgConnectionDpSet(destLabelName, resultValue);

				return;
			}
		}
	}
	// In case of the source is out of the defined range
	// set only if values are different to avoid looping problem
	if(resultString != destVal)
	{
		sgConnectionDpSet(destPreStatusName, resultString);
	}
	// can be written without problems - not in dpconnect
	// otherwise value is kept after restart (fw sets everything to UKN)
	sgConnectionDpSet(destLabelName, resultValue);

}

string getElseStatus (dyn_string inpTableValues, dyn_string outpTableValues) {
  int index;
  
  index = dynContainsIgnoreCase(inpTableValues, ELSE_CONVERT_VALUE);
  
  if (index > 0) {
    return outpTableValues[index];
  } else {
    return UKN_STATUS;
  }

}

void connectTableIndexWithConvertTable(
    string columnDpName, dyn_string columnNameValues, 
    string columnDpStatus, dyn_string columnStatusValues,
    string searchDpName, string searchValue,
    string outputDP, string output,
    string inpTableName, dyn_string inpTableValues, 
    string outpTableName, dyn_string outpTableValues) {
  
  string outputDPName = dpSubStr(outputDP, DPSUB_SYS_DP_EL);
  string value, status; 
  int tableIndex, convertTableIndex;

  if (dynlen(columnNameValues) == dynlen(columnStatusValues)) {
    tableIndex = dynContains(columnNameValues, searchValue);
  
    if (tableIndex > 0) {
      value = columnStatusValues[tableIndex];
      convertTableIndex = dynContains(inpTableValues, value);
    
      if(convertTableIndex > 0) { 
      		status = outpTableValues[convertTableIndex];
      } else {
      		status = getElseStatus(inpTableValues, outpTableValues);
      }
    } else {
   		status = getElseStatus(inpTableValues, outpTableValues);
    }
  } else {
 		status = getElseStatus(inpTableValues, outpTableValues);
  }

  
  if (output != status) {
    sgConnectionDpSet(outputDPName, status);
  }  
}

void connectWMIServiceWithConvertTable(
    string stateDpName, string stateValue, 
    string statusDpStatus, string statusValue,
    string outputDP, string output,
    string inpTableName, dyn_string inpTableValues, 
    string outpTableName, dyn_string outpTableValues) {
  
  string outputDPName = dpSubStr(outputDP, DPSUB_SYS_DP_EL);
  string value, status; 
  int convertTableIndex;

  if (stateValue != "Running") {
  	value = stateValue;
  } else {
  	value = statusValue;
  }

  convertTableIndex = dynContains(inpTableValues, value);

  if(convertTableIndex > 0) { 
  		status = outpTableValues[convertTableIndex];
  } else {
  		status = getElseStatus(inpTableValues, outpTableValues);
  }
  
  if (output != status) {
    sgConnectionDpSet(outputDPName, status);
  }  
}

void connectActiveMQJmxHealth(string dataDP, string dataValue,
                              string outputDP, string outputValue,
							  string inpTableDP, dyn_string inpTableVal, 
							  string outpTableDP, dyn_string outpTableVal,
							  string activeChainDP, string activeChainValue) {

	string outputDPName = dpSubStr(outputDP, DPSUB_SYS_DP_EL);
	
	string status = outpTableVal[dynlen(outpTableVal)];
	int tableIndex	= dynContains(inpTableVal, dataValue);
	string server = strpos(outputDP, "ServerA") > 0 ? "A" : "B";

	if (tableIndex > 0) {
		status = outpTableVal[tableIndex];
	}

	if (status == OPS_STATUS && server != activeChainValue) {
		status = SBY_STATUS;
	}

	if (outputValue != status) {
		sgConnectionDpSet(outputDPName, status);
	}  
}