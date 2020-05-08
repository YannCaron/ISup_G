global mapping collapsibleMenu_dp_entries;
global dyn_int collapsibleMenu_alarm_status = makeDynInt(0, 3, 1, 2, 2);

void collapsibleMenu_panel_initialize() {

  menu.setStyleSheetFile(getPath(STYLE_REL_PATH, "CollapsibleMenu.qss"));
  menu.setOffIconFilename(getPath(IMAGES_REL_PATH, "widgets/CollapsibleMenu.offAlarm.svg"));
  menu.setOnIconFilename(getPath(IMAGES_REL_PATH, "widgets/CollapsibleMenu.onAlarm.svg"));

  // menu  
  dyn_string menuEntries = getPointsOfType("sgFwMenuEntry");
  for (int i = 1; i <= dynlen(menuEntries); i++) {
    string menuEntry = menuEntries[i];
    string dpIdent = dpParent(menuEntry);
    string name, group, panel, params, globalStatusPoint;
    bool isHidden, separator;
    
    dpGet(menuEntry + ".Group", group,
          menuEntry + ".Name", name,
          menuEntry + ".Panel", panel,
          menuEntry + ".Params", params,
          menuEntry + ".Hidden", isHidden,
          menuEntry + ".Separator", separator,
          menuEntry + ".GlobalStatusPoint", globalStatusPoint);
    
    if (!isHidden || group == "") {
	    if (name == "") {
	      DebugTN("Menu entry not configured for [" + menuEntry + "]!");
	    } else {
        if (group == "") {
	    	  menu.addMenuFirst(group, name, dpIdent);
        } else {
	    	  menu.addMenu(group, name, dpIdent);
      	}
	      collapsibleMenu_dp_entries[dpIdent] = makeDynString(group, name, panel, params, "");
      
			  if (globalStatusPoint == "") globalStatusPoint = dpParent(menuEntry) + ".GlobalStatus";
		 		dpConnect("menuAlarm_changed", true, globalStatusPoint + ALARM_ACTIVE_POSTFIX + ":_alert_hdl.._act_state");
      
	      if (separator) menu.addSeparator();
	    }
	  }
  }

	initializeDistributed();
  connectDistribution();
}

void menuAlarm_changed(string dp, int alarm) {
  string dpIdent = dpParent(dpParent(dpParent(dpSubStr(dp, DPSUB_DP_EL))));
  applyStatus(dpIdent, alarm);
}

void collapsibleMenu_menu_clicked(string group, string name, string data) {
	dyn_string entry = collapsibleMenu_dp_entries[data];
  string panel = entry[3];
  string params = entry[4];
  
  dyn_string ds = strsplit(params, ";");
  ds = dynInsertEachString(ds, "$");
	
// P.W. New navigation concept
	sgFwSetNaviParams(panel, ds);
	sgFwNaviPanelOn();

}

// distributed 							--------------------------------------------------------------------
string prevActiveChain;
mapping dsConnected;
mapping groups;

void initializeDistributed() {

  dyn_string distributedSystems;
	dpGet("FwUtils.SupervisedSystems.RemoteSystems", distributedSystems);
  
  // determin groups
 	for (int i = 1; i <= dynlen(distributedSystems); i++) {
    string ds = distributedSystems[i];
    string group = substr(ds, 0, strpos(ds, "_"));
    
    if (mappingHasKey(groups, group)) {
      groups[group] = group;
    } else {
      groups[group] = "";
    }
  }
  
  // add menu
  menu.addSeparator();  
  
  for (int i = 1; i <= dynlen(distributedSystems); i++) {
    string ds = distributedSystems[i];
    string name = substr(ds, 0, strpos(ds, ":"));
    string group = groups[substr(ds, 0, strpos(ds, "_"))];
    
    menu.addMenuLast(group, name, ds);
    collapsibleMenu_dp_entries[ds] = makeDynString(group, name, name + "_RootPanel.pnl", "", "");
  }
  
  // initialize connected
  for (int i=1; i<=dynlen(distributedSystems); i++) {
    dsConnected[distributedSystems[i]] = false;
	}
  
}

void connectDistribution() {
	dpConnect("distribution_changed", TRUE, ACTIVE_CHAIN, 
                  "_Connections.Dist.ManNums", "_Connections_2.Dist.ManNums", 
                  "_DistManager.State.SystemNums", "_DistManager_2.State.SystemNums");
        
}

bool isDistributionRunning(string activeChain, dyn_int manNumsA, dyn_int manNumsB) {
  return ((activeChain == "A" && dynlen(manNumsA) > 0) || (activeChain == "B" && dynlen(manNumsB) > 0));
}

bool isDSRunning(string distributedSystem, string activeChain, dyn_int systemNumsA, dyn_int systemNumsB) {
	int systemId = getSystemId(distributedSystem);
  return ((activeChain == "A" && dynContains(systemNumsA, systemId)) || (activeChain == "B" && dynContains(systemNumsB, systemId)));
}

void distribution_changed(string activeChainDP, string activeChain, 
                          string manNumsADP, dyn_int manNumsA,
                          string manNumsBDP, dyn_int manNumsB,
                          string systemNumsADP, dyn_int systemNumsA, 
                          string systemNumsBDP, dyn_int systemNumsB) {

  // manage distributed system status mapping
  for (int i = 1; i <= mappinglen(dsConnected); i++) {
    string distributedSystem = mappingGetKey(dsConnected, i);

    if (isDistributionRunning(activeChain, manNumsA, manNumsB)) {
      
      if (dsConnected[distributedSystem]) dpQueryDisconnect("distributedAlert_updated", distributedSystem);

      if (isDSRunning (distributedSystem, activeChain, systemNumsA, systemNumsB)) {
        dsConnected[distributedSystem] = true;
        dpQueryConnectSingle("distributedAlert_updated", TRUE, distributedSystem, 
                             "SELECT '_alert_hdl.._act_state' FROM '" + SYSTEM_GLOBAL  + ALARM_ACTIVE_POSTFIX + "' REMOTE '" + distributedSystem + "'");  
      } else {
        dsConnected[distributedSystem] = false;
      }
    } else {
      dsConnected[distributedSystem] = false;
      applyStatus(distributedSystem, DPATTR_ALERTSTATE_NONE);
    }
    
    applyConnected(distributedSystem, dsConnected[distributedSystem]);
  }
  
}

void distributedAlert_updated (string ident, dyn_dyn_anytype ds) {

  loadText(ident);
  int alarm = DPATTR_ALERTSTATE_NONE;
  
  if (dynlen(ds) >= 2) {
    alarm = ds[2][2];
  }

  applyStatus(ident, alarm);
  
}

void loadText(string ident) {

  dyn_string entry = collapsibleMenu_dp_entries[ident];
  
  if (entry[5] == "") {
    string remoteName;
    remoteName = dpGetDescription(ident + "SystemStatus.GlobalStatus");
  
    if (remoteName != "") {
      string group = entry[1];
      string name = entry[2];
  
      collapsibleMenu_dp_entries[ident][5] = remoteName;
      menu.setText(group, name, remoteName);
    }
  
  }
  
}
void applyConnected(string ident, bool isConnected) {
  dyn_string entry = collapsibleMenu_dp_entries[ident];
  string group = entry[1];
  string name = entry[2];
  
  menu.setConnectionStatus(group, name, isConnected);
}

void applyStatus(string ident, int alarm) {
  dyn_string entry = collapsibleMenu_dp_entries[ident];
  string group = entry[1];
  string name = entry[2];

  menu.setStatus(group, name, collapsibleMenu_alarm_status[alarm + 1]);
}
