main()
{
  connectNavirActiveChainStartRequest(); // connect to set in both centrals which chain is active and the starting request 

  connectNavirActiveCentral();
  
  connectRunwaySelect(); // Connect current ILS if present on this system
	
  connectNavirGlobalPreStatus(); // to recreate an alarm if a second input is DEG
	
  while(true)
  {	
    writeCentralHeartBeat();  // to check in central , the link central-server link
	
    delay(2); // wait 2 seconds (ctrl clock is refreshed each 1,0 seconds 
    
  }//while loop
}//main

