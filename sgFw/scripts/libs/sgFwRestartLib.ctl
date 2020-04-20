void restartConnect() {
  dyn_string dpSystemRestart;
  
  dpSystemRestart = getPointsOfType("sgFwSystemRestart");
  string dp;
  
  for (int i = 1; i <= dynlen(dpSystemRestart); i++) {
    dpConnect("restartWorkFunction", FALSE, 
              dpSystemRestart[i] + RESTART_ADDRESS_POSTFIX,
              dpSystemRestart[i] + RESTART_LOGIN_POSTFIX,
              dpSystemRestart[i] + RESTART_PASSWORD_POSTFIX,
              dpSystemRestart[i] + RESTART_RUN_POSTFIX,
              dpSystemRestart[i] + RESTART_HISTORY_POSTFIX);
  }
}

void restartWorkFunction(string addressDP, string address, 
                         string loginDP, string login, 
                         string passwordDP, string password,
                         string runDP, bool run,
                         string historyDP, string history) {

  if (isLinux ()) {
    DebugTN ("PSShutdown command is not allowed on Linux OS.");
  } else {
    if (run && isActiveChain()) {
      int res;

      runDP = dpSubStr(runDP, DPSUB_SYS_DP_EL);
      string ipAddress = getHostByName(address);

      // replace /c by /k option for dos window appears
      string command = "start cmd /c " + getPath(BIN_REL_PATH, "psshutdown.exe") + " -r -f -t 0 -u " + login + " -p " + password + " /accepteula \\\\" + ipAddress; 

      // reset
      dpSet(runDP, FALSE);

      // log
      sgHistoryAddEvent(history, SEVERITY_COMMAND, "Restart " + address + " (" + ipAddress + ") sent");

      // execute
      res = system(command);
    
    }
  }  
}
