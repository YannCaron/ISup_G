private const string DISABLED_QUERY = "SELECT '_original.._value' FROM '*.**.Disabled' WHERE ('_original.._value' == 1)";
private const string DISABLED_STATUS_DP = "ISupDisabled.GlobalStatus";
private const int DELAY = 10;

private bool running = false;

void checkDisabled() {
	dyn_dyn_anytype disabledData, data;

	dpQuery(DISABLED_QUERY, disabledData);

	if (dynlen(disabledData) < 2) return;

	string from = "{";  

	for (int r = 2; r <= dynlen(disabledData); r++) {
		string dpName = disabledData[r][1];
		strreplace(dpName, ".Disabled", ".DisabledTime");

		if (r > 2) from += ",";
		from += dpName;
	}

	from += "}";

	// get all disabled system that timed out
	string query = "SELECT '_original.._value', '_online.._userbyte1' FROM '" + from + "' WHERE ('_original.._value' > 0 AND '_original.._value' <= " + period(getCurrentTime()) + ")";

	dyn_dyn_anytype data;
	dpQuery(query, data);

	// get if alarm must be raised
	bool hasNewDisabled = false;
	for (int i = 2; i <= dynlen(data); i++) {
		if (!data[i][3]) hasNewDisabled = TRUE;
	}

	if (hasNewDisabled) {
		dpSet(DISABLED_STATUS_DP + PRE_STATUS_POSTFIX, U_S_STATUS);
		acknowledgeDisabled(data);
	} else if (dynlen(data) >= 2) {
		dpSet(DISABLED_STATUS_DP + PRE_STATUS_POSTFIX, DEG_STATUS);
	} else {
		dpSet(DISABLED_STATUS_DP + PRE_STATUS_POSTFIX, OPS_STATUS);
	}

}

void acknowledgeDisabled(dyn_dyn_anytype data) {

	dyn_string dpNames = makeDynString();
	dyn_bool values = dynFillBool(dynlen(data) - 1, TRUE);

	for (int r = 2; r <= dynlen(data); r++) {
		string dpName = data[r][1];

		dynAppend(dpNames, dpName + ":_original.._userbyte1");
	}

	dpSet(dpNames, values);

	DebugTN(dpNames);

}

void thread() {
	running = true;

	while(running) {
		checkDisabled();

		// wait for loop
		delay(DELAY);
	}

}

main() {
	startThread("thread");
}