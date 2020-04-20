public void startXMLDispatcher(string dp)
{
  
	// objects
  dispatchObjectsSync(dp);
  dispatchEventsSync(dp);

}

void dispatchObjects(	string dpe1, string status,
											string dpe2, string objectID,
											string dpe3, string text)
{
	string dp = dpSubStr(dpe1,DPSUB_DP);
	sgHistoryAddEvent(dp + ".SystemHistory", SEVERITY_SYSTEM, "Object received: " + objectID + "::" + status + "::" + text);

	dpSet(dp + ".Components.ErrorsList.Change.Object", objectID,
				dp + ".Components.ErrorsList.Change.Status", status,
				dp + ".Components.ErrorsList.Change.FullText", text);
}

void dispatchEvents(	string dpe1, string status,
											string dpe2, string event)
{
	string dp = dpSubStr(dpe1,DPSUB_DP);
	sgHistoryAddEvent(dp + ".SystemHistory", SEVERITY_SYSTEM, "Event received: " + event + "::" + status);

	dyn_string events;
	dpGet(dp + ".Components.NewCriticalEvents", events);
	
	dynAppend(events,event);

	dpSet(dp + ".Components.NewCriticalEvents", events,
				dp + ".Components.CriticalEventsStatus.PreStatus", U_S_STATUS);

	sgHistoryAddEvent(dp + ".Components.ErrorsList.History" , SEVERITY_SYSTEM, event);
}
