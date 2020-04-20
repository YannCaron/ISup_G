sgProjectSpecificFunc()
{

	sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "project specific function called " + getHostname());

	// copy this file into a proj directory and 
	// add here project spedific functions
	// which should be called after the framework initialisation
	// and executed in the fw ctrl manager

}
