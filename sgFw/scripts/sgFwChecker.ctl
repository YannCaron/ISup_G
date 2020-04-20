

// script to check the sgFw status.
// Each chain write its respective ctrlclock which be checked
// if Ctrlclock isn't correct, FWStatus is set to U/S and switch to other chain is possible
// PW december 2005
// 

//******* global constants *******
const int CHECK_DELAY = 2;	// seconds


main()
{
	waitUntilRecoveryFinished();

	connectActiveChainSelect();

	while(true)
	{
		// verify Frameworks for both chains
		frameworksChecker();
	
		// switch to other chain if necessary
		selectBestChain();
	
		// wait for next check
		delay(CHECK_DELAY);
	}
}








