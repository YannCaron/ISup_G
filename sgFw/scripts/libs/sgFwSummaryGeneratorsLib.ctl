// 09 MARS 2004 First version (Th.V)

string translateBooleanValue(bool value)
{
	if (value == 0)
		return("No");
	else
		return("Yes");
} // string translateBooleanValue(bool value)

string dynSplit(dyn_string dynValue)
{
	string temp;
	for (int i = 1; i <= dynlen(dynValue); i++)
	{
			temp += dynValue[i];
			if (i < dynlen(dynValue))
				temp += ", ";
	}
	
	return temp;
} // string dynSplit(dyn_string value)

dyn_string reportLastDynString(dyn_string ds, int nbLastValues)
{

	// Report only last values of a dyn_string
	dyn_string out;
	int len;
	len = dynlen(ds);
	// DebugN("length: " + len);
	len -= nbLastValues; // short
	if (len < 1)
		//len = dynlen(ds);
		len = 1;
			
	for (int i = len; i <= dynlen(ds); i++)
	{
	// 	DebugN("index: " + i);
		dynAppend(out, ds[i]);
	}	
	return out;
}  // dyn_string reportLastDynString(dyn_string ds, int nbLastValues)

bool isIpAddressValide(string ipAddress)
{
	int nb = 0;
	string s;
	
	for (int cpt = 1; cpt <= strlen(ipAddress); cpt++)
	{
		if (ipAddress[cpt] == '.')
			nb++;
	}
	
	if (nb == 3)
		return true;
	else
	{
//		DebugN("isIpAddressValide >> nb points: " + nb);
		return false;	
	}

} // bool isIpAddressValide(string ipAddress)

dyn_string generateSummary_sgWatchDogs(string point)
{
	dyn_string summary;
	dyn_string references, defaultValues, outputs;
	dyn_int timeouts;
	string timeoutsString;
	
	
	dpGet(point + ".References", references,
				point + ".Timeouts", timeouts,
				point + ".DefaultValues", defaultValues,
				point + ".Outputs", outputs);
	timeoutsString = timeouts;			
	dynAppend(summary, "References");
	dynAppend(summary, references);
	dynAppend(summary, "");
	dynAppend(summary, "Timeouts");
	dynAppend(summary, timeoutsString);
	dynAppend(summary, "");
	dynAppend(summary, "DefaultValues");
	dynAppend(summary, defaultValues);
	dynAppend(summary, "");
	dynAppend(summary, "Outputs");
	dynAppend(summary, outputs);
	return summary;
} // dyn_string generateSummary_sgWatchDogs(string point)

dyn_string generateSummary_sgAETable(string point)
{
	dyn_string summary;
	dynAppend(summary, "AE table for: " + point);
	dynAppend(summary, "");
	dyn_string values;
	dpGet(point + ".Table", values);
	
	
	dynAppend(summary, values);
	return summary;
}


dyn_string generateSummary_sgParams(string point)
{
	dyn_string histories;
	string aeTable;
	int delayTime;
	bool generateAlarms, generateEvents;
	
	dpGet(point + ".Histories", histories,
				point + ".AETable",   aeTable,
				point + ".Delay",     delayTime,
				point + ".GenerateAlarms", generateAlarms,
				point + ".GenerateEvents", generateEvents);
				
	dyn_string summary;
	dynAppend(summary, "Params for: " + point);
	dynAppend(summary, "");
	dynAppend(summary, "Histories:      " + histories);
	dynAppend(summary, "AETable:        " + aeTable);
	dynAppend(summary, "Delay:          " + delayTime);
	dynAppend(summary, "GenerateAlarms: " + generateAlarms);
	dynAppend(summary, "GenerateEvents: " + generateEvents);
	
	return summary;
} // dyn_string generateSummary_sgFParams(string point)

dyn_string generateSummary_sgFwAlarmRules(string point)
{
	dyn_string summary, dummy;
	dyn_string names, normalStatuses, comments;
	
	dpGet(point + ".Names", names);		
	dpGet(point + ".NormalStatuses", normalStatuses);		
	dpGet(point + ".Comments", comments);		
	
	if (dynlen(names) != dynlen(normalStatuses) ||  dynlen(names) != dynlen(comments) || dynlen(normalStatuses) != dynlen(comments))
	{
		dynAppend(summary, "length of dyn_string not equals !!!");
		return summary;
	}
	
	for (int i = 1; i <= dynlen(names); i ++)
		dynAppend(summary, names[i] + ", " + normalStatuses[i] + ",  " + comments[i]);

	return summary;
} // generateSummary_sgFwAlarmRules(string point)

dyn_string generateSummary_sgFwTruthTable(string point)
{
	dyn_string summary, result;
	dynAppend(summary, "Truth Table: " + point);
	dynAppend(summary, "");
	
	if (strpos(point, ".") != -1)
		dpGet(point, result);
	else
		dpGet(point + ".", result);
	
	dynAppend(summary, result);
	return summary;	
} // dyn_string generateSummary_sgFwTruthTable(string point)

dyn_string generateSummary_sgFwInt(string point)
{
	dyn_string summary;
	int value;
	dpGet(point, value);
	
	dynAppend(summary, "dpName: " + point + " value: " + value);
	return summary;
} // dyn_string generateSummary_sgFwInt(string point)

dyn_string generateSummary_sgFwLogicRules(string point)
{
	dyn_string summary, dummy;
	dyn_string names, rules, initialValues, comments;

	dpGet(point + ".Names", names);
	dpGet(point + ".Rules", rules);
	dpGet(point + ".InitialValues", initialValues);
	dpGet(point + ".Comments", comments);
	
	if (dynlen(names) != dynlen(comments) || dynlen(names) != dynlen(rules) || dynlen(names) != dynlen(initialValues) || dynlen(names) != dynlen(comments) ||
		dynlen(rules) != dynlen(initialValues) || dynlen(rules) != dynlen(comments) ||
		dynlen(initialValues) != dynlen(comments) )
	{
		dynAppend(summary, "length of dyn_strings are not  equals!!!");
		return;
	}
	
	for(int i = 1; i < dynlen(names); i++)
	 dynAppend(summary, names[i] + ", " + comments[i]);
		
	return summary;
}
dyn_string generateSummary__SNMPManager(string point)
{
	dyn_string summary, dummy;
		
	dynAppend(summary, "SNMPManager for: " + point);
	
	string enterpriseOID, iPAddress, genericTrap, specificTrap;
	unsigned timestamp;
	dyn_string payLoadOID, payloadValue;
	
	dynAppend(summary, "SNMPManager for: " + point);
	dpGet(point + ".Trap.EnterpriseOID", enterpriseOID);
	dpGet(point + ".Trap.IPAddress", iPAddress);
	dpGet(point + ".Trap.genericTrap", genericTrap);
	dpGet(point + ".Trap.specificTrap", specificTrap);
	
	dpGet(point + ".Trap.timestamp", timestamp);
	dpGet(point + ".Trap.PayloadOID", payLoadOID);           
	dpGet(point + ".Trap.PayloadValue", payloadValue);

	dynAppend(summary, "Trap");	
	dynAppend(summary, "EnterpriseOID; " + enterpriseOID);
	dynAppend(summary, "IPAddress: " + iPAddress);
	dynAppend(summary, "GenericTrap: " + genericTrap);
	dynAppend(summary, "SpecificTrap: " + specificTrap);
	
	dynAppend(summary, "Timestamp: " + timestamp);
	dynAppend(summary, "PayLoadOID: " + payLoadOID);
	dynAppend(summary, "PayloadValue: " + payloadValue);
	
	dynAppend(summary, "Redirector");	
	dynAppend(summary, "Trapfilter");	
	return summary;
} // dyn_string generateSummary__SNMPManager((string point)

dyn_string generateSummary__SNMPAgent(string point)
{
	dyn_string summary, dummy, errorOID;
	string iPAddress, readCommunity, writeCommunity;
	int timeOut, retries, protocol, port;
	bool timeOutEnabled;
	
	
	dynAppend(summary, "SNMP agent config for: " + point);
	dynAppend(summary, dummy);
	
	// Get Access part
	dynAppend(summary, "Host access");
	dpGet(point + ".Access.IPAddress", iPAddress);
	dynAppend(summary, "IPAddress: " + iPAddress);
	
	dpGet(point + ".Access.ReadCommunity", readCommunity);
	dynAppend(summary, "ReadCommunity: " +  readCommunity);
	
	dpGet(point + ".Access.WriteCommunity", writeCommunity);
	dynAppend(summary, "WriteCommunity: " +  writeCommunity);
	
	dpGet(point + ".Access.Timeout", timeOut);
	dynAppend(summary, "TimeOut" +  timeOut);
	
	dpGet(point + ".Access.Retries", retries);
	dynAppend(summary, "Retries" +  retries);
	
	dpGet(point + ".Access.Protocol", protocol);
	dynAppend(summary, "Protocol" +  protocol);
	
	dpGet(point + ".Access.Port", port);
	dynAppend(summary, "Port:" +  port);
	
	// Get Status	
	dynAppend(summary, dummy);
	dpGet(point + ".Status.Timeout", timeOutEnabled);
	dynAppend(summary, "Time out enabled: " +  timeOutEnabled);
	
	dpGet(point + ".Status.ErrorOID", errorOID);		
	
	dynAppend(summary, dummy);
	dynAppend(summary, "Last OID error(s)");
	dynAppend(summary, "ErrorOID: " + reportLastDynString(errorOID, 6));
	
	return summary;		
} // dyn_string generateSummary__SNMPAgent(string point)

dyn_string generateSummary_sgConnectWithStringInsertion(string point)
{
	dyn_string summary;
	string pattern;
	
	dynAppend(summary, "ConnectWithStringInsertion for the point: " + point);	
	dpGet(point + ".Template", pattern);
	dynAppend(summary, "Pattern: " + pattern);
	
	return summary;
} // dyn_string generateSummary_sgConnectWithStringInsertion(string point)

dyn_string generateSummary_sgFwHistory(string point)
{
	dyn_string summary;
	int historySize, len;
	dyn_string history, dummy;
	
	dynAppend(summary, "7 last history events of " + point);
	dynAppend(summary, dummy);
	dpGet(point + ".HistorySize", historySize);
	dpGet(point + ".ShortHistory", history);
	
	dynAppend(summary, "History size: " + historySize);
	
	dynAppend(summary,  reportLastDynString(history, 6));
	
	return summary;
} // dyn_string generateSummary_sgFwHistory(string point)

dyn_string ConnectWithInt(string point)
{
	dyn_string summary, dynInput, dynOutput, dummy;
	string indent = "   ";
	
	dynAppend(summary, "Input, Output");
	dynAppend(summary, dummy);

	dpGet(point + INPUT_POSTFIX, dynInput);
	dpGet(point + OUTPUT_POSTFIX, dynOutput);
	
	for (int i = 1; i <= dynlen(dynInput); i++)
		dynAppend(summary, dynInput[i] + ", " + dynOutput[i]); 	 

	// DebugN("ConnectWithInt: " + dynlen(summary) + " items");		
	return summary;
} // dyn_string ConnectWithInt(string point)

dyn_string generateSummary_sgXMLUtils(string point)
{
	dyn_string summary, dummy;
	string port, function;

	dpGet(point + ".CallBackConfig.Port", port);
	dpGet(point + ".CallBackConfig.Function", function);
	
	dynAppend(summary, "XML config for " + point);
	dynAppend(summary, dummy);
	
	dynAppend(summary, "Port: " + port);
	dynAppend(summary, "Function: " + function);
	
	return summary;
}

dyn_string generateSummary_sgPRIMUSRadar(string point)
{
	dyn_string summary, dummy;
	bool input2Available, channel4Available;
	string activeRMCDU, fullName, activeChannel, globalStatus;
	
	dynAppend(summary, "PRIMUS Radar");
	dynAppend(summary, dummy);
	
	dpGet(point + ".Input2Available", input2Available);
	dynAppend(summary, "Input2 available: " + translateBooleanValue(input2Available));
	
	dpGet(point + ".Channel4Available", channel4Available);
	dynAppend(summary, "Channel4 available: " + translateBooleanValue(channel4Available));
	
	dpGet(point + ".ActiveRMCDU", activeRMCDU);
	dynAppend(summary, "ActiveRMCDU: " + activeRMCDU);
	
	dpGet(point + ".FullName", fullName);
	dynAppend(summary, "FullName: " + fullName);
	
	dpGet(point + ".ActiveChannel", activeChannel);
	dynAppend(summary, "ActiveChannel:" + activeChannel);
	
	dynAppend(summary, dummy);
	
	dpGet(point + ".GlobalStatus.Status", globalStatus);
	dynAppend(summary, "GlobalStatus:" + globalStatus);
	
	return summary;
} // dyn_string generateSummary_sgPRIMUSRadar(string point)

dyn_string generateSummary_sgConnectWithConvertTable(string point)
{
	return(ConnectWithInt(point));	
} // generateSummary_sgConnectWithConvertTable(string point)

dyn_string generateSummary_sgConnectWithIntRange(string point)
{
	return(ConnectWithInt(point));
} // generateSummary_sgConnectWithConvertTable(string point)

string translate_WagoStatusToString(int status)
{
	switch (status)
	{
		case WAGO_US:	return "US"; break;
		
		case WAGO_INI: return "INI"; break;
		
		case WAGO_OPS: return "OPS"; break;
		
		default: return "Unable to translate int value from WAGO status to string state";
	}
} // translate_WagoStatusToString

string translate_WagoStatusBusToString(int status)
{
	switch (status)
	{
		case WAGO_BUS_US:	return "US"; break;
		
		case WAGO_BUS_DEG: return "INI"; break;
		
		case WAGO_BUS_OPS: return "OPS"; break;
		
		default: return "Unable to translate int value from WAGO bus status to string state";
	}
} // translate_WagoStatusToString


dyn_string generateSummary_sgWAGO(string point)
{
	dyn_string summary, dummy;
	string bus, address;
	int status_A, status_B;
  
  dynAppend(summary, "Module Wago");
  dynAppend(summary, dummy);
  	
	dpGet(point + ".Bus", bus);
	dpGet(point + ".Address", address);
	dpGet(point + ".Status_A", status_A);
	dpGet(point + ".Status_B", status_B);
	
	dynAppend(summary, "Bus: " + bus);
	dynAppend(summary, "Address: " + address);
	
	dynAppend(summary, "Status_A: " + translate_WagoStatusToString(status_A));
	dynAppend(summary, "Status_B: " + translate_WagoStatusToString(status_B));

	return summary;
} // generateSummary_sgWAGO

dyn_string generateSummary_sgWAGOBus(string point)
{
	// DebugN("In the function generateSummary_sgWAGOBus");
	string port, settings;
	dyn_string summary, dummy;
	int baudRate, pollingRate, status_A, status_B;

	dynAppend(summary, "Bus Wago");
  dynAppend(summary, dummy);
	
	dpGet(point + ".Port", port);
	dpGet(point + ".Settings", settings);
	dpGet(point + ".BaudRate", baudRate);
	dpGet(point + ".PollingRate", pollingRate);
	dpGet(point + ".Status_A", status_A);
	dpGet(point + ".Status_B", status_B);
	
	dynAppend(summary, "Port: " + port);
	dynAppend(summary, "Settings: " + settings);
	dynAppend(summary, "Baud rate: " + baudRate);
	dynAppend(summary, "Polling rate: " + pollingRate);
	dynAppend(summary, "Status_A: " + status_A);
	dynAppend(summary, "Status_B: " + status_B);
	
	return summary;
} // dyn_string generateSummary_sgWAGOBus(string point)

dyn_string generateSummary_sgFwTimeoutsConfig(string point)
{
	// Return a dyn_string containing sumary characteristics of the Watch Dog selected
	dyn_string summary, dynRef, dynTimeOuts;
	string dummy, indent = "   ";
	
	dynAppend(summary, "Reference, Time out value");				
	dynAppend(summary, dummy);	
	
	dpGet(point + REFERENCES_POSTFIX, dynRef);
	dpGet(point + TIME_OUTS_POSTFIX, dynTimeOuts);
	
	for (int i = 1; i <= dynlen(dynRef); i++)
		dynAppend(summary, dynRef[i] + ", " + dynTimeOuts[i]); 	 
	
	//DebugN(summary);
	return summary;
} // dyn_string generateSummary_sgFwTimeoutsConfig(string point)

dyn_string generateSummary_sgFwConnections(string point)
{
	// Return a dyn_string containing sumary characteristics of the sgFwConnections selected
	dyn_string ds, inputs, outputs, rules, params, references, defaults;
	int cpt;
	
	dpGet(point + INPUTS_POSTFIX, inputs);
	dpGet(point + OUTPUTS_POSTFIX, outputs);
	dpGet(point + RULES_POSTFIX, rules);
	dpGet(point + PARAMS_POSTFIX, params);
	dpGet(point + REFERENCES_POSTFIX, references);
	dpGet(point + DEFAULT_VALUES_POSTFIX, defaults);
	
	for(cpt = 1; cpt <= dynlen(inputs); cpt++)
	{
		dynAppend(ds, inputs[cpt] + " -> " + outputs[cpt] + ", " + rules[cpt] + "(" + params[cpt] + ") ref = " + references[cpt] + " def = " + defaults[cpt]);
	}
	return ds;
} // dyn_string generateSummary_sgConnections(string dpName)


dyn_string generateSummary_sgXMLMatchingTable(string dpName)
{
	// Return a dyn_string containing sumary characteristics of the sgXML Matching Table selected
	dyn_string summary, dynInput, dynOutput;
	string value, dummy, indent = "   ";
	string temp, stringValue;
	// DebugN("Name of the point: " + dpName);

	// Inputs
	//DebugN("XML Input: " + dpName + INPUT_XML_MATCHING_TABLE_POSTFIX);
		
	temp = "Input, Output";
	dynAppend(summary, temp);				
	dynAppend(summary, dummy);	
	dpGet(dpName + INPUT_XML_MATCHING_TABLE_POSTFIX, dynInput);
	dpGet(dpName + OUTPUT_XML_MATCHING_TABLE_POSTFIX, dynOutput);
	//temp = indent + "Output: " + dynSplit(dynValue);		
	for (int i = 1; i <= dynlen(dynInput); i++)
		dynAppend(summary, dynInput[i] + " , " + dynOutput[i]);	
	
	return summary;
} // dyn_string generateSummary_sgFwConnections(string dpName)

dyn_string generateSummary_sgFwSystem(string dpName)
{
	// Return a dyn_string containing sumary characteristics of the sgFwSystem selected
	dyn_string summary, dynValue;
	string value, dummy, indent = "   ";	
	string temp, stringValue;
	
	//DebugN("Name of the point: " + dpName);
//	temp = "sgFwSystem characteristics";
//	dynAppend(summary, temp);				
//	dynAppend(summary, dummy);
	
	// Component text
	value = dpGetDescription(dpName);
	dynAppend(summary, "Component Text = " + value);
	dynAppend(summary, dummy);
	
	// params table
	dpGet(dpName + PARAMS_POSTFIX, value);
	dynAppend(summary, "Parameters table = " + value);
	dynAppend(summary, dummy);
	
	// disabled, SubDisabled, Hidden
	dpGet(dpName + DISABLED_POSTFIX, value);
	stringValue = translateBooleanValue(value);
	
	string indent = "   ";	
	temp = "Disabled: " + stringValue;

	dpGet(dpName + SUB_DISABLED_POSTFIX, value);
	stringValue = translateBooleanValue(value);	
	temp += indent + "SubDisabled: " + stringValue;
		
	dpGet(dpName + HIDDEN_POSTFIX, value);
	stringValue = translateBooleanValue(value);
	temp += indent + "Hidden: " + stringValue;
	dynAppend(summary, temp);
	dynAppend(summary, dummy);
	
	// Prestatus, Status, StatusDelay
	dpGet(dpName + PRE_STATUS_POSTFIX, value);
	temp = "PreStatus: " + value;
	
	dpGet(dpName + STATUS_POSTFIX, value);
	temp += indent + "Status: " + value;
	
	dpGet(dpName + STATUS_DELAY_POSTFIX, value);
	temp += indent + "Status Delay: " + value;
	dynAppend(summary, temp);		
  dynAppend(summary, dummy);

  // Labels
  dpGet(dpName + LABEL1_POSTFIX, value); 
  temp = "Label1: " + value;
   
  dpGet(dpName + LABEL2_POSTFIX, value); 
  temp += indent + "Label2: " + value;
  
  dpGet(dpName + LABEL3_POSTFIX, value); 
  temp += indent + "Label3: " + value;

  dpGet(dpName + LABEL4_POSTFIX, value); 
  temp += indent + "Label4: " + value;

  dynAppend(summary, temp);
  dynAppend(summary, dummy);
  
  // Message
  dpGet(dpName + MESSAGE_POSTFIX, value); 
  dynAppend(summary, "Message: " + value);
  dynAppend(summary, dummy);
  
  
  // Events, Event text, histories
	dpGet(dpName + EVENT_GENERATE_EVENT_POSTFIX , value);
	temp = "Generate Events: " + translateBooleanValue(value);
	dynAppend(summary, temp);		
	if (value != "FALSE")
	{
	 	// Generate events..
	 	dpGet(dpName + EVENT_TEXT_POSTFIX, value);
		temp = indent + "Event Text: " + value;
		dynAppend(summary, temp);		
		
		dpGet(dpName + EVENT_HISTORIES_POSTFIX, dynValue);
		
		dynAppend(summary, indent + "History Queues: " + dynSplit(dynValue));		
	} // Generate events
	dynAppend(summary, dummy);
	
	// Alarms
	dpGet(dpName + GENERATE_ALARMS_POSTFIX , value);
	temp = "Generate Alarms: " + translateBooleanValue(value);
	dynAppend(summary, temp);		
	
	if (value != "FALSE")
	{
		// Text	
		dpGet(dpName + ALARM_TEXT, value);
		temp = indent + "Text: " + value;
		dynAppend(summary, temp);			
				
		// Panel
		dpGet(dpName + ALARM_PANEL, value);
		if (value != "")
		{
	//		DebugN("Panel: " + dpName + ALARM_RULE);
			temp = indent + "Panel: " + value;
			dynAppend(summary, temp);
			
			// Panel params
			dpGet(dpName + ALARM_PANEL_PARAM, dynValue);
			dynAppend(summary, indent + "Panel params: " + dynSplit(dynValue));	
		} // Panel defined
	} // Generate alarms
	dynAppend(summary, dummy);
	
	// Logic
	dpGet(dpName + LOGIC_ENABLED_POSTFIX , value);
	temp = "Logic: " + translateBooleanValue(value);
	dynAppend(summary, temp);			
	
	if (value != "FALSE")
	{
		// Rule
		dpGet(dpName + LOGIC_RULE_POSTFIX, value);
		temp = indent + "Rule: " + value;
		dynAppend(summary, temp);
		
		// Inputs
		dpGet(dpName + LOGIC_INPUTS_POSTFIX, dynValue);
		dynAppend(summary, indent + "Input(s)");
		for (int i = 1; i <= dynlen(dynValue); i++)
		{
			dynAppend(summary, indent + indent + dynValue[i]);	
		}
	} // logic enabled
	return summary;
} // dyn_string generateSummary_sgFwSystem(string dpName)
