const int CMD_ENABLE = 1;
const string TXT_ENABLE = "enable";
const int CMD_DISABLE = 2;
const string TXT_DISABLE = "disable";
const int CMD_RESTART = 3;
const string TXT_RESTART = "restart";
const int CMD_REBOOT = 4;
const string TXT_REBOOT = "reboot";
const int CMD_SWITCH = 5;
const string TXT_SWITCH = "switch";
const string NODE_COMPONENT = "OPStatus";

public void setCPDLCTitle(string site, string node, string cnn) {
  if (cnn != "") {
    cnn = " " + cnn;
  }
  
  LabelWindowCmd.text = "CPDLC-ES-" + site + " Node " + node + cnn;
}

public void sendCPDLCCommand(string site, string node, string component, string command, int cmd, string cmdText) {
 	dyn_string ds;
	dyn_string df;
  string esName = "ES" + site + "Node" + node;
  string cmpName = esName + " " + component;
	ChildPanelOnCentralModalReturn("sgFw\\sgFwConfirmWindow.pnl", "Warning !!!", makeDynString("$1:" + "Do you really want to " + cmdText + " " + esName + " ?", "$2:" + "Yes", "$3:" + "No"), df, ds);
	
	if(ds[1] == "true")
	{
		sgHistoryAddEvent("CPDLC.History", SEVERITY_COMMAND, "User request " + cmdText + " on " + cmpName + " node");

   string dpRaw = "CPDLC.RawData." + esName + "." + command;
		dpSet(dpRaw, cmd);
                    
	}
        
	PanelOffPanel("CPDLC Command Window");	
}
