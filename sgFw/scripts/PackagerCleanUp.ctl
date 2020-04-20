main() {
	enableAllSgFwSystems();
	clearAllSgFwHistories();
	clearAllErrorLists();
}

void setValueOnAll(string typeName, string subPoint, anytype value) {
	dyn_string dps = getPointsOfType(typeName);
	for (int i=1; i<=dynlen(dps); i++) {
		dpSet(dps[i] + subPoint, value);
		DebugTN ("Cleanup " + dps[i] + subPoint);
	}
}

void enableAllSgFwSystems() {

	setValueOnAll ("sgFwSystem", ".Disabled", FALSE);
	DebugTN("Enable all sgFwSystem succeed !");

}

void clearAllSgFwHistories() {

	dyn_string empty_ds;
	setValueOnAll ("sgFwHistory", ".Message", "");
	setValueOnAll ("sgFwHistory", ".ShortHistory", empty_ds);
	DebugTN("Clear all sgFwHistory succeed !");

}

void clearAllErrorLists() {
	
	dyn_string empty_ds;
	setValueOnAll ("sgErrorsList", ".Lists.Objects", empty_ds);
	setValueOnAll ("sgErrorsList", ".Lists.Statuses", empty_ds);
	setValueOnAll ("sgErrorsList", ".Lists.Texts", empty_ds);
	DebugTN("Clear all sgErrorsList succeed !");

}