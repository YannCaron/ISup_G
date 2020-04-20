// File: RDPLib.ctl
// 
// Version 1.1
//
// Date 24-JUL-03
//
// This library contains the RDP functions that must be acessed outside the RDP script
//
// History
// =======
// 24-JUL-03 : First version (VL)
// 18-AUG-03 : Add comment on all functions (PW)

// Add the items in the RDP register point
// 09_FEB-04: // System history (ThV)
// 09_FEB-04: Add command sended to Primus in the System history (ThV)
// 15-SEP-08: change library name to sgRDPLib. RDP (Radar Datas Processing) will be the official system name (PW)

public string getRDPARTASAvailableLinksqq(){
  string activeChainValue;
  string primaryValue;
  string secondaryValue;

  dpGet("RDP.RawData.ARTASComputedValue.ActiveChain", activeChainValue,
        "RDP.RawData.ARTASComputedValue.PrimaryLAN", primaryValue,
        "RDP.RawData.ARTASComputedValue.SecondaryLAN", secondaryValue);
  
  string path;
  
  if (activeChainValue == "A" && (isOPS(primaryValue)||isDEG(primaryValue)))
    path = "APrim";
  else if (activeChainValue == "A" && (isOPS(secondaryValue)||isDEG(secondaryValue)))
    path = "ASec";
  else if (activeChainValue == "B" && (isOPS(primaryValue)||isDEG(primaryValue)))
    path = "BPrim";
  else if (activeChainValue == "B" && (isOPS(secondaryValue)||isDEG(secondaryValue)))
    path = "BSec";

  else
    path = "NO";
  
  return path;
}

public string getRDPARTASAvailableCMDLinks(){

  string activeChainARTAS;
  string primaryValueA;
  string secondaryValueA;
  string primaryValueB;
  string secondaryValueB;

  dpGet("RDP.RawData.ARTASComputedValue.ActiveChain", activeChainARTAS,
        "RDP.RawData.ARTASComputedValue.ISupSidePrimaryLANA", primaryValueA,
        "RDP.RawData.ARTASComputedValue.ISupSideSecondaryLANA", secondaryValueA,
        "RDP.RawData.ARTASComputedValue.ISupSidePrimaryLANB", primaryValueB,
        "RDP.RawData.ARTASComputedValue.ISupSideSecondaryLANB", secondaryValueB);

  string cmdPath;
  
  if (activeChainARTAS == "A" && (isOPS(primaryValueA)))
    cmdPath = "APrim";
  else if (activeChainARTAS == "A" && (isOPS(secondaryValueA)))
    cmdPath = "ASec";
  else if (activeChainARTAS == "B" && (isOPS(primaryValueB)))
    cmdPath = "BPrim";
  else if (activeChainARTAS == "B" && (isOPS(secondaryValueB)))
    cmdPath = "BSec";

  else
    cmdPath = "NO";
  
  return cmdPath;
}

public void setRDPTitle(string radarName) {
  
  LabelWindowCmd.text = "RDP ARTAS Radar " + radarName + " commands";
}

public void sendRDPRadarCommand(string radarName, string command) {
  dyn_string ds;
  dyn_string df;
  string availableLinks = getRDPARTASAvailableCMDLinks();
 
  if (availableLinks != "NO"){
    ChildPanelOnCentralModalReturn("sgFw\\sgFwConfirmWindow.pnl", "RDP ARTAS Commands", 
                  makeDynString("$1:" + "Do you really want to " + command + " radar " + radarName + "?", "$2:" + "Yes", "$3:" + "No"), df, ds);
	
    	if(ds[1] == "true")
    	{
      string eventText = "Radar command <" + command + " " + radarName + "> sent by " + getHostname() + " through " + availableLinks;
      sgHistoryAddEvent("RDP.History", SEVERITY_COMMAND, eventText);

      string dpRaw = "RDP.RawData.Radars." + radarName + ".Command." + availableLinks;
      int cmdValue;
        
      if (command == "Connect")
        cmdValue = 2;
      else if (command == "Disconnect")      
        cmdValue = 1;
      else
        cmdValue = 0;
      dpSet(dpRaw, cmdValue);
    }
  }
  else
    sgHistoryAddEvent("RDP.History", SEVERITY_COMMAND, "No available LAN: Radar command <" + command + " " + radarName + "> not sent!");
  
  PanelOffPanel("RDP Command Window");	
}

public void sendRDPRadarAttachDetachCmd(string radarName, string command, string channels) {
  dyn_string ds;
  dyn_string df;
  string availableLinks = getRDPARTASAvailableCMDLinks();

  dyn_string dsChannels = strsplit(channels, "_");
  
  if (availableLinks != "NO")
  {
    ChildPanelOnCentralModalReturn("sgFw\\sgFwConfirmWindow.pnl", "RDP ARTAS Commands", 
                    makeDynString("$1:" + "Do you really want to " + command + " radar " + radarName + " channel " + channels + "?", "$2:" + "Yes", "$3:" + "No"), df, ds);

    if(ds[1] == "true")
    {
      for(int i = 1; i <= dynlen(dsChannels); i++)
      {
        string eventText = "Radar command <" + command + " " + radarName + " channel " + dsChannels[i] + "> sent by " + getHostname() + " through " + availableLinks;
        sgHistoryAddEvent("RDP.History", SEVERITY_COMMAND, eventText);

        string dpRaw = "RDP.RawData.Radars." + radarName + ".Channel" + dsChannels[i] + "Cmd." + availableLinks;
        int cmdValue;
        
        if (command == "Attach")
          cmdValue = 7;
        else if (command == "Detach")      
          cmdValue = 6;
        dpSet(dpRaw, cmdValue);
      }
    }
  }
  else
    sgHistoryAddEvent("RDP.History", SEVERITY_COMMAND, "No available LAN: Radar command <" + command + " " + radarName + " channel " + channels + "> not sent!");

  PanelOffPanel("RDP Command Window");	
}



public void sendRDPARTASCommand(string ARTASChain, string command) {
  dyn_string ds;
  dyn_string df;

  ChildPanelOnCentralModalReturn("sgFw\\sgFwConfirmWindow.pnl", "RDP ARTAS Commands", 
                  makeDynString("$1:" + "Do you really want to " + command + " ARTAS chain " + ARTASChain + "?", "$2:" + "Yes", "$3:" + "No"), df, ds);
	
  if(ds[1] == "true") {
    int cmdValue;
    string dpRawNode;
     if (command == "Start"){
      cmdValue = 1;
      dpRawNode = ".NodeStart.";
    } else if (command == "Stop"){
      cmdValue = 1;
      dpRawNode = ".NodeStop.";
    }      

    string primaryValue;
    string secondaryValue;
    
    dpGet("RDP.RawData.ARTASComputedValue.ISupSidePrimaryLAN" + ARTASChain, primaryValue,
          "RDP.RawData.ARTASComputedValue.ISupSideSecondaryLAN" + ARTASChain, secondaryValue);

    string lan;
    // if LAN ok, we take the first one
    if (isOPS(primaryValue))
      lan = "Prim";
    else if (isOPS(secondaryValue))
      lan = "Sec";
     else
      lan = "Prim";

    string dpRawPostfix;
    if (ARTASChain == "A")
      dpRawPostfix = "A" + lan;
    else if (ARTASChain == "B")
      dpRawPostfix = "B" + lan;
   
    string dpRaw = "RDP.RawData.ARTAS.Commands" + dpRawNode + dpRawPostfix;
    dpSet(dpRaw, cmdValue);
    delay(1);
    dpSet(dpRaw, 0);// to initialize the dp 
 
    string eventText = "ARTAS Node cmd <" + command + " chain " + ARTASChain + "> sent by " + getHostname() + " through " + dpRawPostfix;
    sgHistoryAddEvent("RDP.History", SEVERITY_COMMAND, eventText);
  }
  PanelOffPanel("RDP Command Window");	
}
