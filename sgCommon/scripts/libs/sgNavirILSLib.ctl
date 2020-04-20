
void connectRunwaySelect()
{
	dyn_string ILSsNames;

	ILSsNames = dpNames("ILS*", "sgNavirILSSelect" );

//	DebugTN("NavirILSLib: connectRunwaySelect; ILSsNames: " + ILSsNames);
	if(dynlen(ILSsNames) == 0 )
	{
		DebugTN("NavirILSLib: connectRunwaySelect; No ILS connected");
	}
	else
	{
		for (int i=1; i <= dynlen(ILSsNames); i++)
		{
    string ILSSelectionDpName;
	
    ILSSelectionDpName = dpSubStr(ILSsNames[i], DPSUB_SYS_DP_EL);
    
    //Initialize timer and enable PW 02.2013			
    dpSet(ILSSelectionDpName + ".Status.ILSTimer", 0, ILSSelectionDpName + ".Status.ILSButtonEnable", true);     
      
    dpConnect("connectRequestedILS", ILSSelectionDpName + ".Commands.ILSSelection", ILSSelectionDpName + ".Commands.LastILSSelection", 
									ILSSelectionDpName + ".General.RunwayNameA", ILSSelectionDpName + ".General.RunwayNameB",
									ILSSelectionDpName + ".General.ILSHistories", ACTIVE_CHAIN);

			DebugTN("NavirILSLib: connectRunwaySelect; ILS " + ILSSelectionDpName + " connected");
		}
	}
}

void connectRequestedILS(string dpNameRequest, string ILSRequested, string dpNameLastRequest, string lastILSSelected, 
													string dpNameRWA, string ILSDirectionA, string dpNameRWB, string ILSDirectionB,
													string ILSHistoriesDpName, dyn_string ILSHistories, string dpNameActiveChain, string activeChain)
{
  string ILSRequestedString;
  string valueToSet;
  string ILSSelectionDpName;
  bool newILSSelection;
  
  if(ILSRequested == "--")     // case both ILS unselected
  	ILSRequestedString = ILSRequested;
  else          
   // to avoid to have only "5" if runway name is "05"
	ILSRequestedString = sgNavirILSConvertILSIntNameToString(ILSRequested);

 	if(ILSRequestedString != lastILSSelected)
 		newILSSelection = true;
 	else
                newILSSelection = false;
 
        // get ILS prefix
 	ILSSelectionDpName = sgStripDpName(dpNameRequest, ".Commands.ILSSelection");
        	
        // update last ILSmemo
	if(newILSSelection) //to avoid loop
		dpSet(ILSSelectionDpName + ".Commands.LastILSSelection", ILSRequestedString);

	
	if(ILSRequestedString == ILSDirectionA)
	{		
		setILSRequest(ILSDirectionA, ILSDirectionB, ILSHistories, ILSSelectionDpName, newILSSelection);
	}
	else if(ILSRequestedString == ILSDirectionB)
	{		
		setILSRequest(ILSDirectionB, ILSDirectionA, ILSHistories, ILSSelectionDpName, newILSSelection);
	}
  else if(ILSRequestedString == "--") // Both ILS unselection
	{		
		setILSRequestToBothILSUnselected(ILSDirectionB, ILSDirectionA, ILSHistories, ILSSelectionDpName, newILSSelection);
	}
	else  // no available value
	{
		sgHistoryAddEvent(ILSHistories, SEVERITY_CRITICAL, "Command <<ILS " + ILSRequestedString + " select>> NOT SENT!");
	}			
	
	// update last ILSmemo
	if(newILSSelection) //to avoid loop
		dpSet(ILSSelectionDpName + ".Commands.LastILSSelection", ILSRequestedString);
}

string sgNavirILSConvertILSIntNameToString(int ILSIntname)
{
	string res;
// Check if Runway name is < to 10 -> add a zero at start
	if((ILSIntname < 10)  && (ILSIntname > 0))  // "01" -> "09"
		res = "0" + ILSIntname;
	else if(ILSIntname <= 36)  // "10" -> "36"
		res = ILSIntname;
	else
		res = "";  // other case aren't possible!
	return res;
}

void setILSRequest(string ILSRequested, string otherILS, dyn_string ILSHistories, string ILSSelectionDpName, bool newILSSelection)
{
  // DebugTN("setILSRequest called; newILSSelection: " + newILSSelection);	
  if(newILSSelection)  // if only chain change, we don't disable the button. Commands set is always done to assure the selected ILS at start
	{
     		dpSet(ILSSelectionDpName + ".Status.ILSButtonText", "Select ILS " + otherILS);	// update Button text
		dpSet(ILSSelectionDpName + ".Status.ILSButtonEnable", false);  // to disable the button on other client(s)
	}

	dpSet("ILS" + otherILS + ".HMICommands.ILSSelectA", 2); // don't make only one dpSet, because we write in 2 different OPC servers!
	dpSet("ILS" + otherILS + ".HMICommands.ILSSelectB", 2); // 2 -> unselect

// only a pulse to command the ILS
	delay(0,300);
// set all to 0 to be sure to be initialized
	dpSet("ILS" + otherILS + ".HMICommands.ILSSelectA", 0);// don't make only one dpSet, because we write in 2 different OPC servers!
	dpSet("ILS" + otherILS + ".HMICommands.ILSSelectB", 0);
																											
	delay(0,300);
	dpSet("ILS" + ILSRequested + ".HMICommands.ILSSelectA", 1);// don't make only one dpSet, because we write in 2 different OPC servers!
	dpSet("ILS" + ILSRequested + ".HMICommands.ILSSelectB", 1);  // 1 -> select 
	
// only a pulse to command the ILS
	delay(0,300);
	
// set all to 0 
	dpSet("ILS" + ILSRequested + ".HMICommands.ILSSelectA", 0);// don't make only one dpSet, because we write in 2 different OPC servers!
	dpSet("ILS" + ILSRequested + ".HMICommands.ILSSelectB", 0);
				
// only a pulse to command the ILS
	delay(0, 300);
			
	if(newILSSelection)  // if only chain change, we don't display the clock
	{
		int lastCounterValue = 60;
		
		for(int i = 1; i <= lastCounterValue - 2; i++)
		{
			dpSet(ILSSelectionDpName + ".Status.ILSTimer", i);
			delay(0, 500);
		}
		dpSet(ILSSelectionDpName + ".Status.ILSTimer", 0);  // Timer finished	
	}

	if(newILSSelection)  // if new ILS Selection -> trace
	{
		dpSet(ILSSelectionDpName + ".Status.ILSButtonText", "Select ILS " + otherILS);	// enable and update Button text
		dpSet(ILSSelectionDpName + ".Status.ILSButtonEnable", true);  // to enable the button

		sgHistoryAddEvent(ILSHistories, SEVERITY_COMMAND, "ILS " + ILSRequested + " selection process terminated");
	}
}

void setILSRequestToBothILSUnselected(string ILSRequested, string otherILS, dyn_string ILSHistories, string ILSSelectionDpName, bool newILSSelection)
{
  // DebugTN("setILSRequest called; newILSSelection: " + newILSSelection);	
  if(newILSSelection)  // if only chain change, we don't disable the button. Commands set is always done to assure the selected ILS at start
	{
     		dpSet(ILSSelectionDpName + ".Status.ILSButtonText", "Select ILS " + otherILS);	// update Button text
		dpSet(ILSSelectionDpName + ".Status.ILSButtonEnable", false);  // to disable the button on other client(s)
	}

	dpSet("ILS" + otherILS + ".HMICommands.ILSSelectA", 2); // don't make only one dpSet, because we write in 2 different OPC servers!
	dpSet("ILS" + otherILS + ".HMICommands.ILSSelectB", 2); // 2 -> unselect

// only a pulse to command the ILS
	delay(0,300);
// set all to 0 to be sure to be initialized
	dpSet("ILS" + otherILS + ".HMICommands.ILSSelectA", 0);// don't make only one dpSet, because we write in 2 different OPC servers!
	dpSet("ILS" + otherILS + ".HMICommands.ILSSelectB", 0);
																											
	delay(0,300);
	dpSet("ILS" + ILSRequested + ".HMICommands.ILSSelectA", 2);// don't make only one dpSet, because we write in 2 different OPC servers!
	dpSet("ILS" + ILSRequested + ".HMICommands.ILSSelectB", 2);  // 2 -> unselect
	
// only a pulse to command the ILS
	delay(0,300);
	
// set all to 0 
	dpSet("ILS" + ILSRequested + ".HMICommands.ILSSelectA", 0);// don't make only one dpSet, because we write in 2 different OPC servers!
	dpSet("ILS" + ILSRequested + ".HMICommands.ILSSelectB", 0);
				
// only a pulse to command the ILS
	delay(0, 300);
			
	if(newILSSelection)  // if only chain change, we don't display the clock
	{
		int lastCounterValue = 60;
		
		for(int i = 1; i <= lastCounterValue - 2; i++)
		{
			dpSet(ILSSelectionDpName + ".Status.ILSTimer", i);
			delay(0, 500);
		}
		dpSet(ILSSelectionDpName + ".Status.ILSTimer", 0);  // Timer finished	
	}

	if(newILSSelection)  // if new ILS Selection -> trace
	{
		dpSet(ILSSelectionDpName + ".Status.ILSButtonEnable", true);  // to enable the button
		sgHistoryAddEvent(ILSHistories, SEVERITY_COMMAND, "ILS unselection process terminated");
	}
}








