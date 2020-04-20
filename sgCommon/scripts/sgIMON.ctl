void main () {
  dpConnect("status_onChanged", true, "IMON.Data.Alerts.Status", "IMON.Components.AlertConnection.Status");
}

void status_onChanged(string messagesDp, string messagesValues, string connectionDp, string connectionStatus) {
  
  dpSet("IMON.Components.Alerts.PreStatus", getAlertStatus(messagesValues, connectionStatus));
  dpSet("IMON.Components.Warnings.PreStatus", getWarningStatus(messagesValues, connectionStatus));
  
}

string getAlertStatus(string messagesValues, string connectionStatus) {
  dyn_string statuses = strsplit(messagesValues, ";");

  string result = "OPS";
  if (connectionStatus == "OPS") {
	  for (int i = 1; i <= dynlen(statuses); i++) {
		if (statuses[i] == "ERROR") {
		  return "U/S";
		}
	  }
  } else {
	   result = "UKN";
  }
  return result;
}

string getWarningStatus(string messagesValues, string connectionStatus) {
  dyn_string statuses = strsplit(messagesValues, ";");

  string result = "OPS";
  if (connectionStatus == "OPS") {
	  for (int i = 1; i <= dynlen(statuses); i++) {
		if (statuses[i] == "WARNING") {
		  return "U/S";
		}
	  }
  } else {
	   result = "UKN";
  }
  return result;
}

