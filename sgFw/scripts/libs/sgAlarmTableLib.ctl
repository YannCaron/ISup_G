private const int ALARMLIST_COLUMN_DP = 1;
private const int ALARMLIST_COLUMN_DIRECTION = 3;
private const int ALARMLIST_COLUMN_VISIBLE = 4;
private const int ALARMLIST_COLUMN_LAST = 5;
private const int ALARMLIST_COLUMN_SUM = 6;
private const int ALARMLIST_COLUMN_TIME = 7;
private const int ALARMLIST_COLUMN_CLASS = 8;
private const int ALARMLIST_COLUMN_FREE = 3;
private const int ALARMLIST_COLUMN_COLOR = ALARMLIST_COLUMN_FREE;

private const string ALARMLIST_COLUMN_NAME_DP = "dp";

private const string ALARMLIST_MANDATORY_COLUMNS = "'_alert_hdl.._direction', '_alert_hdl.._visible', '_alert_hdl.._last_of_all', '_alert_hdl.._sum', '_alert_hdl.._system_time', '_alert_hdl.._class', '_alert_hdl.._prior'";

private const string WARNING_SYSTEM = "infra";
private const string ALARMLIST_REPLACE_WARNING_COLOR = "alertWentUna";

private global mapping loading;
private global mapping setters;
private global mapping actions;

private bool callback;

// method
private void initialize(string tableName) {

  // initialize formaters
  setters["_direction"] = "setter_direction";
  setters["_ackable"] = "setter_ack";
  setters["_alert_color"] = "setter_alert_color";
  setters["_dp_list"] = "setter_detail";

  actions["_ackable"] = "action_ack";
  actions["_panel"] = "action_panel";
  actions["_dp_list"] = "action_detail";
  
  // clear
  setValue(tableName, "deleteAllLines");
}

public void alertTableStopProcess(string tableName) {
	loading[tableName] = true;  
}

public void alertTable_initialize(string tableName, string pattern) {

//  DebugTN("sgAlarmTableLib.ctl; alertTable_initialize>; called ");
	initialize(tableName);  
  
  // query
  string list = ALARMLIST_MANDATORY_COLUMNS + ", " + getAlertConfigForTable(tableName);
  string query =
		"SELECT ALERT " + list + " " +
		"FROM '" + pattern + "' " +
		"REMOTE ALL " +
		"WHERE ('_alert_hdl.._active' == 1) AND ('_alert_hdl.._prior' > 10) AND ('_alert_hdl.._sum' == 0) "; // PW APRIL 2017; prior 10 = Info; not displayed
//  		"WHERE ('_alert_hdl.._active' == 1) AND ('_alert_hdl.._prior' >= 0) AND ('_alert_hdl.._sum' == 0) "; 
   
	dpQueryConnectSingle("alarm_callback", TRUE, tableName, query);
  
}

public void alertTable_initialize_timed(string tableName, dyn_string systems, string pattern, time from, time to) {
  
//  DebugTN("sgAlarmTableLib.ctl; alertTable_initialize_timed; called ");
    
	initialize(tableName);  
  
  // query
  dyn_dyn_anytype data;
  string list =  ALARMLIST_MANDATORY_COLUMNS + ", " + getAlertConfigForTable(tableName);
  
  for (int i = 1; i <= dynlen(systems); i++) {
    dyn_dyn_anytype dataPart;
	  string query = 
	      "SELECT ALERT " + list + " " +
	      "FROM '" + pattern + "' " +
	      "REMOTE '" + systems[i] + "' " +
// 	      "WHERE ('_alert_hdl.._prior' >= 0 AND ('_alert_hdl.._sum' == 0) )" +  
 	      "WHERE ('_alert_hdl.._prior' > 10 AND ('_alert_hdl.._sum' == 0) )" +   // PW APRIL 2017; prior 10 = Info; not displayed
        "TIMERANGE (\"" + (string)from + "\", \"" + (string)to + "\", 1, 0)";
    
//  DebugTN("sgAlarmTableLib.ctl; alertTable_initialize_timed; query: " + query );
    
		dpQuery(query, dataPart);

    if (i > 1) dynRemove(dataPart, 1);
    dynAppend(data, dataPart);
	}
  
  callback = false;
  setValue (tableName, "namedColumnVisibility", "_ackable", false);
  
	loadData(tableName, data, false, true);
    
}
public void alertPanel_terminate(string tableName) {
  if (callback) dpQueryDisconnect("alarm_callback", tableName);
}

public void alertTable_clicked(string tableName, int rowId, string columnName, string value) {
  if (mappingHasKey(actions, columnName)) {
    callFunction(actions[columnName], tableName, rowId, columnName, value);
  }
}

// function
private string getAlertConfigForTable(string tableName) {
  
  string result = "";
  int count;
  getValue(tableName, "columnCount", count);
  for (int i = 2; i < count; i++) {

    string name;
    getValue(tableName, "columnName", i, name);
    
    if (strpos(name, "_") != -1 && strpos(ALARMLIST_MANDATORY_COLUMNS, name) == -1) {
      if (result != "") result += ", ";
      result += "'_alert_hdl.." + name + "'";
    }

  }
  return result;
}

private bool showWarning() {
//  return true; bypass
  string hostName = getHostname();
  if (strlen(hostName) < strlen(WARNING_SYSTEM)){
    return false;
  }
   
  hostName = strtolower(substr(hostName, 0, strlen(WARNING_SYSTEM)));
  return (hostName == WARNING_SYSTEM);  
}

private string convertDirection(bool value) {
  if (value) {
    return "CAME";
  } else {
    return "WENT";
  }
}

private string setter_direction(string tableName, int rowId, string columnName, bool value) {
  setValue(tableName, "cellValueRC", rowId, columnName, convertDirection(value));
}

private string setter_ack(string tableName, int rowId, string columnName, bool value) {
  if (value) {
    setValue(tableName, "cellValueRC", rowId, columnName, "!!!");
    setValue(tableName, "cellForeColRC", rowId, columnName, "STD_alert");
    setValue(tableName, "cellBackColRC", rowId, columnName, "white");
  } else {
    setValue(tableName, "cellValueRC", rowId, columnName, "x");
    setValue(tableName, "cellForeColRC", rowId, columnName, "black");
    setValue(tableName, "cellBackColRC", rowId, columnName, "_3DFace");
  }
}

private string setter_alert_color(string tableName, int rowId, string columnName, string value) {
  string abbr;
  getValue(tableName, "cellValueRC", rowId, "_abbr", abbr);
  setValue(tableName, "cellValueRC", rowId, columnName, abbr);
  setValue(tableName, "cellBackColRC", rowId, columnName, value);
}

private string setter_detail(string tableName, int rowId, string columnName, string value) {
  setValue(tableName, "cellValueRC", rowId, columnName, "...");
}


private string setter_debug(string tableName, int rowId, string columnName, string value) {
  DebugTN("Value [" + rowId + ", " + columnName + "] to debug:" + value);
  setValue(tableName, "cellValueRC", rowId, columnName, value);
}

private void action_ack(string tableName, int rowId, string columnName, string value) {
  if (value == "!!!") {
    string dp;
    getValue(tableName, "cellValueRC", rowId, "dp", dp);
    dpSet(dp + ":_alert_hdl.._ack", TRUE);
  }
}

private void action_panel(string tableName, int rowId, string columnName, string value) {
  string dp;
  dyn_string params;

  getValue(tableName, "cellValueRC", rowId, "dp", dp);
  dpGet(dp + ":_alert_hdl.._panel_param", params);
  
  sgFwSetNaviParams(value, params);
  sgFwNaviPanelOn();  
}

private void action_detail(string tableName, int rowId, string columnName, string value) {
  string dp;
  getValue(tableName, "cellValueRC", rowId, "dp", dp);

  ChildPanelOnCentralModal("sgFw\\sgFwMessageBox.pnl", "", 
                           makeDynString("$title:Dp Info", "$content:" + dp, "$type:" + MSGBOX_INFO));
}

private int getLineNumber(string tableName, string dp, bool direction) {
  
  int count;
  int res;
  getValue(tableName, "lineCount", count);
  for (int rowId = 0; rowId < count; rowId++) { // start on 0; PW 8.5.2015
    string searchDp;
    bool searchDir;
    
    getValue(tableName, "cellValueRC", rowId, "dp", searchDp);
    getValue(tableName, "cellValueRC", rowId, "dir", searchDir);
    
    if (dp == searchDp && direction == searchDir) {
      //DebugTN("dp:" + dp + "/" + searchDp + ", direction:" + convertDirection(direction) + "/" + convertDirection(searchDir) + ", rowId:" + rowId);
      return rowId;
    }
  }
  
  return -1;
}

private void removeLine(string tableName, string dp, bool direction) {
  int rowId = getLineNumber(tableName, dp, direction);
  
  if (rowId != -1) {
    setValue(tableName, "deleteLineN", rowId);
  }
}

private void alarm_callback(string tableName, dyn_dyn_anytype data) {

  callback = true;
  setValue (tableName, "namedColumnVisibility", "_ackable", true);

  loadData(tableName, data, true);
  
}

private void loadData(string tableName, dyn_dyn_anytype data, bool unique) {
  loading[tableName] = false;  
  if (dynlen(data) <= 1) return;
  
  // for sorting remove first line that has another types  
  dyn_anytype header = data[1];
  dynRemove(data, 1);
  
  // because sort does not works with dpConnectQuery
  dynDynSort(data, makeDynInt(ALARMLIST_COLUMN_TIME, ALARMLIST_COLUMN_LAST), makeDynBool(true, true));
  
  for (int r = 1; r <= dynlen(data); r++) {
    dyn_anytype line = data[r];

    string dp = line[ALARMLIST_COLUMN_DP];
    bool direction = line[ALARMLIST_COLUMN_DIRECTION];
    bool visible = line[ALARMLIST_COLUMN_VISIBLE];
    bool last = line[ALARMLIST_COLUMN_LAST];
    bool sum = line[ALARMLIST_COLUMN_SUM];
    time timee = line[ALARMLIST_COLUMN_TIME];
    string class = line[ALARMLIST_COLUMN_CLASS];

    int rowId = getLineNumber(tableName, dp, direction);

    // ignore sum and ignore warning if it should be
    if (sum || !showWarning() && wagoAlarmSubString(class) == wagoAlarmSubString(WAGO_ALARMS[3])) continue;
    
    // show or remove
    if (visible || !unique) {

      if (rowId == -1 || !unique) {
        getValue(tableName, "lineCount", rowId);
        setValue(tableName, "appendLine", "line");
      }
      
      // set identifier
      setValue(tableName, "cellValueRC", rowId, "dp", dp);
      setValue(tableName, "cellValueRC", rowId, "dir", direction);
      
      for (int c = ALARMLIST_COLUMN_FREE; c <= dynlen(line); c++) {
        if (loading[tableName]) return;
        
        string columnName = substr((string)header[c], strlen("_alert_hdl..") + 1); // keep only the alert hdl name

        // apply formater if any
        if (mappingHasKey(setters, columnName)) {
          callFunction(setters[columnName], tableName, rowId, columnName, line[c]);
        } else {
          setValue(tableName, "cellValueRC", rowId, columnName, line[c]);
        }
      
      }
    
    } else {
      setValue(tableName, "deleteLineN", rowId);
    }
      
  }
  
}
