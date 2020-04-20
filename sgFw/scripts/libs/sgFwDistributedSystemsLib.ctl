
// skyguide framework distributed systems library
// Functions around distributed systems
// JAN 2006 PW/AJ

dyn_string removeExcludedSystems(dyn_string &distributedSystems)
{

	// variable
	dyn_string excludedSystems;
	int index;
	
	// get datapoints
	dpGet(EXCLUDED_SYSTEMS, excludedSystems);

	for (int i=1; i<=dynlen(excludedSystems); i++)
	{
		excludedSystems[i] = substr(excludedSystems[i], 0, strlen(excludedSystems[i]) - 1);
		index = dynContains(distributedSystems, excludedSystems[i]);
		dynRemove(distributedSystems, index);
	}

}

dyn_string getDistributedSystems(bool local, bool exclude)
{

	// variable
	dyn_string distributedSystems;
	string localSystem = getSystemName();
	
	// get datapoints
	distributedSystems = getPointsOfType (DISTRIBUTED_SYSTEM_TYPE);

	// remove excluded
	if (exclude) 
		removeExcludedSystems(distributedSystems);

	// append local system
	if (local)
		dynInsertAt(distributedSystems, substr(localSystem, 0, strlen(localSystem)-1),1);

	return distributedSystems;

}

void connectDistributionStatuses()
{
	string connectionDistDp;
	string distConnectionDistDp;
	string distManDistDp;
	string reduPostFix = "";

	if(isChainB())
		reduPostFix = "_2";
	
	connectionDistDp = "_Connections" + reduPostFix + ".Dist.ManNums";
	distConnectionDistDp = "_DistConnections" + reduPostFix + ".Dist.ManNums";
	// added _DistManager because after _DistConnection is updated, getSystemId still returns -1 until the DPID is exchanged
	// _DistManager will trigger the callback after the DPID
	// BUT: it is not possible to remove the _DistConnection as the _DistManager doesn't show
	// if there is a connection to both remote servers or only one	
	distManDistDp = "_DistManager" + reduPostFix + ".State.SystemNums";

	dpConnect("setDistributedSystemsStatuses", connectionDistDp, distConnectionDistDp, distManDistDp, ACTIVE_CHAIN);
			
}

void setDistributedSystemsStatuses(string connDistDp, dyn_string connDistManNums, 
																	string distConnDistDp, dyn_string distConnDistManNums,
																	string distManDp, dyn_string distManSysNums,
																	string activeChainDp, string activeChain)
{
	dyn_string distributedSystems;
	string chain;
	string okStatus;
	string status;
	int systemId;
	
	if (isChainA())
		chain = "A";
	else if (isChainB())
		chain = "B";
	
	if (chain == activeChain)
		okStatus = OPS_STATUS;
	else
		okStatus = SBY_STATUS;
	
	distributedSystems = getPointsOfType("sgFwDistributedSystems");
	
	// check if local distribution manager is alive
	if(dynlen(connDistManNums) == 1)
	{
		// check to reach systems which are connected
		for(int i = 1; i <= dynlen(distributedSystems); i++)
		{
			// get remote system ID, -1 if not known
			systemId = getSystemId(distributedSystems[i]+ ":");
			
			int indexA = 0;
			if (systemId >= 1)	// check if system is known
				indexA =	dynContains(distConnDistManNums, systemId);
			
			int redundant;
			isRemoteSystemRedundant(redundant,distributedSystems[i]);
			
			if (redundant == 1)
			{
				int indexB = 0;
				// checking if negative systemnumber is also included
				// negative system number corresponds to host B
				if (systemId >= 1) // check if system is known
					indexB =	dynContains(distConnDistManNums, (0 - systemId));
				
				if ((indexA >= 1) && (indexB >= 1))
					status = okStatus;
				else if ((indexA >= 1) || (indexB >= 1))
					status = DEG_STATUS;
				else
					status = U_S_STATUS;

			}
			else
			{
				if (indexA >= 1)
					status = okStatus;
				else
					status = U_S_STATUS;
			}

			dpSet(distributedSystems[i] + ".DistributedStatus" + chain + PRE_STATUS_POSTFIX, status);
		}
	}
	else
	{
		// if own dist manager is not running set all to U/S
		for(int i = 1; i <= dynlen(distributedSystems); i++)
			dpSet(distributedSystems[i] + ".DistributedStatus" + chain + PRE_STATUS_POSTFIX , U_S_STATUS);
	}
}