const string CPR_HISTORY = "CPR.History";

string gServer;
bool gIsActive;

main()
{
	int res;

	// get server name, for writing into the history
	if (isServerA(getHostname()))
		gServer = "A";
	else if (isServerB(getHostname()))
		gServer = "B";
	else
		DebugTN("sgCPR >> main() >> host " + getHostName() + " is neither A nor B");

	// to know active chain, not really necessary except for Commands!!
	res = dpConnect("determineActiveServer",ACTIVE_CHAIN);
	if (res != 0)
		DebugTN("sgCPR >> main() >> dpConnect to determineActiveServer didn't work, returned: " + res);

	// connect to CPRCommand but don't call work function immediately
	res = dpConnect("cprCommand",FALSE,"CPR.Command");
	if (res != 0)
		DebugTN("sgCPR >> main() >> dpConnect to cprCommand didn't work, returned: " + res);
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