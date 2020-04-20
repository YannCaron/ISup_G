int myHostNum;		

const string PVSS_STATUSES_PREFIX = "PVSSStatuses.";

main()
{

	int cpt = 1;
	time CurrentTime;
	string stringTime;
	string currentChain;

	if(isServerA(getHostname()))
		currentChain = "A";	
	if(isServerB(getHostname()))
		currentChain = "B";

// Select the host
 	myHostNum = initHosts();

	while(true)
	{	
		string activeChain;
	
		dpGet(ACTIVE_CHAIN, activeChain);

		setPVSSManagerStatus("Dist", currentChain, activeChain);
		setPVSSManagerStatus("Driver", currentChain, activeChain);
		setPVSSManagerStatus("Redu", currentChain, activeChain);
		setPVSSManagerStatus("Ui", currentChain, activeChain);
		setChainStatus(currentChain, activeChain);

		delay(2);
	}
}

void setChainStatus(string chain, string activeChain)
{
	string status;
	string name;
	
	name = "PVSSStatuses.Chain" + chain + "WatcherStatus.PreStatus";

	if( (activeChain == "A" && chain == "A") || (activeChain == "B" && chain == "B") )
		status = OPS_STATUS;  // -> OPS		
	else
		status = SBY_STATUS;  // -> SBY		
	
	dpSet(name, status);
}


void setPVSSManagerStatus(string managerType, string chain, string activeChain)
{
	dyn_string names;
	dyn_bool values;
	string status ;
	int i;
	dyn_int managersNrList;
	string name;
	string managerName;
	
	if(chain == "A")
		managerName = "_Connections." + managerType+ ".ManNums";	
	if(chain == "B")
		managerName = "_Connections_2." + managerType+ ".ManNums";	
	
	dpGet(managerName, managersNrList);
	
	if(managerType == "Dist")
	{
		int distManNum;
		
		distManNum = getSystemId(getSystemName());
		
		name = PVSS_STATUSES_PREFIX + "Chain" + chain + ".Dist01.PreStatus";
		if(dynContains(managersNrList, distManNum) != 0)
		{
			if( (activeChain == "A" && chain == "A") || (activeChain == "B" && chain == "B") )
				status = OPS_STATUS;  // -> OPS		
			else
				status = SBY_STATUS ;  // -> SBY		
		}
		else
			status = U_S_STATUS;  // -> U/S		
		dpSet(name, status);
	}
	else 
	// other managers types
	{
		// get all points from pattern		
		names = dpNames(PVSS_STATUSES_PREFIX + "Chain" + chain + "." + managerType + "*.PreStatus");

		// Driver list must always start at 01
		for(i = 1 ; i <= dynlen(names); i++)
		{
			// in case of a manager number > 10
			if(i < 10)
				name = PVSS_STATUSES_PREFIX + "Chain" + chain + "." + managerType + "0" + i + ".PreStatus";
			else
				name = PVSS_STATUSES_PREFIX + "Chain" + chain + "." + managerType + i + ".PreStatus";
	
			if(0 == dynContains(managersNrList, i))
				status = U_S_STATUS;  // -> U/S		
			else 
			{
				if( (activeChain == "A" && chain == "A") || (activeChain == "B" && chain == "B") )
					status = OPS_STATUS ;  // -> OPS		
				else
					status = SBY_STATUS ;  // -> SBY		
			}
			dpSet(name, status);
		}
	}
}










