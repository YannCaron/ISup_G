// File: sgFwHelpersLib.ctl
//
// Version 1.1
//
// Date 24-JUL-03
//
// This file contains helper functions related to the framework
// History
// =======
// 24-JUL-03 : First version (VL)
// 15-JUN-04 : Added distributedDpAvailable() function to return if distributed point is available

bool isOPS(string status){
	return status == "OPS";
}

bool isSBY(string status){
	return status == "SBY";
}

bool isSSB(string status){
	return status == "SSB";
}

bool isINI(string status){
	return status == "INI";
}

bool isDEG(string status){
	return status == "DEG";
}

bool isUS(string status){
	return status == "U/S";
}

bool isTEC(string status){
	return status == "TEC";
}

bool isWIP(string status){
	return status == "WIP";
}

bool isABS(string status){
	return status == "ABS";
}

bool isSTP(string status){
	return status == "STP";
}


bool isUKN(string status){
	if(isOPS(status))
		return false;

	if(isSBY(status))
		return false;

	if(isSSB(status))
		return false;

	if(isINI(status))
		return false;

	if(isDEG(status))
		return false;

	if(isUS(status))
		return false;

	if(isTEC(status))
		return false;

	if(isWIP(status))
		return false;

	if(isABS(status))
		return false;

	if(isSTP(status))
		return false;

	return true;
}

// Check if the specified Dp is available (usually used for distributed Dp)
bool distributedDpAvailable(string dpName)
{
		bool exist;
		int isReadable;
		string dummy;
		exist = dpExists(dpName);  // if Dp exists

		if (exist == false)
			return false;

		isReadable = dpGet(dpName, dummy); // if readable
		dyn_errClass err;
		err = getLastError();   // if previous function terminated without errors
		if (exist && isReadable == 0 && err == "")
			return true;  		// dp or connection ok
		else
			return false;	  		// dp or connection not ok
} //bool distributedDpAvailable(string dpName)

// Strip defined postfix of a dp Name
string sgStripDpName(string rawDpName, string postfix)
{
	string s =	dpSubStr(rawDpName, DPSUB_DP_EL);

	if(postfix == "")
		return s;

	int pos = strpos(s, postfix);

	if(pos < 0)
		return s;		// postfix not found

	return substr(s, 0, pos);
}

// This function returns a dyn_string containing all the datapoints of the specified Type
dyn_string getPointsOfType(string dpType)
{
	dyn_dyn_string couples;
	dyn_string couple;
	dyn_string systems;
	string type;
	string postfix;
	dyn_string points;
	string point;
	string pointName;
	dyn_string pointsName;
	int cpt;
	int cpt2;

	couples = dpGetRefsToDpType(dpType);

	for(cpt = 1; cpt <= dynlen(couples); cpt++){
		couple = couples[cpt];
		type = couple[1];
		postfix = "." + couple[2];

		points = dpNames("*", type);
		for(cpt2 = 1; cpt2 <= dynlen(points); cpt2++)
		{
			point = points[cpt2] + postfix;
			// cutting the "System1:" string
			pointName = substr(point, strpos(point, ":")+1);
			dynAppend(systems, pointName);
		}
	}

	pointsName = dpNames("*", dpType);
	for (int i = 1; i <= dynlen(pointsName); i++)
	{
		pointName = substr(pointsName[i], strpos(pointsName[i], ":")+1);
		dynAppend(systems, pointName);
	}	// for

	return systems;
}

// return declared remote systems
dyn_string sgFwGetRemoteSystems()
{
	dyn_string systems;

//	systems = getPointsOfType("sgFwSystem");  // PW: 2015-01-08 don't understand this unuseful line
	dpGet("FwUtils.HistoryQuery.RemoteSystems", systems);
	return systems;
}

// check the length of the two given dyn_string
// return true if the same lenght, else false
bool check2DynLength(dyn_string ds1, dyn_string ds2)
{
	if(dynlen(ds1) != dynlen(ds2))
		return false;
	else
		return true;
}

// return the active chain based on the redu manager
char returnActiveChain()
{
	bool status;
	dpGet("_ReduManager.Status.Active", status);

	if (status)
		return 'A';
	else
	{
		dpGet("_ReduManager_2.Status.Active", status);
		if (status)
			return 'B';
		else
			return '?';
	}
}

string sgGetSystemPrefix() {
	string name = getSystemName();
  name = substr(name, 0, strlen(name) -1) + "_";
  return name;
}

string sgGetSystemSite() {
  string systemName = getSystemName();
	string site = "";
	int start = strpos(systemName, "_") + 1;
	int end = strpos(systemName, ":");
  return substr(systemName, start, end - start);
}
