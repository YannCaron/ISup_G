string previousCtrlClockWDToCentral;  // saved value for each time we execute the loop
string lastNavirGlobalStatus;

void connectNavirActiveChainStartRequest()
{
  	dpConnect("navirSetCentralValues", ACTIVE_CHAIN, "NavSup.General.CentralA.StartRequest", "NavSup.General.CentralB.StartRequest"); 
}

void connectNavirActiveCentral()
{
  	dpConnect("setActiveCentral", TRUE, ACTIVE_CHAIN); 
}

void setActiveCentral(string activeChainName, string activeChainValue)
{
  delay(1);
    if(activeChainValue == "B")
    dpSet("_DriverS7.ReduControl.CP.Switch", 2);
  else // default chain is A
    dpSet("_DriverS7.ReduControl.CP.Switch", 1);
}    

// write in both central 
void navirSetCentralValues(string activeChainName, string activeChainValue,
            string dpCentralARequest, bool dpCentralARequestValue, string dpCentralBRequest, bool dpCentralBRequestValue) 
{
  if(dpCentralARequestValue) // to avoid loop on start request
  {
    dpSet("NavSup.General.CentralA.CentralName", "A");  // Central Name
  }
  if(dpCentralBRequestValue) // to avoid loop on start request
  {
    dpSet("NavSup.General.CentralB.CentralName", "B");  // Central Name
  }
  
  if(activeChainValue == "A")
  {
  // write to central A
    dpSet("NavSup.General.CentralA.ActiveChainIsA", true);
    dpSet("NavSup.General.CentralA.ActiveChainIsB", false);		
        // write to central B
    if (dpExists("NavSup.General.CentralB.ActiveChainIsA") )
    {
      dpSet("NavSup.General.CentralB.ActiveChainIsA", true);
      dpSet("NavSup.General.CentralB.ActiveChainIsB", false);
    }
  }
  else 
  {
    if(activeChainValue == "B")
    {
      // write to central A
      dpSet("NavSup.General.CentralA.ActiveChainIsA", false,
            "NavSup.General.CentralA.ActiveChainIsB", true);
      // !! Two dpSet because to different OPC Driver			
      // write to central B
      dpSet("NavSup.General.CentralB.ActiveChainIsA", false,
            "NavSup.General.CentralB.ActiveChainIsB", true);
    }
    else 
    {		// Case where no Active chain!
      // write to central A
      dpSet("NavSup.General.CentralA.ActiveChainIsA", false,
            "NavSup.General.CentralA.ActiveChainIsB", false);
          // !! Two dpSet because to different OPC Driver			
         // write to central B
      if (dpExists("NavSup.General.CentralB.ActiveChainIsA") )
      {
        dpSet("NavSup.General.CentralB.ActiveChainIsA", false,
              "NavSup.General.CentralB.ActiveChainIsB", false);
      }
    }	
  }
}

// to check in central , the link central-server link
void writeCentralHeartBeat()
{
  bool previousValue;
  string currentCtrlClock;
	
  if(isChainA())
  {
    dpGet(ACTIVE_CTRL_CLOCK, currentCtrlClock,
	"NavSup.General.CentralA.HeartBeatFromServer", previousValue);
    if(currentCtrlClock != previousCtrlClockWDToCentral)  // sgFw script has changed the time
    {																											// update WD only if SgFw ctrl clock has changed
      dpSet("NavSup.General.CentralA.HeartBeatFromServer", !previousValue);
    }
  }
  if(isChainB())
  {
    dpGet(ACTIVE_CTRL_CLOCK, currentCtrlClock, "NavSup.General.CentralB.HeartBeatFromServer", previousValue);
    if(currentCtrlClock != previousCtrlClockWDToCentral)  // sgFw script has changed the time
    {																											// update WD only if SgFw ctrl clock has changed
      dpSet("NavSup.General.CentralB.HeartBeatFromServer", !previousValue);
    }
  }
  previousCtrlClockWDToCentral = currentCtrlClock;  // update last value
}

void connectNavirGlobalPreStatus()
{
	dpConnect("reGenerateNavirAlarm" ,"SystemStatus.GlobalStatus.PreStatus");
}

// special function to rewrite the alarm on the global Navir status to re create an alarm when an second input is DEG
void reGenerateNavirAlarm(string navirGlobalPreStatusDpName, string navirGlobalPreStatus)
{
	string navirGlobalPreStatusDpNameWithoutSuffix;
	
	// if last Status was DEG and new Status is DEG
	if(lastNavirGlobalStatus == DEG_STATUS && navirGlobalPreStatus == DEG_STATUS)
	{
		// sgFw rewrite the DEG value on status if it was forced to OPS -> restart the alarm
		dpSet("SystemStatus.GlobalStatus.Status", OPS_STATUS);
	}
	// update last status
	lastNavirGlobalStatus = navirGlobalPreStatus;
}

// write once a value on Hearbeats. Used at start to force the WD to be executed
void resetHeartBeats()
{
  dpSet("NavSup.WatchDog.HeartBeat1", false, 
    "NavSup.WatchDog.HeartBeatA", false, 
    "NavSup.WatchDog.HeartBeatAllStations", false);			
  
  if (dpExists("NavSup.WatchDog.HeartBeatB") )
  {        
    dpSet("NavSup.WatchDog.HeartBeatB", false);			
  }
}
	






