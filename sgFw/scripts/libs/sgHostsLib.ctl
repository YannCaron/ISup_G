// File: sgHostsLib.ctl
// 
// Version 1.1
//
// Date 24-JUL-03
//
// This file contains functions needed to identify the various hosts of the system
// NOTE: The names of the hosts must be in capital letters
// History
// =======
// 24-JUL-03 : First version (VL)
// 31-JUL-03 : Added shortcut for always having ISUPLAPTOPA as ServerA (PW)

/*
const string SERVER_A_HOST = "ISUP_G_A";
const string SERVER_B_HOST = "ISUP_G_B";
const string IO_A_HOST = "IoA";
const string IO_B_HOST = "IoB";
const string HMI01 = "ISUP_G_01";
const string HMI02 = "ISUP_G_02";
*/

bool isServerA(string hostname)
{
	dyn_string server = dataHost();
	return ( strtoupper(hostname) == strtoupper(server[1]) );
}

bool isServerB(string hostname)
{
	dyn_string server = dataHost();
	return ( strtoupper(hostname) == strtoupper(server[2]) );
}

/*
bool isIOA(string hostname)
{
	string host = strtoupper(hostname);
	return host == IO_A_HOST;
}

bool isIOB(string hostname)
{
	string host = strtoupper(hostname);
	return host == IO_B_HOST;
}

bool isHMI(string hostname)
{
	string host = strtoupper(hostname);
	if(host == HMI01)
		return true;
	if(host == HMI02)
		return true;
	return false;
}
*/