
main()
{ 
  delay(10);	// to wait on the Framework initialization
  
  while(true)  // main loop
	{
		while (!isActiveChain()) // wait here if isn't the active chain
		{
			setINCHConnectionStatus("A", "A", SBY_STATUS); // status set to stand-by (not connected)
			setINCHConnectionStatus("A", "B", SBY_STATUS); // status set to stand-by (not connected)
			delay (0,500);	
		}

		delay(1);	
				
		startINCHXML("A");  // connect XML to INCH chain A
		heartbeatLoopCore("A"); // loop which send heartbeat until it failed

			// case heartbeat aborted	
		DebugTN("sgNavirINCHAXML.ctl; Last heartbeat to INCH A failed! Retry in 1 seconds");	

		disconnectINCHXML("A");
	}//Main while loop
}
