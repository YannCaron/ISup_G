
// skyguide framework checker library
// Functions around the sgFw checker
// JAN 2006 PW

time gLastCtrlClockTimeA;  // last control clock time to be able to compare in the next cycle
time gLastCtrlClockTimeB;  // last control clock time to be able to compare in the next cycle

const int MIN_SWITCH_DELAY = 60;  // at least N seconds between 2 switches
const int FORCE_STATUS_LAST_SWITCH_DELAY = 45; // to force status to after a switchover. 
const int FW_US_CHECKER_TOLERANCE_DELAY = 30; // if clock don't change after this delay -> U/S
const int FW_DEG_CHECKER_TOLERANCE_DELAY = 5; // if clock don't change after this delay -> DEG

// check the respective Framework ctrl clock and wait until it was correctly started
void waitUntilRecoveryFinished()
{
	string eventConnectionDpName;
	bool eventConnected;

	setOwnFwCheckerStatus(INI_STATUS);

	if( isChainA() )
	{
		eventConnectionDpName = "_Conn_event_0_2_to_event_0_1.Link0"; // event connection on Chain B status
	}
	else
	{
		eventConnectionDpName = "_Conn_event_0_1_to_event_0_2.Link0"; // event connection on Chain A status
	}
	//DebugTN("sgFwCheckerLib, isActiveChain: " + isActiveChain() + " eventConnected: " + eventConnected);
	
	while(!isActiveChain() && !eventConnected)
	{
		delay (1); // wait to have a time difference if FW runs
		dpGet(eventConnectionDpName, eventConnected);

		setOwnFwCheckerStatus(INI_STATUS); // to avoid watchdog

	//DebugTN("sgFwCheckerLib, isActiveChain: " + isActiveChain() + " eventConnected: " + eventConnected);

	}// loop while Fw not ok

	//DebugTN("sgFW finished");
	delay (3); // 
	//DebugTN("sgFW finished. After Delay");
}



bool lastActiveFwOk;  // last Fw status;

// write the framework status of the current chain
void writeFwStatus(string status)
{
	if(isChainA())
		dpSet(FRAMEWORK_STATUS_A_CHECKER, status);
	
	else if(isChainB())
		dpSet(FRAMEWORK_STATUS_B_CHECKER, status);
	
	else  // chain not determinated -> set both to UKN
		dpSet(FRAMEWORK_STATUS_A_CHECKER, UKN_STATUS ,
					FRAMEWORK_STATUS_B_CHECKER, UKN_STATUS );
}



// Each chain refresh its own clock (to individually check each respective Framework
// Active chain refresh the ctrl Clock
void setFwClocks()
{
	time currentTime;
		
	currentTime = getCurrentTime();
		
	if(isChainA())
	{
		dpSet(ACTIVE_CTRL_CLOCK, currentTime);
		dpSet(CTRL_CLOCK_A, currentTime);
	}
	if(isChainB())
	{
		dpSet(ACTIVE_CTRL_CLOCK, currentTime);
		dpSet(CTRL_CLOCK_B, currentTime);
	}
}

// Verify if logic is unavailable (verify if respective clock have changed)
void frameworksChecker()
{
	time ctrlClockA;
 	time ctrlClockB;
 	time lastSwitchTime; 
	
	// get Fw clock A & B & the last switch time
 	dpGet(CTRL_CLOCK_A, ctrlClockA,
	 			CTRL_CLOCK_B, ctrlClockB,
				ACTIVE_CHAIN_SELECT  + ORIGINAL_STIME, lastSwitchTime);
	
	// calculate ctrl clock deltas since last execution
	float deltaA;
	float deltaB;

	deltaA = sgGetDeltaCtrlClock(ctrlClockA, gLastCtrlClockTimeA);
	deltaB = sgGetDeltaCtrlClock(ctrlClockB, gLastCtrlClockTimeB);

	string fwStatusA;
	string fwStatusB;
	bool fwAIsOK;
	bool fwBIsOK;
	bool activeFwOk;
	
	treatFwStatus(deltaA, ctrlClockA, "A", fwAIsOK, fwStatusA); // function return fwAIsOK & fwStatusA
	treatFwStatus(deltaB, ctrlClockB, "B", fwBIsOK, fwStatusB); // function return fwBIsOK & fwStatusB

	time currentTime;
	int delta;
	
	currentTime = getCurrentTime();
	
	delta = (int)currentTime - (int)lastSwitchTime;
	delta = fabs(delta);
	// if time too short after last switch, force status to ok. After a switchover, it can take a few second to stabilize the FW statutes (CPU load)!
	if(delta < FORCE_STATUS_LAST_SWITCH_DELAY) 
	{
		if(	isAActiveChain() )
		{
			fwStatusA = OPS_STATUS;
			fwStatusB = SBY_STATUS;
		}
		if(	isBActiveChain() )
		{
			fwStatusA = SBY_STATUS;
			fwStatusB = OPS_STATUS;
		}
		fwAIsOK = true;
		fwBIsOK = true;
	}

// set activeFwOk of active chain is ok
	if( (isAActiveChain() && fwAIsOK) || (isBActiveChain() && fwBIsOK) )
	{
		activeFwOk = true;
	
		if(!lastActiveFwOk)  // first cycle after a restart
			writeDisabledToRecalculateAllAlarms();
	}	
	else
	{
		activeFwOk = false;
		
		if(lastActiveFwOk)  // to avoid to re set alarms
			setAllAlarms();
	}
	// update saved values
	gLastCtrlClockTimeA = ctrlClockA;
	gLastCtrlClockTimeB = ctrlClockB;

	dpSet(FRAMEWORK_STATUS_A_CHECKER, fwStatusA,   // set sgFwStatus A
				FRAMEWORK_STATUS_B_CHECKER, fwStatusB);  // set sgFwStatus B
	
	lastActiveFwOk = activeFwOk;  // update memo for next cycle
	
	writeFwCheckerStatus();  // write fw checker alive status 
}

// used to set all alarms when Framework doesn't work
void setAllAlarms()
{
	dyn_string allAlarmsDpNames;
	
	dpGet(ALARMS_DPS, allAlarmsDpNames);
	
	// start on second position. First  position is used for the system description
	for(int i=2; i<=dynlen(allAlarmsDpNames) ;i++)
	{
		dyn_string singleAlarmDpName;
	
		// it can contains several alarms dps separated with "+"
		singleAlarmDpName = strsplit(allAlarmsDpNames[i], "+");
	
		// set to false, if alarm is already ackowledged
		dpSet(singleAlarmDpName[1] + ALARM_ACTIVE_POSTFIX , FALSE);
		
		dpSet(singleAlarmDpName[1] + ALARM_ACTIVE_POSTFIX , TRUE);
	}
}

// used to rewrite disabled status to force to recalculate alarms when Framework restart
void writeDisabledToRecalculateAllAlarms()
{
	dyn_string allAlarmsDpNames;
	
	dpGet(ALARMS_DPS, allAlarmsDpNames);
	
	// start on second position. First  position is used for the system description
	for(int i=2; i<=dynlen(allAlarmsDpNames) ;i++)
	{
		dyn_string singleAlarmDpName;
	
		// it can contains several alarms dps separated with "+"
		singleAlarmDpName = strsplit(allAlarmsDpNames[i], "+");
	
		// get deactivation status
		bool deactivation;
		dpGet(singleAlarmDpName[1] + DISABLED_POSTFIX, deactivation);
		//set deactivation to force to recalculate alarm status
		dpSet(singleAlarmDpName[1] + DISABLED_POSTFIX, deactivation);
		
	}
}


// Each chain write its own checker alive status
void writeFwCheckerStatus()
{
	string fwCheckerStatus;
	string fwCheckerStatusDpName;
	
	if(isActiveChain())
	 	fwCheckerStatus = OPS_STATUS;
	else
		fwCheckerStatus = SBY_STATUS;
	
	setOwnFwCheckerStatus(fwCheckerStatus);
}

// set Fw Checker status of the active chain (lines added in config.redu file
void setOwnFwCheckerStatus(string status)
{
	string fwCheckerStatusDpName;
	
	if(isChainA())
		dpSet(FRAMEWORK_CHECKER_STATUS_A + PRE_STATUS_POSTFIX, status);
	
	if(isChainB())
		dpSet(FRAMEWORK_CHECKER_STATUS_B + PRE_STATUS_POSTFIX, status);
}


// get and calculate the delta between two ctrl clock
float sgGetDeltaCtrlClock(time currentCtrlclock, time lastCtrlClock)
{
 	float delta;
 	
	// calculate logic delta
	delta = (float)currentCtrlclock - (float)lastCtrlClock;
	delta = fabs(delta);

	return delta;
}

// calculate with the defined delta and ctrlclock if framework status is ok and its status
void treatFwStatus(float delta, time ctrlClock, string chain, bool &fwOk, string &fwStatus)
{
	if (delta != 0 )  // sgFW ok -> OPS
	{	// if is active chain -> OPS else SBY
		if( (isAActiveChain() && chain == "A") || (isBActiveChain() && chain == "B") )
		{	
			fwStatus = OPS_STATUS;  // set sgFwStatus OPS	
			fwOk = true;
		}	
		else 
		{
			fwStatus = SBY_STATUS;  // set sgFwStatus SBY
			fwOk = true;
		}	
	}
	else  // -> delta = 0 sgFW degraded (too much load or problem. Check difference between current time and ctrl clock 
	{
		time currentTime;
		float deltaCurrentTime;

		currentTime = getCurrentTime();
		
		deltaCurrentTime = sgGetDeltaCtrlClock(currentTime, ctrlClock);
		
		// U/S 	
		if(deltaCurrentTime >= FW_US_CHECKER_TOLERANCE_DELAY)  // ctrlclock not synchronized. Difference is upper or equal than this constant
		{
			fwStatus = U_S_STATUS;  // set sgFwStatus A to U/S
			fwOk = false;
			}
		else // DEG
			if(deltaCurrentTime >= FW_DEG_CHECKER_TOLERANCE_DELAY)  // ctrlclock not synchronized. Difference is upper or equal than this constant
			{
				fwStatus = DEG_STATUS;  // set sgFwStatus A to DEG. This delta is possible if fw is too much loaded
				fwOk = true;
			}
			else  // Tolerable -> OPS or SBY
			{
				if( (isAActiveChain() && chain == "A") || (isBActiveChain() && chain == "B") )
				{	
					fwStatus = OPS_STATUS;  // set sgFwStatus OPS	
					fwOk = true;
				}	
				else 
				{
					fwStatus = SBY_STATUS;  // set sgFwStatus SBY
					fwOk = true;
				}	
		}
	}
}


// If framework is U/S and other chain is good -> switchover
// If both framework ok and other Status (to switchover) degraded -> switchover
void selectBestChain()
{
	string fwStatusA;
	string fwStatusB;
	string otherSwitchStatusA;
	string otherSwitchStatusB;
	string chainToSwitchFw;
	string chainToSwitchOther;
	bool selectChainAFw;
	bool selectChainBFw;
	bool selectChainAOther;
	bool selectChainBOther;
	
	time lastSwitchTime;
	
	// get FW preStatus (if Fw isn't available...
	dpGet(FRAMEWORK_STATUS_A + PRE_STATUS_POSTFIX, fwStatusA,
				FRAMEWORK_STATUS_B + PRE_STATUS_POSTFIX, fwStatusB,
				AUTOSWITCH_STATUS_A, otherSwitchStatusA,
				AUTOSWITCH_STATUS_B, otherSwitchStatusB,
				ACTIVE_CHAIN_SELECT  + ORIGINAL_STIME, lastSwitchTime);
	
	time currentTime;
	int delta;
	
	currentTime = getCurrentTime();
	
	delta = (int)currentTime - (int)lastSwitchTime;
	delta = fabs(delta);

	// if time to short since last switch, do nothing to wait
	if(delta < MIN_SWITCH_DELAY) 
	{
		return;
	}

	chainToSwitchFw = systemNeedToSwitchoverTo(fwStatusA, fwStatusB);
		
	// First Framework determinates which chain is used!
	if(chainToSwitchFw == "A" || chainToSwitchFw == "B" ) //"" -> no change
	{
		sgHistoryAddEvent(SYSTEM_HISTORY, SEVERITY_SYSTEM, "FwChecker autoswitch to :" + chainToSwitchFw + "FwStatusA:" + fwStatusA + " FwStatusB:" + fwStatusB); 
		DebugTN("selectBestChain; FwChecker automatically switched to chain: " + chainToSwitchFw +". FwStatusA:" + fwStatusA + " FwStatusB:" + fwStatusB); 
	
		dpSet(ACTIVE_CHAIN_SELECT, chainToSwitchFw);
		return;  // if Fw isn't ok, no other status can make a switchover
	}

	// get status for other important status to switch
	chainToSwitchOther = systemNeedToSwitchoverTo(otherSwitchStatusA, otherSwitchStatusB);
		
	// FW is OPS in both chain, Other can select the chain
	if(chainToSwitchFw == "=" && (chainToSwitchOther == "A" || chainToSwitchOther == "B"))
	{
		sgHistoryAddEvent(SYSTEM_HISTORY, SEVERITY_SYSTEM, "FwChecker autoswitch to :" + chainToSwitchOther + "otherSwitchStatusA:" + otherSwitchStatusA + " otherSwitchStatusB:" + otherSwitchStatusB); 
		DebugTN("selectBestChain; FwChecker automatically switched to chain: " + chainToSwitchOther +". otherSwitchStatusA:" + otherSwitchStatusA + " otherSwitchStatusB:" + otherSwitchStatusB); 
	
		dpSet(ACTIVE_CHAIN_SELECT, chainToSwitchOther);
	}
}


// return the right chain value to switch or not. 
string systemNeedToSwitchoverTo(string statusA, string statusB)
{
// "" -> don't switch
// "A" -> switch to A
// "B" -> switch to B
// "=" -> no preference

// if both statuses are OPS or SBY -> chain are equal
	if(isOPS(statusA) && isOPS(statusB) || isOPS(statusA) && isSBY(statusB) || isSBY(statusA) && isOPS(statusB) || isSBY(statusA) && isSBY(statusB))
		return "=";

// if one chain status is DEG and other is OPS or SBY -> don't switch immediately -> DEG is only if fw is unsynchronized
	if(isOPS(statusA) && isDEG(statusB) || isDEG(statusA) && isOPS(statusB) || isSBY(statusA) && isDEG(statusB) || isDEG(statusA) && isSBY(statusB))
		return "=";

// if both chain are DEG -> don't switch immediately -> DEG is only if fw is unsynchronized
	if(isDEG(statusA) && isDEG(statusB))
		return "=";

	//if A isn't active AND (statusA OPS or SBY) AND (statusB not OPS AND not SBY) -> choose Chain A
	if(!isAActiveChain() && (isOPS(statusA)||isSBY(statusA)) && (!isOPS(statusB) && !isSBY(statusB)) )
		return "A";

	//if B isn't active AND (statusB OPS or SBY) AND (statusA not OPS AND not SBY) -> choose Chain B
	if(!isBActiveChain() && (isOPS(statusB)||isSBY(statusB)) && (!isOPS(statusA) && !isSBY(statusA)) )
		return "B";

	return "";
}

// connect the active chain selection command to set 
void connectActiveChainSelect()
{
	dpConnect("setActiveChain", false, ACTIVE_CHAIN_SELECT);
}

// send command to switch to other chain 
void setActiveChain(string activeChainSelectDp, string chainToSwitch)
{
	if(chainToSwitch == "A")
		dpSet("_ReduManager.Command.ActiveSet", true);

	if(chainToSwitch == "B")
		dpSet("_ReduManager_2.Command.ActiveSet", true);
	
	//else 
	// nothing to do if "="
}





