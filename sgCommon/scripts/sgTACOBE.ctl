main()
{
	int res;

  res = dpConnect("connectTACOCommand", false, "TACO.Command");  
  
  if (res != 0)
		DebugTN("sgTACOBE >> main() >> dpConnect to determineActiveServer didn't work, returned: " + res);
}

void determineActiveServer(string DPE, string activeServer)
{
	gIsActive = (gServer == activeServer);
}

void cprCommand(string dpe, string command)
{
	int res;

	// send command only from active server, of course
	if (!gIsActive)
		return;

	res = system(command);
	if (res != 0)
	{
		sgHistoryAddEvent(CPR_HISTORY, SEVERITY_SYSTEM,"command could not be sent to the CPR Gateway");
		DebugTN("Server" + gServer + " cprCommand() >> failed, returned: " + res);
	}
	else
		DebugTN("Server" + gServer + " cprCommand() >> sent: " + command);
}
