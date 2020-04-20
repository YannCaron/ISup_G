const unsigned SEND_COMMAND_TIMEOUT = 200;
const unsigned SEND_COMMAND_PORT_PMON = 4999;

const string SEND_COMMAND_FORMAT = "%s#%s#%s:%s\n";
const string SEND_COMMAND_REPLY_OK = "OK";

const string SEND_COMMAND_RESTART_ALL = "RESTART_ALL";

string pmonFormatCommand(string user, string password, string command, string subCommand = "") {
  string ret;
  sprintf(ret, SEND_COMMAND_FORMAT, user, password, command, subCommand);
  return ret;
}

bool pmonSendCommand(string host, unsigned port, string user, string pass, string command, string &reply) {
  
  dyn_errClass err; 
  int socket;
  string cmd;
  
  socket = tcpOpen  (host, port);
  cmd = pmonFormatCommand(user, pass, command);

	tcpWrite (socket, cmd);
	tcpShutdownOutput(socket);
	tcpRead (socket, reply, SEND_COMMAND_TIMEOUT);
	tcpClose (socket);
  
  err=getLastError(); 
  
  if (dynlen(err) == 0 && reply == SEND_COMMAND_REPLY_OK) {
    return true;
  } else {
	if (reply == "") reply = "unable to connect to TCP [" + host + ":" + port + "]";
    return false;
  }

}

void pmonRestart (string history, string hostName) {
  string host;
  bool ret;
  string reply;
    
  host = getHostByName(hostName);  

  sgHistoryAddEvent(history, SEVERITY_COMMAND, "User: " + getHostname() + " request restart " + hostName);
  DebugTN("HMI >> User: " + getHostname() + " request restart " + hostName);

  ret = pmonSendCommand(host, SEND_COMMAND_PORT_PMON, "", "", SEND_COMMAND_RESTART_ALL, reply);

  if (ret) {
    sgHistoryAddEvent(history, SEVERITY_COMMAND, hostName + " restart successfull");
    DebugTN("HMI >> " + hostName + " restart successfull");
  } else {
    sgHistoryAddEvent(history, SEVERITY_SYSTEM, "Command " + SEND_COMMAND_RESTART_ALL + " does not work !", reply);
    DebugN("pmonSendCommand; " + SEND_COMMAND_RESTART_ALL + " from host: " + hostName + "; Error received: " + reply + " !");
  }
 
}

void pmonRestartConfirm (string history, string hostName) {
  
  dyn_float df;
  dyn_string ds;
  
  ChildPanelOnCentralModalReturn("sgFw/sgFwConfirmWindow.pnl", "Confirmation", 
  makeDynString("$1:Do you really want to restart " + hostName + " ?\n(This command take a FEW minutes !)", "$2:Yes", "$3:No"), df, ds);
	
  if(ds[1] == "true")
  {
    pmonRestart(history, hostName);
  }
}
