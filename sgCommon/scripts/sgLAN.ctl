
main()
{

	dyn_string dps = dpNames("*","sgLAN");
	for (int i=1; i<=dynlen(dps); i++) {
		startXMLDispatcher(dps[i]);
	}

//	DebugTN(dps);
}