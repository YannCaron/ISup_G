
const string DBKEY_HMI_SUPERVISED_SYSTEMS_TABLE = "Supervised systems table";
const string DBKEY_HMI_LABELS_LIST = "Events All labels";
const string DBKEY_HMI_SYSTEMS_LIST = "Events All systems";
const string DBKEY_HMI_HISTORIES_LIST = "Events All histories";
const string DBKEY_HMI_ALARMS_LIST = "Events All Alarms";

// Create and fill the DB for HMI
// This function is called in the eventInitialize of the sgBasePanel.pnl

bool initSupervisedSystemsLists()
{
	bool b;
	dyn_string empty;

	sgDBInit();

	b = sgDBCreateTable(DBKEY_HMI_SUPERVISED_SYSTEMS_TABLE);
//	if(!b)
//		return false;

	dyn_string remoteSystems;

	sgDBCreateTable(DBKEY_HMI_SUPERVISED_SYSTEMS_TABLE);
	sgDBSet(DBKEY_HMI_SUPERVISED_SYSTEMS_TABLE, DBKEY_HMI_LABELS_LIST, empty);
	sgDBSet(DBKEY_HMI_SUPERVISED_SYSTEMS_TABLE, DBKEY_HMI_SYSTEMS_LIST, empty);
	sgDBSet(DBKEY_HMI_SUPERVISED_SYSTEMS_TABLE, DBKEY_HMI_HISTORIES_LIST, empty);
	sgDBSet(DBKEY_HMI_SUPERVISED_SYSTEMS_TABLE, DBKEY_HMI_ALARMS_LIST, empty);

	dyn_string labels;
	dyn_string historiesPoints;
	dyn_string alarmsPoints;
	dpGet("FwUtils.SupervisedSystems.Labels", labels,
          "FwUtils.SupervisedSystems.HistoryDpNames", historiesPoints,
          "FwUtils.SupervisedSystems.AlarmsDpNames", alarmsPoints);

	if(!check2DynLength(labels, historiesPoints) || !check2DynLength(labels, alarmsPoints))
	{
		sgHistoryAddEvent("FwUtils.HistoryQuery", SEVERITY_SYSTEM, "initSupervisedSystemsLists >> labels length is not the same as historyPoingths length or alarmsPoint");
		return false;
	}

	remoteSystems = sgFwGetRemoteSystems();

	for(int cpt = 1; cpt <= dynlen(labels); cpt++)
	{
		sgDBAppend(DBKEY_HMI_SUPERVISED_SYSTEMS_TABLE, DBKEY_HMI_LABELS_LIST, labels[cpt]);
		sgDBAppend(DBKEY_HMI_SUPERVISED_SYSTEMS_TABLE, DBKEY_HMI_SYSTEMS_LIST, getSystemName());
		sgDBAppend(DBKEY_HMI_SUPERVISED_SYSTEMS_TABLE, DBKEY_HMI_HISTORIES_LIST, historiesPoints[cpt]);
		sgDBAppend(DBKEY_HMI_SUPERVISED_SYSTEMS_TABLE, DBKEY_HMI_ALARMS_LIST, alarmsPoints[cpt]);
	}

	// Get remote systems

	// Add all remote system in the combo
	for (int i = 1; i <= dynlen(remoteSystems); i++)
	{
          // to check if remote system exists
	  if(dpExists(remoteSystems[i] + "FwUtils.SupervisedSystems.Labels"))
          {
                dyn_string remoteLabels;
		dyn_string remoteHistoriesDpNames;
		dyn_string remoteAlarmsDpNames;

		// DebugN("sgFwHistoryQueryPanel: " + remoteSystems[i] + ":" + "FwUtils.HistoryQuery.Labels");
		dpGet(remoteSystems[i] + "FwUtils.SupervisedSystems.Labels", remoteLabels,
					remoteSystems[i] + "FwUtils.SupervisedSystems.HistoryDpNames", remoteHistoriesDpNames,
					remoteSystems[i] + "FwUtils.SupervisedSystems.AlarmsDpNames", remoteAlarmsDpNames);

		if(!check2DynLength(remoteLabels, remoteHistoriesDpNames) || !check2DynLength(remoteLabels, remoteAlarmsDpNames))
		{
			DebugTN("initSupervisedSystemsLists >> dynlen of lists for system: " + remoteSystems[i] + " are not the same, system skiped");
			sgHistoryAddEvent("FwUtils.HistoryQuery", SEVERITY_SYSTEM, "initSupervisedSystemsLists >> Supervised system: " + remoteSystems[i] + " labels length is not the same as historyPoingths length or alarmsPoint");
			continue;
		}

		for (int id = 1; id <= dynlen(remoteLabels); id++)
		{
			sgDBAppend(DBKEY_HMI_SUPERVISED_SYSTEMS_TABLE, DBKEY_HMI_LABELS_LIST, remoteLabels[id]);
			sgDBAppend(DBKEY_HMI_SUPERVISED_SYSTEMS_TABLE, DBKEY_HMI_SYSTEMS_LIST, remoteSystems[i]);
			sgDBAppend(DBKEY_HMI_SUPERVISED_SYSTEMS_TABLE, DBKEY_HMI_HISTORIES_LIST, remoteHistoriesDpNames[id]);
			sgDBAppend(DBKEY_HMI_SUPERVISED_SYSTEMS_TABLE, DBKEY_HMI_ALARMS_LIST, remoteAlarmsDpNames[id]);
		}
          }// dpExists
	} // loop to add all remote systems

	return true;
}

void ForceToUnknown(string systemName, string name)
{

	dyn_string outputs, defaultValues;
	dyn_string watchDogsDpe, historyDpe;

	// get watch dogs dpe
	watchDogsDpe = dpGetDpFromType(systemName + name, "sgWatchDogs");
	historyDpe = dpGetDpFromType(systemName + name, "sgFwHistory");

	// get watchdogs
	dpGet(watchDogsDpe + OUTPUTS_POSTFIX, outputs);
 	dpGet(watchDogsDpe + DEFAULT_VALUES_POSTFIX, defaultValues);

	ForceToUnknownPoints(systemName, outputs, defaultValues);
  
	// prepare to UKN
	if (isExistDpType(systemName + name, "sgXMLMatchingTable"))
	{
		sgXMLPrepareForceToUKN();
	}

	// add history
	sgHistoryAddEvent(historyDpe, SEVERITY_COMMAND, "<<Force to UKN>> sent");

}

void ForceToUnknownDistributedSystem(string systemName, string name, dyn_string watchdogPostfixes, string historyPostFix) {
	dyn_string outputs, defaultValues;
	string systemPrefix;
	string historyDpe;

	historyDpe = systemName + name + "." + historyPostFix;
	systemPrefix = systemName + name + ".";

	for (int i = 1; i <= dynlen(watchdogPostfixes); i++) {
		dyn_string watchdogOutputs, watchdogDefaultValues;
		dpGet(
			systemPrefix + watchdogPostfixes[i] + OUTPUTS_POSTFIX, watchdogOutputs, 
			systemPrefix + watchdogPostfixes[i] + DEFAULT_VALUES_POSTFIX, watchdogDefaultValues);
		dynAppend(outputs, watchdogOutputs);
		dynAppend(defaultValues, watchdogDefaultValues);
	}

  	ForceToUnknownPoints(systemName, outputs, defaultValues);

	// add history
	sgHistoryAddEvent(historyDpe, SEVERITY_COMMAND, "<<Force to UKN>> sent");  
  
}

void ForceToUnknownPoints(string systemName, dyn_string outputs, dyn_string defaultValues) {
 	dyn_string names, values;

	for (int i=1; i<=dynlen(outputs); i++)
	{

		// variable
		dyn_string outputNames;

    	// get names
		outputNames = getPointsFromPattern(systemName + outputs[i]);

		// loop on names
		for (int j=1; j<=dynlen(outputNames); j++)
		{
			dynAppend(names, outputNames[j]);
			dynAppend(values, defaultValues[i]);
		}

	}

	// set ukn to systems
	dpSet(names, values);

}
