
// Version 1.0
//
// Date AUG-06
//
// This file contains the connection to get internal PVSS statuses
// History
// =======
// 09-AUG-06 : First version (PW)
// 16-AUG-06 : Integration in the present Library
// 20-SEP-06 : creation of sgFwConnectPVSSStatus to have only one function (PW / AJ)

// Connect PVSS internal statuses 
void sgFwConnectPVSSStatuses()
{
	dpConnect("sgFwConnectPVSSStatus", "_Connections.Ui.ManNums",	"_Connections_2.Ui.ManNums", 
						"_ReduManager.PeerAlive.Link0", "_ReduManager_2.PeerAlive.Link0",	
						ACTIVE_CHAIN);
	
	dpConnect("sgFwConnectPVSSStatus", "_Connections.Driver.ManNums",	"_Connections_2.Driver.ManNums", 
						"_ReduManager.PeerAlive.Link0", "_ReduManager_2.PeerAlive.Link0",	
						ACTIVE_CHAIN);

	dpConnect("sgFwConnectPVSSStatus", "_Connections.Redu.ManNums", "_Connections_2.Redu.ManNums", 
						"_ReduManager.PeerAlive.Link0", "_ReduManager_2.PeerAlive.Link0",	
						ACTIVE_CHAIN);

	dpConnect("sgFwConnectPVSSStatus", "_Connections.Dist.ManNums", "_Connections_2.Dist.ManNums", 
						"_ReduManager.PeerAlive.Link0", "_ReduManager_2.PeerAlive.Link0",	
						ACTIVE_CHAIN);
}

// Set managers statuses
void sgFwConnectPVSSStatus(string connADpName, dyn_int manNumsA, string connBDpName, dyn_int manNumsB,
											string reduLinkADpName, bool reduLinkAOk, string reduLinkBDpName, bool reduLinkBOk,
											string activeChainDpName, string activeChain)
{
	string status;

	// extract manager name
	dyn_string ds;
	dyn_string pvssStatusDpNames;
	
	ds = strsplit(connADpName, ".");
	
	pvssStatusDpNames =	dpNames("PVSSStatuses.Chain*." + ds[2] + "*"); //Type is the second value
	
	for(int i = 1; i <= dynlen(pvssStatusDpNames); i++)
	{
		bool activeChainReduLink;
		bool onActiveChain;
		int manNum;
		string manType;
		string chain;
				
		ds = strsplit(pvssStatusDpNames[i], ".");
		
		// determine manager type to treat the dist manager case
		manType = substr(ds[3], 0, strlen(ds[3]) - 2);

		// if not dist manager, man num = the manager number
		if(manType != "Dist")
			manNum = substr(pvssStatusDpNames[i], strlen(pvssStatusDpNames[i]) - 2); // get manager No from dpNames
		else // case dist manager, get system Id
			manNum = getSystemId();
		
		// determine if dp for chain A or B
		chain = substr(ds[2], strlen(ds[2]) - 1);
		
		if(activeChain == "A")
			activeChainReduLink = reduLinkAOk;
		else if(activeChain == "B")
			activeChainReduLink = reduLinkBOk;
		else 	// case active chain = "X"
			activeChainReduLink = false; 
			
		if(activeChain == chain)
			onActiveChain = true;
		else 
			onActiveChain = false;

		if( ((dynContains(manNumsA, manNum) >= 1) && (chain == "A")) ||	((dynContains(manNumsB, manNum) >= 1) && (chain == "B")) )
			status =	sgFwGetPVSSStatus(true, activeChainReduLink, onActiveChain);
		else
			status =	sgFwGetPVSSStatus(false, activeChainReduLink, onActiveChain);
		
		dpSet(pvssStatusDpNames[i] + PRE_STATUS_POSTFIX, status);
	}
}

// return PVSS managers status
string sgFwGetPVSSStatus(bool isConnected, bool activeChainReduLink, bool onActiveChain)
{
	string status;

	if(onActiveChain)
	{
		if(isConnected)
			status = OPS_STATUS;
		else
			status = U_S_STATUS;
	}
	else  // not on active chain
	{
		if(!activeChainReduLink)
			status = UKN_STATUS;
		else
			if(isConnected)
				status = SBY_STATUS;
			else
				status = U_S_STATUS;
	}		
	return status;
}


