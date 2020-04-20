dyn_dyn_string gIPAddresses;
dyn_dyn_string gRules;
dyn_string gPrefixes;
dyn_string gHistoryDP;

// yca [2010.05.19] get ip by hosts names
dyn_string getIpAddresses(dyn_string ds)
{
  dyn_string addr_list; // unused
  dyn_string ips;
 
  for (int i = 1; i<=dynlen(ds); i++) {
    string ip = getHostByName(ds[i], addr_list);
    dynAppend(ips, ip);
  }
  
  return ips;
}

void startTrapsDispatcher(int driverNumber)
{
	dyn_string dispatchers;
	dispatchers = getPointsOfType("sgTrapsDispatcher");
	// DebugN("Dispatcher: " + dispatchers);
	
 	for (int cpt = 1; cpt <= dynlen(dispatchers); cpt++)
 	{
 		// 21.07.2005 aj historyDP added to be able to use the library for EMNet as well
 		// therefore a DPT using a sgTrapsDispatcher has to have a SystemHistory directly below the root element!!
 		dynAppend(gHistoryDP, dpSubStr(dispatchers[cpt], DPSUB_DP) + ".SystemHistory");
 		
 		dyn_string ds;
 		dpGet(dispatchers[cpt] + ".IPAddresses", ds);
                // yca [2010.05.19] get ip by hosts names
 		gIPAddresses[cpt] = getIpAddresses(ds);
                //DebugTN("IPAddresses = " + gIPAddresses[cpt]);
 		
 		dpGet(dispatchers[cpt] + ".Rules", ds);
 		gRules[cpt] = ds;
                //DebugTN("Rules = " + gRules[cpt]);
 		
 		string s;
 		dpGet(dispatchers[cpt] + ".OIDPrefix", s);
 		dynAppend(gPrefixes,s);
                //DebugTN("OISPrefixes = " + gPrefixes);
 	}
	
	//DebugTN("sgTrapsDispatcherLib: ",gHistoryDP);
		
	string managerName;

	//29.06.2005 aj connect to the _SNMPManager or _SNMPManager_2 according to chain
	if (isServerA(getHostname()))
		managerName = "_" + driverNumber + "_SNMPManager";
	else if (isServerB(getHostname()))
		managerName = "_" + driverNumber + "_SNMPManager_2";
	//29.06.2005 aj connect to the _SNMPManager or _SNMPManager_2 according to chain
		
	dpConnect("trapsReceived", false, managerName + ".Trap.IPAddress", managerName + ".Trap.PayloadOID", managerName + ".Trap.PayloadValue");

}

string convertDynStringToString(dyn_string ds)
{
	string str;
	for (int cpt = 1; cpt <= dynlen(ds); cpt++)
		str += ", " + ds[cpt];
		
	return str;
	
}

void trapsReceived(string ipDpName, string ipValue, string oidDpName, dyn_string oids, string valuesDpName, dyn_string values)
{
	string ip;
        
        // 20071010 aj - change in PVSS II 3.6
        // if port is not there, take ip as it is
        if (strpos(ipValue,"/") > -1)
          ip = substr(ipValue, 0, strpos(ipValue,"/"));
        else
          ip = ipValue;
  
      	int index;
	index = findDispatcherIndex(ip);
 
  string oidList = convertDynStringToString(oids);   // Modified P.Wulliens 2018-01-10; Optinet Timeout Problem without full traps log
  string valueList = convertDynStringToString(values); // Modified P.Wulliens 2018-01-10; Optinet Timeout Problem without full traps log
 
	if (index != 0)
	{
			//DebugTN("trapsReceived >> ip source: " + ipValue + " oid list: " + oidList + " oid values: " + valueList);
		sgHistoryAddEvent(gHistoryDP[index], SEVERITY_SYSTEM, "trapsReceived >> ip source: " + ipValue + " oid list: " + oidList + " oid values: " + valueList);
		execMatchingRule(index, oids, values);	
	}
	else
	{
 		// 21.07.2005 aj history is choosen dynamically but if the IP is ignored no dispatcher is associated
 		// therefore write it to all TrapsDispatcher-SystemHistories 
 		for (int cptHistories = 1; cptHistories <= dynlen(gHistoryDP); cptHistories++)
 			sgHistoryAddEvent(gHistoryDP[cptHistories], SEVERITY_SYSTEM, "trapsReceived >> trap received from: " + ipValue + " but ignored because not in any dispatcher list: oid list: " + oidList + " oid values: " + valueList);
	}
}

void execMatchingRule(int index, dyn_string oids, dyn_string values)
{
  bool called = false;
  int cpt = 1;
	dyn_string rules;
	rules = gRules[index];

  // Do not call twice for Optinet YCA [07-09-2010]
  while (!called && cpt <=dynlen(rules)) {
	//for (int cpt = 1; cpt <= dynlen(rules); cpt++)
	//{
		bool found = true;
		dyn_string ds = strsplit(rules[cpt], "-");
		string functionName;
		functionName = ds[1];
		dynRemove(ds, 1);

		for (int id = 1; id <= dynlen(ds); id++)
		{
      //DebugN("complet OID from rule: " + gPrefixes[index] +  + "." + ds[id]);
      // DebugN("received OID         : " + oids);
			/*if (!dynContains(oids, gPrefixes[index] + "." + ds[id]))
			{
				found = false;
				break;
			}

      Replaced for OPTINET [YCA - PWU 02-09-2010]
			*/
			dyn_string pattern = dynPatternMatch(gPrefixes[index] + "." + ds[id], oids);
			if (dynlen(pattern) == 0)
			{
				found = false;
				break;
			}                  
		} 
		//DebugTN("Found = " + found + " oid = " + oids + " prefixes " + gPrefixes[index]);			
		if (found)
		{					
			// DebugN("The function: " + functionName + " can be executed because we found all needed oids");
			// retrive parameters for the call function
			if (dynlen(oids) != dynlen(values))
			{
				sgHistoryAddEvent(gHistoryDP[index], SEVERITY_SYSTEM, "execMatchingRule >> receive " + dynlen(oids) + " oids + and " + dynlen(values) + " values");
				return;
			}
						
			string parameters;
			for (int id = 1; id <= dynlen(ds); id++)
			{
				int idx = 0;
		 		/*idx = dynContains(oids, gPrefixes[index] + "." + ds[id]);
                                  
				Replaced for OPTINET [YCA - PWU 02-09-2010]
        */
				dyn_string pattern = dynPatternMatch(gPrefixes[index] + "." + ds[id], oids);
        if (dynlen(pattern) > 0) {
          idx = dynContains(oids, pattern[1]);
        }
		 				 		
				if (id > 1)	parameters += ",";
				parameters += "\"" + values[idx] + "\"" ;
			}
			
			string script;
			// the script run in an other process -> script must contain the main function, function must be in a library, 
			// 21.07.2005 aj add additional parameter as same function can be used for ScNet and EMNet
			string netType = dpSubStr(gHistoryDP[index], DPSUB_DP);
			script = "void main() { " + functionName + "(\"" + netType + "\"," + parameters + ");}";
			//DebugTN("execMatchingRule >> script: " + script);
			execScript(script, makeDynString(""));
      called = true;
		} // found = true
    cpt ++;
	}
} 

int findDispatcherIndex(string ipAddress)
{
	for (int cpt = 1; cpt <= dynlen(gIPAddresses); cpt++)
	{
		if (dynContains(gIPAddresses[cpt], ipAddress))
		{
			return cpt;
		}
	}
	//DebugTN("findDispatcherIndex >> Dispatcher not found for  ipAddress: " + ipAddress);
	return 0;
}

