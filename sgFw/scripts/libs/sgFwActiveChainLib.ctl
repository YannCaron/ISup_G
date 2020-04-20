
// Useful functions around active chain, chain name, ...
// JAN 2006 PW 

// return true if is chain A
bool isChainA()
{
	return isServerA(getHostname());
}

bool isChainB()
{
	return isServerB(getHostname());
}

bool isActiveChain()
{
	if(isChainA() && isAActiveChain())
		return true;
	
	if(isChainB() && isBActiveChain())
		return true;
	
	return false;
}

bool isAActiveChain()
{
	string activeChain;
	dpGet(ACTIVE_CHAIN, activeChain);
	if(activeChain == "A")
		return true;
	return false;
}

bool isBActiveChain()
{
	string activeChain;
	dpGet(ACTIVE_CHAIN, activeChain);
	if(activeChain == "B")
		return true;
	return false;
}

string getActiveChain()
{
	string activeChain;
	dpGet(ACTIVE_CHAIN, activeChain);
	return activeChain;
}
