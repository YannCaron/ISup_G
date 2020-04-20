// Version 1.2 ; LLZ-> LOC

global dyn_string rawStatusesNames;
global dyn_string integerStatuses;

void addComboSelectionForGlobalSet(string rawStatusName, string integerStatus)
{
	int index;
	index = dynContains(rawStatusesNames, rawStatusName);

	if(index >= 1)	// already exists
	{	// update value
		integerStatuses[index] = integerStatus;
	}
	else
	{
		dynAppend(rawStatusesNames, rawStatusName);
		dynAppend(integerStatuses, integerStatus);
	}
//	DebugTN("addComboSelectionForGlobalSet(rawStatusName, integerStatus) called. rawStatusesNames: " + rawStatusesNames);
//	DebugTN("addComboSelectionForGlobalSet(rawStatusName, integerStatus) called. integerStatuses: " + integerStatuses);
}

void writeStatuses()
{
//	DebugTN("writeStatuses called. rawStatusesNames: " + rawStatusesNames);
//	DebugTN("writeStatuses called. integerStatuses: " + integerStatuses);

	dpSet(rawStatusesNames, integerStatuses);
	dynClear(rawStatusesNames);
	dynClear(integerStatuses);
		
}

string getRawILSCATDps(string sysname)
{
	string INCHILSCATDps;
	dyn_string ILSNames;	
	ILSNames = dpNames(sysname + ":*", "sgNavirILS");
	//	DebugTN("INCHILSCATDps: " +INCHILSCATDps);	
	// Remove standard dummy ILS dp		
	dynRemove(ILSNames, dynContains(ILSNames, sysname + ":ILSDummyForHMICAT"));
		
	for (int i = 1; i <= dynlen(ILSNames); i++)  
	{
//		INCHILSCATDps = INCHILSCATDps + "," + ILSNames[i] + ".HMIStatuses.CATIIIStatus" + PRE_STATUS_POSTFIX;
//		INCHILSCATDps = INCHILSCATDps + "," + ILSNames[i] + ".HMIStatuses.CATIIStatus" + PRE_STATUS_POSTFIX;
//		INCHILSCATDps = INCHILSCATDps + "," + ILSNames[i] + ".HMIStatuses.CATIStatus" + PRE_STATUS_POSTFIX;
//		INCHILSCATDps = INCHILSCATDps + "," + ILSNames[i] + ".HMIStatuses.LOCDMEStatus" + PRE_STATUS_POSTFIX;

		INCHILSCATDps = INCHILSCATDps + "," + ILSNames[i] + ".RawDatas.CATIIIStatus" ;
		INCHILSCATDps = INCHILSCATDps + "," + ILSNames[i] + ".RawDatas.CATIIStatus" ;
		INCHILSCATDps = INCHILSCATDps + "," + ILSNames[i] + ".RawDatas.CATIStatus" ;
		INCHILSCATDps = INCHILSCATDps + "," + ILSNames[i] + ".RawDatas.LOCDMEStatus" ;

	}
	return INCHILSCATDps;
} // getRawILSCATDps()

void setFullSystemSituation(string sysname, int statusIntegerValue )
{
	dyn_string dps;
	dyn_string statuses;
	string allDps;
	allDps = getRawILSCATDps(sysname);
	
	dps = strsplit(allDps, ",");
	dynRemove(dps, 1);
	
	dynAppend(dps, dpNames(sysname + ":*.RawDatas.Navaid_*.OperationalStatus", "sgNavirStation"));
	dynAppend(dps, dpNames(sysname + ":*.RawDatas.Navaid_*.Status", "sgNavirStation"));


//PW March 2007 special case for Les Eplatures. Must be removed when Les Eplatures install through Network OPS!	

	dynAppend(dps, dpNames(sysname + ":*.RawDatas.Navaid_*.OperationalStatus", "sgSpecialNavirStation"));

	for(int i = 1; i <= dynlen(dps); i++)
	{
		dynAppend(statuses, statusIntegerValue); 
	}

	rawStatusesNames = dps;
	integerStatuses = statuses;

//	DebugTN("setSystemNormalSituation called. rawStatusesNames: " + rawStatusesNames);
//	DebugTN("setSystemNormalSituation called. integerStatuses: " + integerStatuses);

 	writeStatuses();
}

