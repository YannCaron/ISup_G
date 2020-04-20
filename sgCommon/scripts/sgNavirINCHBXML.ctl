
main()
{ 
  delay(10);	// to wait on the Framework initialization

  while(true)  // main loop
  {
		while (!isActiveChain()) // wait here if isn't the active chain
		{
			setINCHConnectionStatus("B", "A", SBY_STATUS); // status set to stand-by (not connected)
			setINCHConnectionStatus("B", "B", SBY_STATUS); // status set to stand-by (not connected)
			delay (0,500);	
		}
		delay(1);	

		startINCHXML("B");  // connect XML to INCH chain A
		heartbeatLoopCore("B"); // loop which send heartbeat until it failed
			
			// case heartbeat aborted	
		DebugTN("sgNavirINCHBXML.ctl; Last heartbeat to INCH B failed! Retry in 1 seconds");	
		
		disconnectINCHXML("B");
	}//Main while loop
}
