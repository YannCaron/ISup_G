// connect 2 points, with rule and parameters
const string DBKEY_CONNECTIONS_BUFFER1 = "ConnectionsBuffer1";
const string DBKEY_CONNECTIONS_BUFFER2 = "ConnectionsBuffer2";
private const string POSTFIX_USERBIT1 = ":_original.._userbit1";
private const string POSTFIX_USERBIT_INVALID = POSTFIX_USERBIT1;

int gConnectionsBufferInUse = 1;


void fwConnect(string input, string output, string rule, string params)
{

	if(rule == "ConnectDescription")
	{
		dpConnect("connectDescription", false, input, output + DESCRIPTION_DUMMY);
		return;
	}

	if(rule == "ConnectWithConvertTable")
	{
		dpConnect("writeConvertedValue", false, input, output, params + ".Input", params + ".Output");
		return;
	}
	if(rule == "ConnectWithConvertTableInvalid")
	{
   string invalidbit = input + POSTFIX_USERBIT_INVALID;
		dpConnect("writeConvertedValueInvalid", true, input, invalidbit, output, params + ".Input", params + ".Output");
		return;
	}
	if(rule == "ConnectWithIntRange")
	{
 		dpConnect("convertIntRangeToStatus", true, input, output, params + ".Input", params + ".Output");
//		dpConnect("convertIntRangeToStatus", false, input, output, params + ".Input", params + ".Output");
		return;
	}
	if(rule == "ConnectWithIntRangeInvalid")
	{
   string invalidbit = input + POSTFIX_USERBIT_INVALID;
 		dpConnect("convertIntRangeToStatusInvalid", true, input, invalidbit, output, params + ".Input", params + ".Output");
		return;
	}
  if(rule == "ConnectWithStringInsertion")
	{
		dpConnect("connectStringInsertion", false, input, output, params + TEMPLATE_POSTFIX);
		return;
	}
	if(rule == "ConnectCopy")
	{
		dpConnect("connectCopy", false, input, output);
		return;
	}

	if(rule == "ConnectWithSubstraction")
	{
		// ConnectWithSubstraction(string sourceName, int sourceValue, string destName, string destValue, string paramName, int paramValue)
		dpConnect("ConnectWithSubstraction", false, input, output, params);
		return;
	}

	// 20070322 aj added rule for diskspacecheck
	if (rule == "ConnectDiskSpace")
	{
		// activeChain is included to trigger a workfunction call after a switchover (OPS<->SBY)
		dpConnect("ConnectDiskSpace", true, input, output, params + ".Input", params + ".Output", "_ReduManager.PeerAlive.Link0", "_ReduManager_2.PeerAlive.Link0", ACTIVE_CHAIN);
		return;
	}

  // 20121008 yn pw add table connection rule
	if(rule == "ConnectTableIndexWithConvertTable")
	{
		dpConnect("connectTableIndexWithConvertTable", true, 
              input + ".TableIdentifier", 
              input + ".TableState", 
              input + ".SearchName", 
              output,
              params + ".Input", 
              params + ".Output");
		return;
	}
  
	if(rule == "ConnectWMIServiceWithConvertTable")
	{
		dpConnect("connectWMIServiceWithConvertTable", true, 
              input + ".State", 
              input + ".Status", 
              output,
              params + ".Input", 
              params + ".Output");
		return;
	}

	if(rule == "ConnectActiveMQJmxHealth")
 	{ 
		int res =	dpConnect("connectActiveMQJmxHealth", true, 
			input, 
			output, 
			params + ".Input",
			params + ".Output", 
			ACTIVE_CHAIN);
  		return;
	}   

	sgFwSpecificConnections(input, output, rule, params);

}



bool initFwConnections()
{
	dyn_string inputs;
	dyn_string outputs;
	dyn_string rules;
	dyn_string params;
	dyn_string points;
	int cpt;
	int cptPoints;
	string starValue;
	string output;

	dyn_string connections;

	connections = getPointsOfType("sgFwConnections");

	sgDBCreateTable(DBKEY_CONNECTIONS_BUFFER1);
	sgDBCreateTable(DBKEY_CONNECTIONS_BUFFER2);

	for(int cptConnections = 1; cptConnections <= dynlen(connections); cptConnections++)
	{
		dyn_string tempInputs;
		dyn_string tempOutputs;
		dyn_string tempRules;
		dyn_string tempParams;
		dyn_string tempReferences;
		dyn_string tempDefaultValues;
		dpGet(connections[cptConnections] + INPUTS_POSTFIX, tempInputs,
					connections[cptConnections] + OUTPUTS_POSTFIX, tempOutputs,
					connections[cptConnections] + RULES_POSTFIX, tempRules,
					connections[cptConnections] + PARAMS_POSTFIX, tempParams);

		if ((dynlen(tempInputs) != dynlen(tempOutputs)) || (dynlen(tempInputs) != dynlen(tempRules)) || (dynlen(tempInputs) != dynlen(tempParams)))
		{
			DebugN("Connection: " + connections[cptConnections] + " is bad: fields length have not the same values");

			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "Connection: " + connections[cptConnections] + " is bad: fields length have not the same values");
			return false;
		}

		dynAppend(inputs, tempInputs);
		dynAppend(outputs, tempOutputs);
		dynAppend(rules, tempRules);
		dynAppend(params, tempParams);
	}
	for(cpt = 1; cpt <= dynlen(inputs); cpt++)
	{
		points = getPointsFromPattern(inputs[cpt]);

		for(cptPoints = 1; cptPoints <= dynlen(points); cptPoints++)
		{
			starValue = findStarValue(inputs[cpt], points[cptPoints]);

			output = replaceStar(outputs[cpt], starValue);

			fwConnect(points[cptPoints], output, rules[cpt], replaceStar(params[cpt], starValue));

		}
	}
	return true;
}

void sgConnectionDpSet(string dpName, string dpVal)
{
	string val;

	val = dpVal;

	if(val == "")
		val = " ";

	if(gConnectionsBufferInUse == 1)
		sgDBSet(DBKEY_CONNECTIONS_BUFFER1, dpName, val);
	else
		sgDBSet(DBKEY_CONNECTIONS_BUFFER2, dpName, val);
}


void sgConnectionsFlush()
{
	dyn_string names;
	dyn_string values;

	//VL: 22-JUN-2005: added this test to avoid any overhead by flushing and crossing empty buffers
	int fullLen;
	fullLen = dynlen(sgDBTableKeys(DBKEY_CONNECTIONS_BUFFER1)) + dynlen(sgDBTableKeys(DBKEY_CONNECTIONS_BUFFER2));

	if(fullLen == 0)
	{
//		DebugTN("sgConnectionsFlush: nothing to flush");
		return;
	}

	string flushBuffer;
	if(gConnectionsBufferInUse == 1)
	{
		gConnectionsBufferInUse = 2;
		flushBuffer = DBKEY_CONNECTIONS_BUFFER1;
	}
	else
	{
		gConnectionsBufferInUse = 1;
		flushBuffer = DBKEY_CONNECTIONS_BUFFER2;
	}

	delay(0,10);

	names = sgDBTableKeys(flushBuffer);
	for(int cpt = 1; cpt <= dynlen(names); cpt++)
	{
		dyn_string ds;

		ds = sgDBGet(flushBuffer, names[cpt]);

		if(dynlen(ds) != 1)
		{
			if(dynlen(ds) == 0)
			{
				DebugTN("sgConnectionsLib, flush: no values for key " + names[cpt]);
			}
			else
			{
				DebugTN("sgConnectionsLib, flush: values for key " + names[cpt] + " is " + ds);
			}
		}

		dynAppend(values, ds);
		sgDBRemove(flushBuffer, names[cpt]);
	}

	if(dynlen(names) != dynlen(values))
	{
		DebugTN("sgConnectionsFlush: " + dynlen(names) + " / " + dynlen(values));
		DebugTN(names);
	}

	if(dynlen(names) != 0)
	{
//		DebugTN("sgConnectionsFlush: will set " + dynlen(names) + " " + dynlen(values) + " values");
		dpSet(names, values);
	}
}
