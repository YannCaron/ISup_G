string myChain;
string fwStatusDpName;
string currentStatus;

int gFwDebugLevel;

bool gInitFinished;

void main()
{
	gInitFinished = false;
	bool b;
	time start;
	float delta;
	
	writeFwStatus(INI_STATUS);
	
	dpConnect("sgFw2DebugLevelChanged", false, "FwUtils.Commands.DebugLevel");
		
	dpGet("FwUtils.Commands.DebugLevel", gFwDebugLevel);
 
	sgDBWaitForInit();
	
//	DebugTN("Start");
	bool timingsTrace;
	
	sgDBCreateTable(DBKEY_DELAYED_SYSTEMS);
	
	start = getCurrentTime();
	b = sgHistoriesInit();
	if(!b)
	{
		DebugTN("Histories initialisation failed");
		return;
	}
	delta = getCurrentTime() - start;
	if(gFwDebugLevel)
		DebugTN("Histories initialised in " + delta);

	start = getCurrentTime();
	b = sgAELoadTables();
	if(!b)
	{
		DebugTN("AE Tables initialisation failed");
		sgRefreshShortHistories(false);		
		return;
	}
	delta = getCurrentTime() - start;
	if(gFwDebugLevel)
		DebugTN("AE Tables initialised in " + delta);
	
	start = getCurrentTime();
	b = sgTTLoadTables();
	if(!b)
	{
		DebugTN("Truth tables initialisation failed");
		sgRefreshShortHistories(false);		
		return;
	}
	delta = getCurrentTime() - start;
	if(gFwDebugLevel)
		DebugTN("Truth tables initialised in " + delta);
	
	start = getCurrentTime();
	b = sgFwLoadParams();
	if(!b)
	{
		DebugTN("Params initialisation failed");
		sgRefreshShortHistories(false);		
		return;
	}
	delta = getCurrentTime() - start;
	if(gFwDebugLevel)
		DebugTN("Params initialised in " + delta);
		
	start = getCurrentTime();
	b = sgFwLoadSystems();
	if(!b)
	{
		DebugTN("FwSystems initialisation failed");
		sgRefreshShortHistories(false);		
		return;
	}
	delta = getCurrentTime() - start;
	if(gFwDebugLevel)
		DebugTN("FwSystems initialised in " + delta);

	start = getCurrentTime();
	b = sgFwLoadBitStates();
	if(!b)
	{
		DebugTN("FwBitStates initialisation failed");
		sgRefreshShortHistories(false);		
		return;
	}
	delta = getCurrentTime() - start;
	if(gFwDebugLevel)
		DebugTN("FwBitStates initialised in " + delta);

	start = getCurrentTime();
	b = sgFwBuildParentInputLinks();
	if(!b)
	{
		DebugTN("Input - Parents links initialisation failed");
		sgRefreshShortHistories(false);		
		return;
	}
	delta = getCurrentTime() - start;
	if(gFwDebugLevel)
		DebugTN("FwSystems input - parents links initialised in " + delta);	


	start = getCurrentTime();
	b = sgFwConnectBitStates();
	if(!b)
	{
		DebugTN("Bits States connections initialisation failed");
		sgRefreshShortHistories(false);		
		return;
	}
	delta = getCurrentTime() - start;
	if(gFwDebugLevel)
		DebugTN("FwBit states connected in " + delta);		


	start = getCurrentTime();
	b = sgFwConnectSystems();
	if(!b)
	{
		DebugTN("Systems connections initialisation failed");
		sgRefreshShortHistories(false);		
		return;
	}
	delta = getCurrentTime() - start;
	if(gFwDebugLevel)
		DebugTN("FwSystems connected in " + delta);		

	start = getCurrentTime();
	b = initFwConnections();
	if(!b)
	{
		DebugTN("Connections initialisation failed");
		sgRefreshShortHistories(false);		
		return;
	}
	delta = getCurrentTime() - start;
	if(gFwDebugLevel)
		DebugTN("Connections initialised in " + delta);		
			
	start = getCurrentTime();
	b = sgWDInit();
	if(!b)
	{
		DebugTN("Watch dogs initialisation failed");
		sgRefreshShortHistories(false);		
		return;
	}
	delta = getCurrentTime() - start;
	if(gFwDebugLevel)
		DebugTN("Watch dogs inialized in " + delta);
	
	sgRefreshShortHistories(false);		
	
	start = getCurrentTime();
	b = sgInitAckAllAlarms();
	if(!b)
	{
		DebugTN("Init Ack all Alarms failed");
		sgRefreshShortHistories(false);		
		return;
	}
	delta = getCurrentTime() - start;
	if(gFwDebugLevel)
		DebugTN("Ack all Alarms initialised in " + delta);

	
//	DebugTN("Finish");	
	gInitFinished = true;	

	connectQueriesToSavePendingEvents();

	sgFwConnectActiveChain();

	sgFwConnectPVSSStatuses();

	connectDistributionStatuses();
	
	b = connectSystemGlobalStatuses();

	if(!b)
	{
		DebugTN("Connection to GlobalStatus of Distributed Systems failed");
		sgRefreshShortHistories(false);		
		return;
	}
	
	// 20060703 aj connection to recreate alarm for global system status
	connectGlobalPreStatus();

	// 20070206 aj init project specific functionality (does nothing if not needed)
	sgProjectSpecificFunc();

  	// 20140605 yc restart TCPComm for clients refresh  
  	sgFw2RestartTCPCommClients();
  		
	while(true)
	{
		// setTrace(EXECUTION_TRACE);
		
		if (gFwDebugLevel >= 4)
			sgFwStatsDisplay();

		start = getCurrentTime();
//		DebugTN("Will check delayed systems");
	
		b = sgFwDelayedSystemsCheck();
		if(!b)
		{
			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwDelayedSystemsCheck failed");
			sgRefreshShortHistories(false);		
			break;
		}

		delta = getCurrentTime() - start;		
		if(gFwDebugLevel &&  (delta > 1))
			DebugTN("Delayed systems: " + delta);

		start = getCurrentTime();
		b = sgFwComputeLogic();
		if(!b)
		{
			DebugTN("sgFw.ctl: sgFwComputeLogic() failed");
			break;
		}
		delta = getCurrentTime() - start;
	
		if(gFwDebugLevel &&  (delta > 1))
			DebugTN("Logic: " + delta);

		start = getCurrentTime();
		b = sgRefreshShortHistories(false);
		if(!b)
		{
			DebugTN("sgFw.ctl: sgRefreshShortHistories(false) failed");
			break;
		}
		delta = getCurrentTime() - start;	
		if(gFwDebugLevel &&  (delta > 1))
			DebugTN("Short histories: " + delta);


		start = getCurrentTime();
		b = sgWDChecker();
		if(!b)
		{
			DebugTN("sgFw.ctl: sgWDChecker() failed");
			break;
		}
		delta = getCurrentTime() - start;		
		if(gFwDebugLevel &&  (delta > 1))
			DebugTN("Watchdogs: " + delta);

		start = getCurrentTime();
		sgConnectionsFlush();
		delta = getCurrentTime() - start;		
		if(gFwDebugLevel &&  (delta > 1))
			DebugTN("Connections: " + delta);


//		DebugTN("Will update active chain");

//		updateActiveChain();

		if (gFwDebugLevel > 2)
			DebugTN("Will dpSet the clock");
		
		setFwClocks();
			
// wait to recall the FrameWork in 250 ms
		delay(0, 250);
	}
  
}

void sgFw2DebugLevelChanged(string dpName, int dpValue)
{
	DebugN("sgFw2 >> new debugLevel: " + dpValue);
	gFwDebugLevel = dpValue;
	
	if (gFwDebugLevel > 0)
		DebugN("sgFw2 >> Will trace framework time if more than 1 sec");
		
	if (gFwDebugLevel > 1)
		DebugN("sgFw2 >> Will trace framework statistics");
		
	if (gFwDebugLevel > 2)
		DebugN("sgFw2 >> Will trace when framework dpSet the clock");	
}

void sgFw2RestartTCPCommClients() {

	dyn_string dps, values;

	if (dpExists("FwUtils.TCPCommRestart.DataPoints")) {
	  	dpGet(
	  		"FwUtils.TCPCommRestart.DataPoints", dps,
	  		"FwUtils.TCPCommRestart.Values", values
	  		);
  		dpSet(dps, values);
	} else {
		DebugTN("sgFw2.ctl: TCPComm restart dps does not exists !");
	}

}


