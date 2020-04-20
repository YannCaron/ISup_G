/*
Author: Martin Koller, koller@bnet.at
Functions for the Alert-Screen
*/

//---------------------------------------------------------------------------
/*
Parameters:
  screen ... true=AlertScreen, false=AlertRow
Returns:
  returns the DP-Name of the Properties-DP for this Manager.
  a trailing dot "." is appended
*/

string as_getPropDP(bool screen)
{
  return (screen ? "_ASProp_" : "_ARProp_") + myManNum() + ".";
}

//---------------------------------------------------------------------------
/*
Do initialisation neccessary for AlertScreen/AlertRow
*/

as_init()
{
  string dpProp, dpASProp;
  string screenType;
  int ret;
  
  dyn_int diTypeSelections;
  int i;
  
  dyn_string dsSystemNames;
  dyn_uint   duSystemIds;
  int        iCheckSystemNames;

  addGlobal("g_asMaxLinesToDisplay", INT_VAR);
  addGlobal("g_asMaxDpeToDisplay", INT_VAR);
  addGlobal("g_asMaxDpeHourToDisplay", INT_VAR);

  dpGet("_Config.MaxLinesToDisplay:_online.._value",   g_asMaxLinesToDisplay,
        "_Config.MaxDpeToDisplay:_online.._value",     g_asMaxDpeToDisplay,
        "_Config.MaxDpeHourToDisplay:_online.._value", g_asMaxDpeHourToDisplay);

  addGlobal("g_asDisplayLines", INT_VAR);        g_asDisplayLines = 0;
  addGlobal("g_asDisplayDpes", INT_VAR);         g_asDisplayDpes = 0;
  addGlobal("g_asDisplayHours", INT_VAR);        g_asDisplayHours = 0;


  // As long as we do not have constants, we have to create global vars ...
  // AS_OPEN_RANGE_SEC is the number of seconds which are used for
  // splitting historical queries into pieces of this length
  addGlobal("AS_HIST_RANGE_SEC", INT_VAR); AS_HIST_RANGE_SEC = 3600*24;
  addGlobal("E_AS_FUNCTION", INT_VAR); E_AS_FUNCTION = 0;
  addGlobal("E_AS_DP_VAL",   INT_VAR); E_AS_DP_VAL = 1;
  addGlobal("AS_TYPEFILTER", DYN_STRING_VAR);
  addGlobal("AS_TYPECONST", DYN_INT_VAR);
  AS_TYPEFILTER = makeDynString( "bit",
                                 "bit32",
                                 "unsigned integer",
                                 "integer",
                                 "float" );
  AS_TYPECONST  = makeDynInt( DPEL_BOOL,
                              DPEL_BIT32,
                              DPEL_UINT,
                              DPEL_INT,
                              DPEL_FLOAT );

  g_timeLastUpdate = 0;

  // check wheter we are in AlertScreen or in AlertRow
  getValue("", "type", screenType);

// Checks if the Properties DP exists. If not, it creates it.
// PW:29.01.03 Prop with the SgAlertScreen
// Old: dpProp = as_getPropDP((screenType == "AlertScreen"));
  dpProp = as_getPropDP((screenType == "AlertScreen")||(screenType == "SgAlertScreen"));
  
  dpASProp = substr(dpProp, 0, strlen(dpProp)-1);  // remove "."
  
  // if Properties DP does not exist, create it
  if ( ! dpExists(dpASProp) )
  {
    bool vis;
    dyn_string sortList;
      
    if ( dpCreate(dpASProp, "_ASProperties") == -1 )
    {
      std_error("AS", ERR_SYSTEM, PRIO_SEVERE,
                E_AS_FUNCTION, "main(): dpCreate("+dpASProp+",_ASProperties)");
      return;
    }
    if ( dynlen(getLastError()) )
    { dyn_errClass err = getLastError();
      errorDialog(err);
      return;
    }
   // now set default-values
    getValue("", "namedColumnVisibility", "timeStr", vis);
    if ( vis ) sortList[1] = "timeStr";
     
    // Read names of all systems
    iCheckSystemNames = getSystemNames( dsSystemNames, duSystemIds );
    if( iCheckSystemNames == -1 )
    {
      std_error("AS", ERR_SYSTEM, PRIO_SEVERE,
                 E_AS_FUNCTION, "as_getPropsFilterTypes(): dpGet( ... FilterSystems ...)");
      return;
    }
    if ( dynlen(getLastError()) )
    {
      dyn_errClass err = getLastError();
      errorDialog(err);
      return;
    }
    
    // Default Values Filter Types
    for( i = 1; i <= dynlen( AS_TYPEFILTER ); i ++ )
      dynAppend( diTypeSelections, 0 );
    
    if ( dpSet(dpASProp + ".Settings.Filter.State:_original.._value", 0,
               dpASProp + ".Settings.Sorting.SortList:_original.._value", sortList,
               dpASProp + ".Settings.Timerange.Type:_original.._value", 0,
               dpASProp + ".Settings.Timerange.MaxLines:_original.._value", 100,
               dpASProp + ".Settings.Timerange.Chrono:_original.._value", true,
               dpASProp + ".Settings.Name:_original.._value", "",
               dpASProp + ".Settings.User:_original.._value", DEFAULT_USERID,
               dpASProp + ".Settings.Type.Selections:_original.._value", diTypeSelections,
               dpASProp + ".Settings.Type.AlertSummary:_original.._value", 0,
               dpASProp + ".Settings.System.Selections:_original.._value", dsSystemNames
              ) == -1 )
    {
      std_error("AS", ERR_SYSTEM, PRIO_SEVERE,
                E_AS_FUNCTION, "main(): dpSet(... default values ...)");
      return;
    }
  }
  
  // check if there is the correct number of typeselections
  dpGet( dpASProp + ".Settings.Type.Selections:_online.._value", diTypeSelections );
  if( dynlen( diTypeSelections ) != dynlen( AS_TYPEFILTER ) )
  {
    diTypeSelections = "";
    for( i = 1; i <= dynlen( AS_TYPEFILTER ); i ++ )
      dynAppend( diTypeSelections, 0 );
      
    dpSet( dpASProp + ".Settings.Type.Selections:_original.._value", diTypeSelections,
           dpASProp + ".Settings.Type.AlertSummary:_original.._value", 0 );
  }
  
  // Check if there is any system selected
  dpGet( dpASProp + ".Settings.System.Selections:_online.._value", dsSystemNames );
  if( dynlen( dsSystemNames ) <= 0 )
  {
    // Read and write names of all systems
    getSystemNames( dsSystemNames, duSystemIds );
    dpSet( dpASProp + ".Settings.System.Selections:_original.._value", dsSystemNames );
  }
  
// PW: 20.01.03 for SgAlertScreen no busy flag
  	if (screenType != "SgAlertScreen"){
		g_busyThread = -1;
		g_connectId = "";
		dynClear ( g_counterConnectId );
  
  		std_startBusy();
	}
  
  dpGet("_Config.ShowInternals:_online.._value", g_showInternals,
        "_Config.MaxLines:_online.._value", g_maxClosedLines);

// PW: 20.01.03 for SgAlertScreen
//old:  if ( screenType == "AlertScreen" )
  if ((screenType == "AlertScreen") || (screenType == "SgAlertScreen"))
  {
    unsigned action;
    dyn_dyn_anytype configs;
    dyn_string configNames;
    int i;
    
    // check if the user wants the Screen not to activate the query
    // but instead show the properties dialog
    dpGet(dpProp+"Action:_online.._value", action);
    
    // connect to cancel-bit
    ret = dpConnect( "as_cancel", dpProp + "Cancel:_original.._value" );
    if ( ret == -1 )
    {
    // PW: 20.01.03 for SgAlertScreen no busy flag
	  	if (screenType != "SgAlertScreen")
  		{
			std_stopBusy();
      	}
      std_error("AS", ERR_SYSTEM, PRIO_SEVERE,
                E_AS_FUNCTION, "main(): dpConnect(... Cancel ...)");
      return;
    }

   // get current filter settings  
    ret = dpConnect("as_propertiesScreenCB", action >= 2,
                    dpProp+"Settings.Filter.State:_online.._value",
                    dpProp+"Settings.Filter.Shortcut:_online.._value",
                    dpProp+"Settings.Filter.Prio:_online.._value",
                    dpProp+"Settings.Filter.DpComment:_online.._value",
                    dpProp+"Settings.Filter.AlertText:_online.._value",
                    dpProp+"Settings.Filter.DpList:_online.._value",
                    "_Config.MinPrio:_online.._value",
                
                    dpProp+"Settings.Sorting.SortList:_online.._value",
                
                    dpProp+"Settings.Timerange.Type:_online.._value",
                    dpProp+"Settings.Timerange.Begin:_online.._value",
                    dpProp+"Settings.Timerange.End:_online.._value",
                    dpProp+"Settings.Timerange.Chrono:_online.._value",
                    dpProp+"Settings.Timerange.MaxLines:_online.._value",
                    dpProp+"Settings.Timerange.Selection:_online.._value",

                    dpProp+"Settings.Name:_online.._value",
                    
                    dpProp+"Settings.Type.Selections:_online.._value",
                    dpProp+"Settings.Type.AlertSummary:_online.._value",
                    
                    dpProp+"Settings.System.Selections:_online.._value",
                    dpProp+"Settings.System.Selections:_online.._stime"
                   );
    if ( action <= 1 )
    {
    	// VL Do not open properties window by default
    	if (screenType != "SgAlertScreen"){
	      	as_openPropWindow("vision/SC/AS_properties");
	      	std_stopBusy();
	    }
    }
	// PW:29.01.03 no config combo for SgAlertscreen
	if (screenType != "SgAlertScreen"){
    	// see which configurations we have
    	configNames[1] = "";
    	as_getConfigList(configNames);
    	setValue("configNames", "items", configNames);
    	    }
  }
  else if ( screenType == "AlertRow" )
    ret = dpConnect("as_propertiesRowCB", true,
                    dpProp+"Settings.Filter.State:_online.._value",
                    dpProp+"Settings.Filter.Shortcut:_online.._value",
                    dpProp+"Settings.Filter.Prio:_online.._value",
                    dpProp+"Settings.Filter.DpComment:_online.._value",
                    dpProp+"Settings.Filter.AlertText:_online.._value",
                    dpProp+"Settings.Filter.DpList:_online.._value",

                    "_Config.MinPrio:_online.._value",
                    
                    dpProp+"Settings.Type.Selections:_online.._value",
                    dpProp+"Settings.Type.AlertSummary:_online.._value",
                    
                    dpProp+"Settings.System.Selections:_online.._value"
                   );

  if ( ret == -1 )
  {
  // PW: 20.01.03 for SgAlertScreen no busy flag
  	if (screenType != "SgAlertScreen")
  	{
    	std_stopBusy();
    }
    std_error("AS", ERR_SYSTEM, PRIO_SEVERE,
              E_AS_FUNCTION, "main(): dpConnect(... properties ...)");
    return;
  }
}

//-----------------------------------------------------------------------------
/*
 Get List of all configurations
Parameter:
  configNames (in/out) ... list of configurations (items are appended)
*/

as_getConfigList(dyn_string &configNames)
{
  dyn_dyn_anytype configs;
  int i;
  
  dpQuery("SELECT '_online.._value' FROM '*.Name' WHERE _DPT = \"_ASConfig\"", configs);
           
  if ( dynlen(getLastError()) ) 
  {        dyn_errClass err = getLastError(); 
    errorDialog(err); 
    return; 
  } 
             
  for (i = 2; i <= dynlen(configs); i++) 
    dynAppend(configNames, configs[i][2]);
}

//-----------------------------------------------------------------------------
/*
   open the properties window as a child panel
*/

as_openPropWindow(string panel)
{
  int i, count = 0, columns;
  bool vis;
  string cols, colNames, name;
  
  getValue("table", "columnCount", columns);
  
  for (i = 1; i <= columns; i++)
  {
    getValue("table", "columnVisibility", i - 1, vis,
                      "columnToName", i - 1, name);

    if ( vis && (name != "detail") )
    {
      string nam;
      getValue("table", "namedColumnHeader", name, nam);
      strreplace(nam, " ", "_");
      cols += ' ' + nam;
      colNames += ' ' + name;
      count++;
    }
  }
  
  ChildPanelOnCentralModal(panel, "",
     makeDynString("$colTitles:"+cols, "$colNames:"+colNames, "$count:"+count));
}

//-----------------------------------------------------------------------------
/*
Shows current Filter etc. Settings and issue SELECT statement
*/

as_propertiesScreenCB(string dpaState, unsigned valState,
             string dpaShortcut, string valShortcut,
             string dpaPrio, string valPrio,
             string dpaDpComment, string valdpCommentFilter,
             string dpaAlertText, string valAlertText,
             string dpaDpList, dyn_string valDpList,
             string dpaMinPrio, unsigned valMinPrio,
             
             string dpaSortList, dyn_string valSortList,
             
             string dpaType, unsigned valType,
             string dpaBegin, time valBegin,
             string dpaEnd, time valEnd,
             string dpaChrono, bool valChrono,
             string dpaMaxLines, unsigned valMaxLines,
             string dpaSelection, unsigned valSelection,

             string dpaConfig, string currentConfig,
             
             string dpaTypeSelections, dyn_int valTypeSelections,
             string dpaTypeAlertSummary, bool valTypeAlertSummary,
             
             string dpaSystemSelections, dyn_string valSystemSelections,
             string dpaSystemSelectionsTime, time valTimeUpdate
             )
{
  string attrList, from, where, c_where;
  string strMinPrio = valMinPrio;      
  int    count;
  string remote;
  string screenType;
  int    iNumberSystemSelections;
  int    iCountSystems;
  int    n;
  bool   bOnlyOwnSystem;
  int    iSystemId;
  int    noOfDpes;
  
  
  // Check redu-switch
  if (valTimeUpdate == g_timeLastUpdate) // No update when redu-switch
    return;
  else
    g_timeLastUpdate = valTimeUpdate;
 
// PW: 29.01.03 for SgAlertScreen 
	getValue("", "type", screenType); 
 	if (screenType != "SgAlertScreen"){
    	// see which configurations we have
  		std_startBusy();
  	}
  
  g_dpCommentFilter = valdpCommentFilter;
  g_maxLines = valMaxLines;
  g_state    = valState;
  iNumberSystemSelections = dynlen( valSystemSelections );
  
  if ( g_connectId != "" )
  { // Diconnect all selected systems
    for( n = 1; n <= dynlen( g_counterConnectId ); n ++ )
      dpQueryDisconnect( "as_alertsCB", g_connectId + "_" + g_counterConnectId[n] );
      
    g_connectId = "";
    dynClear( g_counterConnectId );
  }
   	setValue("", "deleteAllLines");
	setValue("", "stop", false);


// PW march 2003
// visible table makes some glitches
//	setValue("", "visible", false);
 
 // PW: 29.01.03 for SgAlertScreen 
 	if (screenType != "SgAlertScreen"){
  		setValue("configNames", "text", currentConfig);
        setValue("as_fieldValue", "text", "");
        setValue("state", "text", getCatStr("sc", "running"));
 
  // only if no special configuration is selected
  		setValue("props", "enabled", ( currentConfig == "" ));
	}
  // allow "set filter" button in openMode or closedMode
  		if ( (valType == 1) || (valType ==2) ){
    		setValue("", "tableMode", TABLE_SELECT_BROWSE);
			setValue("", "selectByClick", TABLE_SELECT_LINE);
// PW: 29.01.03 for SgAlertScreen 
 			if (screenType != "SgAlertScreen"){
				setValue("filter", "enabled", true);
				setValue("trend",  "enabled", true);
			}
 	 	}
  		else{
    		setValue("", "tableMode", TABLE_SELECT_NOTHING);
    		
// PW: 29.01.03 for SgAlertScreen 
 			if (screenType != "SgAlertScreen"){
      			setValue("filter", "enabled", false);
      			setValue("trend",  "enabled", false);
      		}		
  		}

  {  // correct begin/end-times
    time t;
    
    // end-time must be greater than begin-time
    if ( valBegin > valEnd ) { t = valBegin; valBegin = valEnd; valEnd = t; }
    if ( valEnd > getCurrentTime() ) valEnd = getCurrentTime();
  }

// PW: 29.01.03 for SgAlertScreen 
 	if (screenType != "SgAlertScreen"){
 		as_showProps(dpaState, dpaType,
              valState,
              valShortcut,
              valPrio,
              valdpCommentFilter,
              valAlertText,
              valDpList,
              valMinPrio,
             
              valSortList,
             
              valType,
              valBegin,
              valEnd,
              valChrono,
              valMaxLines,
              valSelection
             );
	}  
  // now connect/query for alerts

  attrList = as_getAttrList(valState);   // get list of visible attributes to query

  as_getFromWhere(from, where, valState, valShortcut, valPrio, valAlertText, valDpList, 
                  valTypeSelections, valTypeAlertSummary, valType);
  
  where = "('_alert_hdl.._prior' >= " + strMinPrio + ')' + where;
//DebugN(from, where);  
  // checking if number of dpes greater then g_asMaxDpeToDisplay

  if ( valType != 0 )   // open mode or current mode
  {
  as_getDpesOfFilter(from, true, noOfDpes);

  if (noOfDpes == -1 || noOfDpes > g_asMaxDpeToDisplay)
  {
    dyn_float  df;
    dyn_string ds;

    // Die aktuelle Anzahl der DPE konnte nicht festgestellt werden.
    // Es ist möglich, daß die Anzahl sehr groß ist, und damit die Abfrage lange dauert.
    // Wollen Sie die Abfrage starten?

// PW March 2004 
// No confirmation box for a query on all systems and for closed alarms
//    if (noOfDpes != -1)
//    { 
//        string sTemp = getCatStr("sc","toomuchalert1");
//        strreplace(sTemp, "§", noOfDpes);
//        strreplace(sTemp, "°", g_asMaxDpeToDisplay);
//
//        ChildPanelOnCentralModalReturn("vision/MessageWarning2",
//                   getCatStr("sc","Attention"),
//                   makeDynString(sTemp,
//                                 getCatStr("general","OK"),
//                                 getCatStr("sc","cancel")),
//                   df, ds );
//     }
//     else
//        ChildPanelOnCentralModalReturn("vision/MessageWarning2",
//                   getCatStr("sc","Attention"),
//                   makeDynString(getCatStr("sc","toomucharchivedalerts1"),
//                                 getCatStr("general","OK"),
//                                 getCatStr("sc","cancel")),
//                   df, ds );

// set the patient text with a new information

	setValue("PatientText" , "text", "This query might take a few seconds...");

// PW march 2004 force result to true like the ok from confirmation box
		df[1] = true;


    if (!df[1])
    {
// PW: 29.01.03 for SgAlertScreen 
   	 	if (screenType != "SgAlertScreen")
   	 	{
				std_stopBusy();
			}
      g_asDisplayDpes = 1; // do not display, return
      state.text = getCatStr("sc","cancelledtoomuch");
      setValue("", "deleteAllLines");
      setValue("", "visible",true);
      return;
    }
    else
    {
      g_asDisplayDpes  = 2; // do display
    }
  }
  }

  // now do a QUERY-CONNECT
 
  if (valType == 2)
  {
    string st1, st2;

    // restrict query using ack. time
    st1 = valBegin;   // convert time to string
    st2 = valEnd;     // convert time to string
    {
      time t = valEnd - valBegin;
      int  hours = period(t);
      
      hours /= AS_HIST_RANGE_SEC;
      if ( g_asDisplayHours != 2 && noOfDpes * hours > g_asMaxDpeHourToDisplay )
      {
        dyn_float  df;
        dyn_string ds;

      if (noOfDpes != -1)
      { 
        string sTemp = getCatStr("sc","toomuchalerthour2");
        strreplace(sTemp, "§", noOfDpes * hours);
        strreplace(sTemp, "°", g_asMaxDpeHourToDisplay);

        ChildPanelOnCentralModalReturn("vision/MessageWarning2",
                   getCatStr("sc","Attention"),
                   makeDynString(sTemp,
                                 getCatStr("general","OK"),
                                 getCatStr("sc","cancel")),
                   df, ds );
      }
      else
        ChildPanelOnCentralModalReturn("vision/MessageWarning2",
                   getCatStr("sc","Attention"),
                   makeDynString(getCatStr("sc","toomucharchivedalerts1"),
                                 getCatStr("general","OK"),
                                 getCatStr("sc","cancel")),
                   df, ds );

        if (!df[1])
        {
// PW: 29.01.03 for SgAlertScreen 
         	if (screenType != "SgAlertScreen"){
				std_stopBusy();
			}
          g_asDisplayHours = 1; // do not display, return
          state.text = getCatStr("sc","cancelledtoomuch");
          setValue("", "deleteAllLines");
          setValue("", "visible",true);
          return;
        }
        else
        {
          g_asDisplayHours = 2; // do display
          //g_asDisplayLines = 2; // do display
        }
      }
    }

    c_where = 
     + "('_alert_hdl.._ack_time' >= \"" + st1 + "\" AND '_alert_hdl.._ack_time' <= \"" + st2 + "\")";
    // DebugN("where: ", c_where);
  }
  else
    c_where = where;
  
  // connect for every selected system
  for( iCountSystems = 1; iCountSystems <= iNumberSystemSelections; iCountSystems ++ )
  {
    checkSystems( bOnlyOwnSystem );
    
    if( bOnlyOwnSystem )
    { // if there is only one system available
      iSystemId = getSystemId() + ":";
      if ( dpQueryConnectSingle("as_alertsCB", (valType == 0),  // only with currentMode we want an answer
             (valType == 0) ? "currentMode_" + iSystemId : ((valType == 1) ? "openMode_" + iSystemId : "closedMode_" + iSystemId),
             "SELECT ALERT " + attrList + " FROM " + from + " WHERE " + c_where) == -1 )
      {
// PW: 29.01.03 for SgAlertScreen 
			if (screenType != "SgAlertScreen"){
				std_stopBusy();
			}
        std_error("AS", ERR_SYSTEM, PRIO_SEVERE,
               E_AS_FUNCTION, "propertiesCB(): dpQueryConnectSingle(...)");
        return;
      }
      if ( dynlen(getLastError()) )
      {        dyn_errClass err = getLastError();
// PW: 29.01.03 for SgAlertScreen 
       	if (screenType != "SgAlertScreen"){
			std_stopBusy();
		}
        errorDialog(err);
        return;
      }
    }
    else
    { // if there are more than one systems available
      remote = valSystemSelections[iCountSystems];
      if( strpos( remote, ":" ) <= -1)
        remote += ":";
        
      iSystemId = getSystemId( remote );
      remote = "'" + remote + "'";
      
      if ( dpQueryConnectSingle("as_alertsCB", (valType == 0),  // only with currentMode we want an answer
             (valType == 0) ? "currentMode_" + iSystemId : ((valType == 1) ? "openMode_" + iSystemId : "closedMode_" + iSystemId),
             "SELECT ALERT " + attrList + " FROM " + from + " REMOTE " + remote + " WHERE " + c_where) == -1 )
      {
// PW: 29.01.03 for SgAlertScreen 
       	if (screenType != "SgAlertScreen"){
			std_stopBusy();
		}
        std_error("AS", ERR_SYSTEM, PRIO_SEVERE,
               E_AS_FUNCTION, "propertiesCB(): dpQueryConnectSingle(...)");
        return;
      }
      if ( dynlen(getLastError()) )
      {        dyn_errClass err = getLastError();
      // PW: 29.01.03 for SgAlertScreen 
       	if (screenType != "SgAlertScreen"){
			std_stopBusy();
        }
        as_checkQueryError( err, iSystemId );
        iSystemId = 0;
      }
    } // End system available
    // Setting id for connect
    if (iSystemId > 0)
      dynAppend( g_counterConnectId, iSystemId );
  } // End loop systems
  
// PW: 29.01.03
// If screen type = SgAlarmscreen   -> no "anhalten" object
if (screenType != "SgAlertScreen")
  {
  // set stop-button depending on Mode (closed mode => not visible)
  	if( valType == 2 )
    	setValue( "anhalten", "enabled", false );
  	else
    	setValue( "anhalten", "enabled", true );
  }
  
  g_connectId = "currentMode";
  
  if ( valType == 1 )  // open list
  {
    g_connectId = "openMode";
        
    setValue("", "visible", true);
// PW: 29.01.03 for SgAlertScreen 
  	if (screenType != "SgAlertScreen"){
	    std_stopBusy();
  	}
  }
  else if ( valType == 2 ) // closed list
  {
    dyn_dyn_anytype tab, tabAll;
    time t;
    unsigned action, lines;
    string fileName, dpProp = as_getPropDP(true);
    string st1, st2, select;
    

    g_connectId = "closedMode";

    dpGet(dpProp + "Action:_online.._value", action,
          dpProp + "FileName:_online.._value", fileName);
    
    dpSet(dpProp + "Cancel:_original.._value", false);  // for cancelling query-loop
// PW: 29.01.03 for SgAlertScreen 
	if (screenType != "SgAlertScreen"){
	    setValue("cancel", "enabled", true);
	}
    while ( valBegin < valEnd )
    {
      bool cancelled;

      if ( g_asDisplayHours < 2 || (valEnd - valBegin) < AS_HIST_RANGE_SEC )
        t = valEnd;
      else
        setPeriod(t, valBegin + AS_HIST_RANGE_SEC - 1, 999); // end with 999 mSecs of previous second

      st1 = valBegin;   // convert time to string
      st2 = t;          // convert time to string

          // PW: 29.01.03 for SgAlertScreen 
		if (screenType == "SgAlertScreen"){
			setValue("as_fieldValue", "text",
			formatTime("%H:%M:%S %d/%m/%y", valBegin) + "  -  " + formatTime("%H:%M:%S %d/%m/%y", t));
		}
		else{
	      	setValue("as_fieldValue", "text",
               formatTime("%c", valBegin) + "  -  " + formatTime("%c", t));
      	}
      
      // loop selected systems
      for( iCountSystems = 1; iCountSystems <= iNumberSystemSelections; iCountSystems ++ )
      {
        checkSystems( bOnlyOwnSystem );
      
        if( bOnlyOwnSystem )
        { // if there is only one system available
          select = "SELECT ALERT " + attrList + " FROM " + from + " WHERE " + where;
          if( dpQuery( select + " TIMERANGE(\"" + st1 + "\",\"" + st2 + "\",1,0)", tab ) == -1 )
          {
          // PW: 29.01.03 for SgAlertScreen 
			if (screenType != "SgAlertScreen"){
	            std_stopBusy();
    		}
            std_error("AS", ERR_SYSTEM, PRIO_SEVERE,
                      E_AS_FUNCTION, "propertiesCB(): dpQuery(...)");
            setValue("cancel", "enabled", false);
            return;
          }
          
          if ( dynlen(getLastError()) )
          {        dyn_errClass err = getLastError();
          // PW: 29.01.03 for SgAlertScreen 
			if (screenType != "SgAlertScreen"){
            	std_stopBusy();
            }
            errorDialog(err);
            setValue("cancel", "enabled", false);
            return;
          }
        }
        else
        { // if there are more than one systems available
          remote = valSystemSelections[iCountSystems];
          iSystemId = getSystemId( remote + ":" );
          
          
          // if there is asked a wrong system stop query. Message was still shown
          if( !dynContains( g_counterConnectId, iSystemId ) )
          {
            return;
          }
          
          
          if( strpos( remote, ":" ) <= -1)
            remote += ":";
          
          remote = "'" + remote + "'";
          
          select = "SELECT ALERT " + attrList + " FROM " + from + " REMOTE " + remote + " WHERE " + where;
          if( dpQuery( select + " TIMERANGE(\"" + st1 + "\",\"" + st2 + "\",1,0)", tab ) == -1 )
          {
          	// PW: 29.01.03 for SgAlertScreen 
			if (screenType != "SgAlertScreen"){
            	std_stopBusy();
            }
            std_error("AS", ERR_SYSTEM, PRIO_SEVERE,
                      E_AS_FUNCTION, "propertiesCB(): dpQuery(...)");
            setValue("cancel", "enabled", false);
            return;
          }
          
          if ( dynlen(getLastError()) )
          {        dyn_errClass err = getLastError();
          // PW: 29.01.03 for SgAlertScreen 
			if (screenType != "SgAlertScreen"){
	            std_stopBusy();
	        }
            as_checkQueryError( err, iSystemId ); // Show no error because it was shown at "dpQueryConnect"
            setValue("cancel", "enabled", false);
            return;
          }
        } // End system available
        
        lines += (dynlen( tab ) - 1);   // sum of all lines - 1 header line per query
        
        if (lines > g_asMaxLinesToDisplay)
        {
          dyn_float  df;
          dyn_string ds;

          if (g_asDisplayLines == 1) // do not display
          {
// PW: 29.01.03 for SgAlertScreen 
			if (screenType != "SgAlertScreen"){
	            std_stopBusy();
	        }
            state.text = getCatStr("sc","cancelledtoomuch");
            setValue("", "deleteAllLines");
            setValue("", "visible",true);
            return;
          }
          else
          if (g_asDisplayLines != 2)
          {

           if (noOfDpes != -1)
            { 
              string sTemp = getCatStr("sc","toomuchalert2");

              if ( noOfDpes >= g_maxClosedLines)  // too much lines -> show warning
              {

                sTemp = getCatStr("sc","toomuchAlertsCancel");
                strreplace(sTemp, "§", lines);
                strreplace(sTemp, "°", g_asMaxLinesToDisplay);
// PW: 29.01.03 for SgAlertScreen 
				if (screenType != "SgAlertScreen"){
                	std_stopBusy();
                }

                ChildPanelOnCentralModal("vision/MessageWarning", "", makeDynString(sTemp));
                setValue("cancel", "enabled", false);
                return;
              }

              strreplace(sTemp, "§", lines);
              strreplace(sTemp, "°", g_asMaxLinesToDisplay);

              ChildPanelOnCentralModalReturn("vision/MessageWarning2",
                         getCatStr("sc","Attention"),
                         makeDynString(sTemp,
                                       getCatStr("general","OK"),
                                       getCatStr("sc","cancel")),
                         df, ds );
            }
            else
            {
               string sTemp = getCatStr("sc","toomucharchivedalerts2");
               strreplace(sTemp, "§", g_asMaxLinesToDisplay);
               ChildPanelOnCentralModalReturn("vision/MessageWarning2",
                         getCatStr("sc","Attention"),
                         makeDynString(sTemp,
                                       getCatStr("general","OK"),
                                       getCatStr("sc","cancel")),
                         df, ds );
            }

             if (!df[1])
            {
            	// PW: 29.01.03 for SgAlertScreen 
			if (screenType != "SgAlertScreen"){
	              std_stopBusy();
	        }
              g_asDisplayLines = 1;
              state.text = getCatStr("sc","cancelledtoomuch");
              setValue("", "deleteAllLines");
              setValue("", "visible",true);
              return;
            }
            else g_asDisplayLines = 2; // do display
          }
        }
        if ( lines >= g_maxClosedLines)  // too much lines -> show warning
        {
          string msg;
          
          msg = getCatStr("sc", "maxLines");
          strreplace(msg, "§", "\n");
          // PW: 29.01.03 for SgAlertScreen 
			if (screenType != "SgAlertScreen"){
          		std_stopBusy();
			}
          ChildPanelOnCentralModal("vision/MessageWarning", "", makeDynString(msg));
          setValue("cancel", "enabled", false);
          return;
        }
        
        dpGet(dpProp + "Cancel:_online.._value", cancelled);  // did the user interrupt the query-loop
        
        if ( cancelled )
        {
        // PW: 29.01.03 for SgAlertScreen 
			if (screenType != "SgAlertScreen"){
	          	std_stopBusy();
	          }
          setMultiValue("cancel", "enabled", false,
                        "as_fieldValue", "text", "");
          return;
        }

        if ( valChrono && (action != 3) )
          as_alertsCB("closedModeAppend", tab);
        else
        {
          if ( dynlen(tabAll) > 0 ) dynRemove(tab, 1);  // delete header-line
          dynAppend(tabAll, tab);
        }
    
        valBegin = t + 0.001;  // add one milliSecond
      } // End loop systems
    } // End while
// PW: 29.01.03 for SgAlertScreen 
	if (screenType != "SgAlertScreen"){
    setValue("cancel", "enabled", false);
	}
    // resort the result to "left" after "entered" alert
    if ( ! valChrono && (action != 3) )
      as_alertsCB("closedModeAppend", as_resortTab(tabAll));

    setMultiValue("", "visible", true,
                  "as_fieldValue", "text", "");

    if ( action == 2 )
    {
      as_printTable();
      dpSet(dpProp + "Action:_original.._value", 0);  // do this only once
    }
    else if ( action == 3 )
    {
      dyn_dyn_anytype ret;
      dyn_dyn_anytype xtab = valChrono ? tabAll : as_resortTab(tabAll);

      //as_convertTab(ret, xtab, g_colVis, g_dpCommentFilter);
      convertAlertTab(xtab, g_colVis, g_dpCommentFilter, g_showInternals, ret);
      as_saveTable(fileName, ret);
      
      dpSet(dpProp + "Action:_original.._value", 0);  // do this only once
    }
    // PW: 29.01.03 for SgAlertScreen 
	if (screenType != "SgAlertScreen"){
    	std_stopBusy();
    }
  }
  // update linecount
  getValue("", "lineCount", count);
  if ( shapeExists("as_lineCount") ) setValue("as_lineCount", "text", count);
}

//--------------------------------------------------------------------------------------
/*
   print table
*/

as_printTable()
{
  dyn_string header, footer;
  string dpProp = as_getPropDP(true);
  string dummy;
  langString headerText;
  
  unsigned valState;
  string stateText;
  string valShortcut;
  string valPrio;
  string valDpComment;
  string valAlertText;
  dyn_string valDpList;
                          
  unsigned valType;
  time valBegin;
  time valEnd;
  
  dyn_int valTypeSelections;
  bool    valTypeAlertSummary;
  bool    bFirstType;
  int     i;
  string  valTypeFooter;
  
  dyn_string valSystemSelections;
  string     valSystemFooter;
  
  
  dpGet(dpProp + "Settings.Header:_online.._value",              headerText,
  
        dpProp + "Settings.Filter.State:_online.._value",        valState,
        dpProp + "Settings.Filter.Shortcut:_online.._value",     valShortcut,
        dpProp + "Settings.Filter.Prio:_online.._value",         valPrio,
        dpProp + "Settings.Filter.DpComment:_online.._value",    valDpComment,
        dpProp + "Settings.Filter.AlertText:_online.._value",    valAlertText,
        dpProp + "Settings.Filter.DpList:_online.._value",       valDpList,

        dpProp + "Settings.Timerange.Type:_online.._value",      valType,
        dpProp + "Settings.Timerange.Begin:_online.._value",     valBegin,
        dpProp + "Settings.Timerange.End:_online.._value",       valEnd,
        
        dpProp + "Settings.Type.Selections:_online.._value",     valTypeSelections,
        dpProp + "Settings.Type.AlertSummary:_online.._value",   valTypeAlertSummary,
        
        dpProp + "Settings.System.Selections:_online.._value",   valSystemSelections
       );
       
  // building footer for filterTypes and filterAlertSummary
  valTypeFooter = "";
  if( dynMax( valTypeSelections ) != 0 )
  {
    bFirstType = 0;
    for( i = 1; i <= dynlen( valTypeSelections ); i ++ )
    {
      if( valTypeSelections[i] == 0 )
      {
        if( bFirstType == 0 )
        {
          valTypeFooter += AS_TYPEFILTER[i];
          bFirstType = 1;
        }
        else
          valTypeFooter += " | " + AS_TYPEFILTER[i];
      }
    }
    if( !bFirstType )
    {
      valTypeFooter += getCatStr("sc", "notDisplay");
    }
  }
  
  // building footer for systems
  valSystemFooter = "";
  for( i = 1; i <= dynlen( valSystemSelections ); i ++ )
  {
    if( i != 1 )
      valSystemFooter += "  |  ";
    valSystemFooter += valSystemSelections[i];
  }
  
  
    switch ( valState )
    {
      case 0: stateText = getCatStr("sc", "all");       break;
      case 1: stateText = getCatStr("sc", "noack");     break;
      case 2: stateText = getCatStr("sc", "pending");   break;
      case 3: stateText = getCatStr("sc", "noackPend"); break;
      default:
        std_error("AS", ERR_PARAM, PRIO_WARNING, E_AS_DP_VAL, "");
        stateText = "????";
    }
  
  
  header[1] = "\\left{" + getCatStr("sc", "alerts") + "," + 
              ((headerText == "") ? "" : (headerText + ",")) + 
              formatTime("%c", getCurrentTime()) + "}\\center{" +
              // show timerange only in closed mode
              ((valType == 2) ? (formatTime("%c", valBegin) + " - " + formatTime("%c", valEnd)) : "") +
              "}\\right{\\page/\\numpages}";
  header[2] = "\\fill{_}";
  header[3] = "\\tablehead";
  header[4] = "\\fill{_}";

  footer[1] = "\\fill{_}";
  footer[2] = getCatStr("sc", "filter") + ":" + stateText + 
                ((valShortcut  == "") ? "" : ("|" + getCatStr("sc", "shortcut")     + valShortcut )) +
                ((valPrio      == "") ? "" : ("|" + getCatStr("sc", "prio")         + valPrio     )) +
                ((valDpComment == "") ? "" : ("|" + getCatStr("sc", "dpComment")    + valDpComment)) +
                ((valAlertText == "") ? "" : ("|" + getCatStr("sc", "alertText")    + valAlertText)) +
                ((valTypeFooter== "") ? "" : ("|" + getCatStr("sc", "types") + ": " + valTypeFooter)) +
                ((valTypeAlertSummary == 0) ? "" : ("|" + getCatStr("sc", "alert_summary"))) +
                ((valSystemFooter == "") ? "" : ("|" + getCatStr("sc", "systems") + ": " + valSystemFooter));

  if ( dynlen(valDpList) ) dynAppend(footer, getCatStr("sc", "dpList") + (dummy = valDpList));
  
  setValue("table", "printTable",
            header,
            makeDynString(),   // no special column attributes
            footer,
            _UNIX ? "AS_UNIX.cfg" : "AS_NT.cfg",  // config-file for Alert Screen
            PAPER_FORMAT_A4_COND,
            true,              // landscape ?
            false,             // all columns ?
            '|',               // delimiter
            0,                 // leftSpace 
            0);                // lineSpace
}

//--------------------------------------------------------------------------------------
/*
   print status table (modified as_printTable)
*/

as_printTableStatus()
{  
  dyn_string header, footer;
  string dpProp = as_getPropDP(true);
  
  string dummy;
  langString headerText;
  
  string stateText;
//  string valShortcut;
  string valPrio;
  string valDpComment;
  string valAlertText;
  dyn_string valDpList;
                          
  unsigned valType;
  time valBegin;
  time valEnd;
  
  dyn_int valTypeSelections;
  bool    valTypeAlertSummary;
  bool    bFirstType;
  int     i;
  string  valTypeFooter;
  
  dyn_string valSystemSelections;
  string     valSystemFooter;
  
  
  dpGet(dpProp + "Settings.Header:_online.._value",              headerText,
  
//        dpProp + "Settings.Filter.State:_online.._value",        valState,
//        dpProp + "Settings.Filter.Shortcut:_online.._value",     valShortcut,
        dpProp + "Settings.Filter.Prio:_online.._value",         valPrio,
        dpProp + "Settings.Filter.DpComment:_online.._value",    valDpComment,
        dpProp + "Settings.Filter.AlertText:_online.._value",    valAlertText,
        dpProp + "Settings.Filter.DpList:_online.._value",       valDpList,

        dpProp + "Settings.Timerange.Type:_online.._value",      valType,
        dpProp + "Settings.Timerange.Begin:_online.._value",     valBegin,
        dpProp + "Settings.Timerange.End:_online.._value",       valEnd,
        
        dpProp + "Settings.Type.Selections:_online.._value",     valTypeSelections,
        dpProp + "Settings.Type.AlertSummary:_online.._value",   valTypeAlertSummary,
        
        dpProp + "Settings.System.Selections:_online.._value",   valSystemSelections
       );
       
       
  // building footer for filterTypes and filterAlertSummary
  valTypeFooter = "";
  if( dynMax( valTypeSelections ) != 0 )
  {
    bFirstType = 0;
    for( i = 1; i <= dynlen( valTypeSelections ); i ++ )
    {
      if( valTypeSelections[i] == 0 )
      {
        if( bFirstType == 0 )
        {
          valTypeFooter += AS_TYPEFILTER[i];
          bFirstType = 1;
        }
        else
          valTypeFooter += " | " + AS_TYPEFILTER[i];
      }
    }
    if( !bFirstType )
    {
      valTypeFooter += getCatStr("sc", "notDisplay");
    }
  }
  
  // building footer for systems
  valSystemFooter = "";
  for( i = 1; i <= dynlen( valSystemSelections ); i ++ )
  {
    if( i != 1 )
      valSystemFooter += "  |  ";
    valSystemFooter += valSystemSelections[i];
  }
  
  
  header[1] = "\\left{" + getCatStr("sc", "statelisthead") + ", " + 
              formatTime("%c", getCurrentTime()) + 
              "}\\right{\\page/\\numpages}";
  header[2] = "\\fill{_}";
  header[3] = "\\tablehead";
  header[4] = "\\fill{_}";

  footer[1] = "\\fill{_}";
  footer[2] = getCatStr("sc", "filter") + ":" + stateText + 
                ((valPrio      == "") ? "" : ("|" + getCatStr("sc", "prio")      + valPrio     )) +
                ((valDpComment == "") ? "" : ("|" + getCatStr("sc", "dpComment") + valDpComment)) +
                ((valAlertText == "") ? "" : ("|" + getCatStr("sc", "alertText") + valAlertText)) +
                ((valTypeFooter== "") ? "" : ("|" + getCatStr("sc", "types") + ": " + valTypeFooter)) +
                ((valTypeAlertSummary == 0) ? "" : ("|" + getCatStr("sc", "alert_summary"))) +
                ((valSystemFooter == "") ? "" : ("|" + getCatStr("sc", "systems") + ": " + valSystemFooter));
                
   if ( dynlen(valDpList) ) dynAppend(footer, getCatStr("sc", "dpList") + (dummy = valDpList));

  setValue("table", "printTable",
            header,
            makeDynString(),   // no special column attributes
            footer,
            _UNIX ? "AS_UNIX.cfg" : "AS_NT.cfg",  // config-file for Alert Screen
            PAPER_FORMAT_A4_COND,
            true,              // landscape ?
            false,             // all columns ?
            '|',               // delimiter
            0,                 // leftSpace 
            0);                // lineSpace
}


//--------------------------------------------------------------------------------------
/*
   Save table into file (TAB separated)
Parameters:
  fileName ... target file (will be stored in DATA_PATH)
  tab      ... all entries
*/

as_saveTable(string fileName, dyn_dyn_anytype tab)
{
  file fd;
  int i, j;

  if ( fileName == "" )
  {
    std_error("AS", ERR_SYSTEM, PRIO_SEVERE,
              E_AS_DP_VAL, "as_saveTable(fileName)");
    return;
  }

  fd = fopen(DATA_PATH + fileName, "w");

  if ( fd == false ) return;

  for (i = 1; i <= dynlen(tab[1]); i++)     // order is [column][line]
  {
    for (j = 1; j <= dynlen(tab); j++)
      fprintf(fd, "%s\t", tab[j][i]);

    fprintf(fd, "\n");
  }

  fclose(fd);
}

//--------------------------------------------------------------------------------------
/*
issue SELECT statement
*/

as_propertiesRowCB(string dpaState, unsigned valState,
             string dpaShortcut, string valShortcut,
             string dpaPrio, string valPrio,
             string dpaDpComment, string valdpCommentFilter,
             string dpaAlertText, string valAlertText,
             string dpaDpList, dyn_string valDpList,
             string dpaMinPrio, unsigned valMinPrio,
             string dpaTypeSelections, dyn_int valTypeSelections,
             string dpaTypeAlertSummary, bool valTypeAlertSummary,
             string dpaSystemSelections, dyn_string valSystemSelections
            )
{
  string attrList, from, where;
  string strMinPrio = valMinPrio;
  string remote;
  int    iCountSystems;
  int    n;
  bool   bOnlyOwnSystem;
  int    iSystemId;
  
  
  g_dpCommentFilter = valdpCommentFilter;
  g_state = valState;
  
  
  setValue("", "deleteAllLines",
               "stop", false,
               "sort", "time");
  
  { // Diconnect all selected systems
    for( n = 1; n <= dynlen( g_counterConnectId ); n ++ )
      dpQueryDisconnect( "as_alertsCB", g_connectId + "_" + g_counterConnectId[n] );
    
    g_connectId = "";
    dynClear( g_counterConnectId );
  }
  
  
  // now connect/query for alerts
  attrList = as_getAttrList(valState);   // get list of visible attributes to query

  as_getFromWhere(from, where, valState, valShortcut, valPrio, valAlertText, valDpList,
                  valTypeSelections, valTypeAlertSummary, 0);

  where = "('_alert_hdl.._prior' >= " + strMinPrio + ')' + where;
  
  // connect for every selected system
  for( iCountSystems = 1; iCountSystems <= dynlen( valSystemSelections ); iCountSystems ++ )
  {
    checkSystems( bOnlyOwnSystem );
    
    if( bOnlyOwnSystem )
    { // if there is only one system available  
      // now do a QUERY-CONNECT
      iSystemId = getSystemId() + ":";
      if ( dpQueryConnectSingle("as_alertsCB", true,  // only with currentMode we want an answer
             "currentMode_" + iSystemId,
             "SELECT ALERT " + attrList + " FROM " + from + " WHERE " + where) == -1 )
      {
        std_error("AS", ERR_SYSTEM, PRIO_SEVERE,
                  E_AS_FUNCTION, "propertiesCB(): dpQueryConnectSingle(...)");
        return;
      }
    }
    else
    { // if there are more than one systems available
      remote = valSystemSelections[iCountSystems];
      iSystemId = getSystemId( remote + ":" );
      
      if( strpos( remote, ":" ) <= -1)
        remote += ":";
      remote = "'" + remote + "'";
      
      // now do a QUERY-CONNECT
      if ( dpQueryConnectSingle("as_alertsCB", true,  // only with currentMode we want an answer
             "currentMode_" + iSystemId,
             "SELECT ALERT " + attrList + " FROM " + from + " REMOTE " + remote + " WHERE " + where) == -1 )
      {
        std_error("AS", ERR_SYSTEM, PRIO_SEVERE,
                  E_AS_FUNCTION, "propertiesCB(): dpQueryConnectSingle(...)");
        return;
      }
      if ( dynlen(getLastError()) )
      {        dyn_errClass err = getLastError();
        as_checkQueryError( err, iSystemId );
        iSystemId = 0;
      }
    } // End system available
    // Setting id for connect
    if (iSystemId > 0)
      dynAppend( g_counterConnectId, iSystemId );
      
  } // End loop systems
  
  g_connectId = "currentMode";
}

//--------------------------------------------------------------------------------------
/*
Resort the given table so that the "left" alerts are directly after the "entered" alert
Parameters:
  tab (in) ... result of query (& only for performance, but tab is being changed!!)
Returns:
  resorted table
*/

dyn_dyn_anytype as_resortTab(dyn_dyn_anytype &tab)
{
  int i, j, retIdx = 1;
  dyn_dyn_anytype ret;
  time t;

  ret[retIdx++] = tab[1];   // we have to save the header

  for (i = 2; i <= dynlen(tab); i++)  // line 1 is header
    if ( (t = tab[i][2]) != 0 )   // not used before in this function
    {
      ret[retIdx++] = tab[i];

      if ( tab[i][9] )  // _direction column == entered
      {
        for (j = i+1; j <= dynlen(tab); j++)   // search partner ("left" alert)
        {
          if ( getAIdentifier(tab[j][2]) == getAIdentifier(tab[i][2]) )  // same dpid && same detail
          {
            ret[retIdx++] = tab[j];
            tab[j][2] = 0;  // set to "already used"
            break; 
          }
        }
      }
    }

  return ret;
}

//--------------------------------------------------------------------------------------
/*
Show Properties via shapes
*/

as_showProps(string dpaState, string dpaType,
             unsigned valState,
             string valShortcut,
             string valPrio,
             string dpCommentFilter,
             string valAlertText,
             dyn_string valDpList,
             unsigned valMinPrio,
             
             dyn_string valSortList,
             
             unsigned valType,
             time valBegin,
             time valEnd,
             bool valChrono,
             unsigned valMaxLines,
             unsigned valSelection
            )
{
  {
    // properties for filter
    
    string text, tyString, gName;
    
    switch ( valState )
    {
      case 0: text = getCatStr("sc", "all");       break;
      case 1: text = getCatStr("sc", "noack");     break;
      case 2: text = getCatStr("sc", "pending");   break;
      case 3: text = getCatStr("sc", "noackPend"); break;
      default:
        std_error("AS", ERR_PARAM, PRIO_WARNING, E_AS_DP_VAL, "propertiesCB():"+dpaState);
        text = "????";
    }
  
    setMultiValue("fi_alertState", "text",  text,
                  "fi_shortcut",   "text",  valShortcut,
                  "fi_prio",       "text",  valPrio,
                  "fi_dpComment",  "text",  dpCommentFilter,
                  "fi_alertText",  "text",  valAlertText); //,
//                  "fi_dpList",     "text",  (tyString = valDpList));
    tyString = valDpList;
                  
    if (dynlen(valDpList)==1 && strpos(valDpList[1],"group:::")==0)
    {
      gName=valDpList[1]; strreplace(gName,"group:::",getCatStr("groups","groupfilter")+" = ");
      fi_dpList.text=gName;
    }
    else
      fi_dpList.text=valDpList;
  } 

  {
    // properties for sorting
    
    int i;

    // do not sort the timeStr column, but sort the time column
    for (i = 1; i <= dynlen(valSortList); i++)
      if ( valSortList[i] == "timeStr" ) valSortList[i] = "time";   

    setValue("", "sortDyn", valSortList);
  }

  {
    // properties for timerange

    switch ( valType )
    {
      case 0:
      {
        setMultiValue("ti_type",      "text", getCatStr("sc", "current"),
                      "ti_begin",     "text", "",
                      "ti_end",       "text", "",
                      "ti_maxLines",  "text", "",
                      "ti_selection", "text", "");
        break;
      }
      
      case 1:
      {
        setMultiValue("ti_type",      "text", getCatStr("sc", "open"),
                      "ti_begin",     "text", "",
                      "ti_end",       "text", "",
                      "ti_maxLines",  "text", valMaxLines,
                      "ti_selection", "text", "");
        break;
      }

      case 2:
      {
        string selection;
        sprintf(selection, "select%d", valSelection-1);
        setMultiValue("ti_type",      "text", getCatStr("sc", "closed"),
                      "ti_begin",     "text", formatTime("%c", valBegin),
                      "ti_end",       "text", formatTime("%c", valEnd),
                      "ti_maxLines",  "text", "",
                      "ti_selection", "text", getCatStr("sc", selection));
        break;
      }
      
      default:
        std_error("AS", ERR_PARAM, PRIO_WARNING, E_AS_DP_VAL, "propertiesCB():"+dpaType);
    }
  } 
}

//-----------------------------------------------------------------------------
/*
Get list of alert-attributes which are always needed and
of the optional columns in the given table.
The returned string can be used to create a SELECT statement
Parameters:
  state ... filter for alert-state (0=all; 1=ackable; 2=pending; 3=1&&2)
Returns:
  list of attributes to query
*/

string as_getAttrList(unsigned state)
{
  int count, i;
  string list, name;
  bool vis;

  list = "'_alert_hdl.._alert_color',"
         "'_alert_hdl.._ack_state',"
         "'_alert_hdl.._visible',"
         "'_alert_hdl.._ackable',"
         "'_alert_hdl.._oldest_ack',"
         "'_alert_hdl.._ack_oblig',"
         "'_alert_hdl.._direction'";
  
  getValue("", "columnCount", count);
  
  for (i = 1; i <= count; i++)
  {
    getValue("", "columnVisibility", i - 1, g_colVis[i],
                 "columnToName", i - 1, name);

    if ( (name == "_partner") && (state >= 2) ) // for this state-filter, we need the _partner attribute
      g_colVis[i] = true;
    
    if ( g_colVis[i] && (name[0] == '_') )      // only these columns are alert_hdl attributes
      list += ",'_alert_hdl.." + name + "'";
  }
  
  return list;
}

//---------------------------------------------------------------------------
/*
   Get the name of the DP which has a specified configuration-name
Parameter:
  configName ... userd-defd name of configuration to be searched
Returns:
  Name of DP when configuration exists, else ""
*/

as_getConfigDP(string &dp, string configName)
{
  dyn_dyn_anytype tab;

  dp = "";

  // get DP of selected configuration
  dpQuery("SELECT '_online.._value' FROM '*.Name' WHERE _DPT = \"_ASConfig\" AND '_online.._value' == \"" + configName + "\"", tab);
      
  if ( dynlen(getLastError()) )
  {
    dyn_errClass err = getLastError();
    errorDialog(err);
    return;
  }

  if ( dynlen(tab) < 2 ) return;
    
  dp = dpSubStr(tab[2][1], DPSUB_DP) + '.';
}

//---------------------------------------------------------------------------
/*
Used in the AS_Properties panel for getting the selected properties
and setting them onto the _ASProp_? datapoint
Parameters:
  dpProp  ... name of DP on which to set the values (must be of DP-Type _ASConfig); with trailing "."
  configName ... user-defined name of configuration

  colNamesStr ... blank sep. list of internal column-names
  colTitlesStr ... blank sep. list of column titles in active language
  count ... number of columns
*/

as_setProps(string dpProp, string configName, string colNamesStr, string colTitlesStr, int count)
{
  int fiState, i, j, chars, chars1;
  string dpCheck, gName;
  string fiShortcut, fiPrio, fiDpComment, fiAlertText;
  dyn_string fiDpList, soList, sortList;
  dyn_string colNames, colTitles;
  
  int tiType, tiMaxLines;
  int tibYear, tibMonth, tibDay, tibHour, tibMinute, tibSecond;
  int tieYear, tieMonth, tieDay, tieHour, tieMinute, tieSecond;
  time tiBegin, tiEnd;
  bool tiChrono, tiChronoEnabled;
  int  tiSelection, tiShift;
  
  langString geHeader;
  string geOneHeader;
  
  int n;
  int fiTypeTable;
  dyn_int fiTypeSelections;
  bool fiAlertSummary,group;
  dyn_float  dfResult;
  dyn_string dsResult;
  string     msg;
  
  int        k;
  int        fiSystemTable;
  dyn_string fiSystemSelections;
  dyn_string fiAllSystemNames;
  dyn_string fiSelectedSystemNames;
  string     mySystemName;


  getMultiValue("fi_state",     "number", fiState,
                "fi_shortcut",  "text",   fiShortcut,
                "fi_prio",      "text",   fiPrio,
                "fi_dpComment", "text",   fiDpComment,
                "fi_alertText", "text",   fiAlertText,
                "fi_dpList",    "items",  fiDpList,

                "so_list",      "items", soList,
                
                "ti_type",      "number", tiType,
                "ti_maxLines",  "text",   tiMaxLines,
                "ti_chrono",    "state",  0, tiChrono,
                "ti_chrono",    "enabled",  tiChronoEnabled,
                "ti_selection", "selectedPos", tiSelection,
                "ti_shift",     "selectedPos", tiShift,

                "tib_year",     "text",   tibYear,
                "tib_month",    "text",   tibMonth,
                "tib_day",      "text",   tibDay,
                "tib_hour",     "text",   tibHour,
                "tib_minute",   "text",   tibMinute,
                "tib_second",   "text",   tibSecond,

                "tie_year",     "text",   tieYear,
                "tie_month",    "text",   tieMonth,
                "tie_day",      "text",   tieDay,
                "tie_hour",     "text",   tieHour,
                "tie_minute",   "text",   tieMinute,
                "tie_second",   "text",   tieSecond,
                
                "ge_header",    "text",   geOneHeader,
                "ge_headerList","text",   geHeader,
                
                "fi_typeTable", "lineCount", fiTypeTable,
                "fi_alertSummary", "state", 0, fiAlertSummary,
                
                "fi_systemTable", "lineCount", fiSystemTable,
                
                "dpe_group", "number", group,
                "fi_groups", "text", gName
                );
                
  if ( getNoOfLangs() == 1 ) geHeader = geOneHeader;
  
  if ( (! tiChronoEnabled) || tiChrono )    // if not chrono, leave sortList empty
  {
    // convert column-Titles back to the internal column names
    for (i = 1; i <= count; i++)
    {
      sscanf(substr(colNamesStr, chars), "%s", colNames[i]);
      chars += strlen(colNames[i]) + 1;
      
      sscanf(substr(colTitlesStr, chars1), "%s", colTitles[i]);
      chars1 += strlen(colTitles[i]) + 1;
    }
    for (i = 1; i <= dynlen(soList); i++)
    {  
      j = dynContains(colTitles, soList[i]);   // get the index
      dynAppend(sortList, colNames[j]);        // set internal column name
    }
  }
  
  // create begin and end time
  tiBegin = makeTime(tibYear, tibMonth, tibDay, tibHour, tibMinute, tibSecond);
  tiEnd   = makeTime(tieYear, tieMonth, tieDay, tieHour, tieMinute, tieSecond);

  as_getBeginEndTime(tiBegin, tiEnd, tiSelection, tiShift);  // correct timerange

  if ( tiType != 0 ) fiState = 0;  // in open or closed protocoll, we want all states

  // now set the selections              
  dpCheck = substr(dpProp, 0, strlen(dpProp) - 1);  // remove "."
  if ( ! dpExists(dpCheck) )
  {
    if ( dpCreate(dpCheck, "_ASConfig") == -1 )
    {
      std_error("AS", ERR_SYSTEM, PRIO_SEVERE,
                E_AS_FUNCTION, "as_setProps(): dpCreate(" + dpCheck + ",_ASConfig)");
      return;
    }
    if ( dynlen(getLastError()) )
    { dyn_errClass err = getLastError();
      errorDialog(err);
      return;
    }
  }
  
  
  // reading type table
  for( n = 1; n <= fiTypeTable; n ++ )
    getValue( "fi_typeTable", "cellValueRC", n-1, "Selections", fiTypeSelections[n] );
    
  if( dynMin( fiTypeSelections ) != 0 )
  {
    msg = getCatStr("sc","noTypes");
    strreplace(msg, "§", "\n");
    ChildPanelOnCentralModalReturn("vision/MessageWarning",getCatStr("sc","Attention"),
                                   makeDynString("$1:" + msg),
                                   dfResult, dsResult );
    // Get data from datapoint
    dpGet( dpProp + "Type.Selections:_original.._value", fiTypeSelections );
  }
  
  
  // reading system table
  fiSelectedSystemNames = "";
  k = 0;
  for( n = 1; n <= fiSystemTable; n ++ )
  {
    getValue( "fi_systemTable", "cellValueRC", n-1, "Names",      fiAllSystemNames[n],
                                "cellValueRC", n-1, "Selections", fiSystemSelections[n] );
    if( fiSystemSelections[n] == "1" )
    {
      k ++;
      fiSelectedSystemNames[k] = fiAllSystemNames[n];
    }
  }
  
  if( k == 0 ) // No system was selected
  {
    msg = getCatStr("sc","noSystems");
    strreplace(msg, "§", "\n");
    ChildPanelOnCentralModalReturn("vision/MessageWarning",getCatStr("sc","Attention"),
                                   makeDynString("$1:" + msg),
                                   dfResult, dsResult );
    // select own system
    mySystemName = substr( getSystemName(), 0, strpos( getSystemName(), ":" ) );
    fiSelectedSystemNames[1] = mySystemName;
  }
  
  
  // writing data
  if (group)
  {
    fiDpList=makeDynString("group:::"+gName);
  }
  dpSetWait(dpProp + "Name:_original.._value", configName,
            dpProp + "User:_original.._value", getUserId(),
            dpProp + "Header:_original.._value", geHeader,

            dpProp + "Filter.State:_original.._value", fiState,
            dpProp + "Filter.Shortcut:_original.._value", fiShortcut,
            dpProp + "Filter.Prio:_original.._value", fiPrio,
            dpProp + "Filter.DpComment:_original.._value", fiDpComment,
            dpProp + "Filter.AlertText:_original.._value", fiAlertText,
            dpProp + "Filter.DpList:_original.._value", fiDpList,

            dpProp + "Sorting.SortList:_original.._value", sortList,

            dpProp + "Timerange.Type:_original.._value", tiType,
            dpProp + "Timerange.MaxLines:_original.._value", tiMaxLines,
            dpProp + "Timerange.Chrono:_original.._value", tiChrono,
            dpProp + "Timerange.Selection:_original.._value", tiSelection,
            dpProp + "Timerange.Shift:_original.._value", tiShift,
            dpProp + "Timerange.Begin:_original.._value", tiBegin,
            dpProp + "Timerange.End:_original.._value", tiEnd,
            
            dpProp + "Type.Selections:_original.._value", fiTypeSelections,
            dpProp + "Type.AlertSummary:_original.._value", fiAlertSummary,
            
            dpProp + "System.Selections:_original.._value", fiSelectedSystemNames
            );
  
  if ( dynlen(getLastError()) )
  { dyn_errClass err = getLastError();
    errorDialog(err);
  }
}

//---------------------------------------------------------------------------
/*
Used in the AS_Properties panel for getting the selected properties from an _ASConfig DP
and setting them onto the shapes
Parameters:
  dpProp ... name of DP for properties (must be of DP-Type _ASConfig); with trailing "."
*/

as_getPropsFilter(string dpProp)
{
  int state,gState=0;
  string shortcut, prio, comment, alertText, gName="";
  dyn_string dpList, sections;

  dpGet(dpProp + "Filter.State:_online.._value", state,
        dpProp + "Filter.Shortcut:_online.._value", shortcut,
        dpProp + "Filter.Prio:_online.._value", prio,
        dpProp + "Filter.DpComment:_online.._value", comment,
        dpProp + "Filter.AlertText:_online.._value", alertText,
        dpProp + "Filter.DpList:_online.._value", dpList);

  fi_groups.items=groupGetNames();
  if (dynlen(dpList)==1 && strpos(dpList[1],"group:::")==0)
  {
    gName=dpList[1];
    strreplace(gName,"group:::","");
    asGetGroupFilter(dpList);
    dpselector.visible=false;
    append.visible=false;
    modify.visible=false;
    delete.visible=false;
    fi_dpName.visible=false;
    fi_groups.visible=true;
    fi_groups.text=gName;
    gState=1;
    dpListMatches.enabled = false;
  }
  else
  {
    dpselector.visible=true;
    append.visible=true;
    modify.visible=true;
    delete.visible=true;
    fi_dpName.visible=true;
    fi_groups.visible=false;
    dpListMatches.enabled = true;
  }

  setMultiValue("fi_state",      "number", state,
                "fi_shortcut",   "text",   shortcut,
                "fi_prio",       "text",   prio,
                "fi_dpComment",  "text",   comment,
                "fi_alertText",  "text",   alertText,
                "fi_dpList",     "items",  dpList,
                "dpe_group",     "number", gState);
}
asGetGroupFilter(dyn_string &dps)
{
  int        i, overflow;
  string     gName=dps[1];
  dyn_float  df;
  dyn_string dpcs=makeDynString(), ds, ds1, ds2,
             typeFilter=makeDynString(getCatStr("general","all")),
             dpeFilter=makeDynString("");
  
  strreplace(gName,"group:::","");
  groupGetFilterItemsRecursive(groupNameToDpName(gName),ds1,ds2,overflow);
  if (overflow==-1)
  {
    ChildPanelOnCentralModalReturn("vision/MessageWarning",
      getCatStr("para","warning"),
      makeDynString(getCatStr("groups","leveloverflow")),df,ds);
    return;
  }
  dps=makeDynString();
  dynAppend(typeFilter,ds1);
  dynAppend(dpeFilter,ds2);
  for (i=2;i<=dynlen(typeFilter);i++)
  {
    groupGetFilteredDps(typeFilter[i],dpeFilter[i],ds,overflow);
    if (overflow==-1)
    {
      ChildPanelOnCentralModalReturn("vision/MessageWarning",
        getCatStr("para","warning"),
        makeDynString(getCatStr("groups","leveloverflow")),df,ds);
      return;
    }
    dynAppend(dps,ds);
  }
  for (i=1;i<=dynlen(dps);i++) dps[i]=dpSubStr(dps[i],DPSUB_DP_EL);
}

//---------------------------------------------------------------------------
/*
Used in the AS_Properties panel for getting the selected properties from an _ASConfig DP
and setting them onto the shapes
Parameters:
  dpProp ... name of DP for properties (must be of DP-Type _ASConfig); with trailing "."
  strColTitles ... blank sep. list of table column-headers in current language
  strColNames ... blank sep. list of table column names (internal names)
  count ... number of columns
*/

as_getPropsSort(string dpProp, string strColTitles, string strColNames, int count)
{
  int i, chars, chars2;
  dyn_string colTitles, colNames;
  dyn_string soList, selected;
  string col;

  dpGet(dpProp + "Sorting.SortList:_online.._value", soList);

  // create dyn_string of column-names  
  chars = chars2 = 0;
  for (i = 1; i <= count; i++)
  {
    sscanf(substr(strColNames, chars), "%s", colNames[i]);
    chars += strlen(colNames[i]) + 1;
    
    sscanf(substr(strColTitles, chars2), "%s", colTitles[i]);
    chars2 += strlen(colTitles[i]) + 1;
  }

  // create dyn_string of column-titles which are selected for sorting
  for (i = 1; i <= dynlen(soList); i++)
  {
    int j = dynContains(colNames, soList[i]);
    dynAppend(selected, colTitles[j]);
    colTitles[j] = "";
  }
  
  // remove selected columns from list, so that we get the "rest"
  for (i = 1; i <= count; i++)
  {
    int j = dynContains(colTitles, "");
    dynRemove(colTitles, j);
  }

  setMultiValue("so_columns", "items", colTitles,
                "so_list",    "items", selected);
}

//---------------------------------------------------------------------------
/*
Used in the AS_Properties panel for getting the selected properties from an _ASConfig DP
and setting them onto the shapes
Parameters:
  dpProp ... name of DP for properties (must be of DP-Type _ASConfig); with trailing "."
  loadTi ... true=load start/stop time, false=don't
*/

as_getPropsTime(string dpProp, bool loadTi)
{
  int type, maxLines, selection, shift;
  bool chrono;
  time tib, tie;

  if ( dpGet(dpProp + "Timerange.Type:_online.._value", type,
             dpProp + "Timerange.MaxLines:_online.._value", maxLines,
             dpProp + "Timerange.Chrono:_online.._value", chrono,
             dpProp + "Timerange.Selection:_online.._value", selection,
             dpProp + "Timerange.Shift:_online.._value", shift,
             dpProp + "Timerange.Begin:_online.._value", tib,
             dpProp + "Timerange.End:_online.._value", tie
             ) == -1 )
  {
    std_error("AS", ERR_SYSTEM, PRIO_SEVERE,
               E_AS_FUNCTION, "as_getPropsTime(): dpGet( ... Timerange ...)");
    return;
  }
  if ( dynlen(getLastError()) )
  {
    dyn_errClass err = getLastError();
    errorDialog(err);
    return;
  }

  setMultiValue("ti_type",      "number", type,
                "ti_maxLines",  "text", maxLines,
                "ti_chrono",    "state", 0, chrono,
                "ti_selection", "selectedPos", selection,
                "ti_shift",     "selectedPos", shift);

  if ( loadTi )
    setMultiValue("tib_year",   "text", year(tib),
                  "tib_month",  "text", month(tib),
                  "tib_day",    "text", day(tib),
                  "tib_hour",   "text", hour(tib),
                  "tib_minute", "text", minute(tib),
                  "tib_second", "text", second(tib),

                  "tie_year",   "text", year(tie),
                  "tie_month",  "text", month(tie),
                  "tie_day",    "text", day(tie),
                  "tie_hour",   "text", hour(tie),
                  "tie_minute", "text", minute(tie),
                  "tie_second", "text", second(tie));

  as_setTiPropsEnabled(type); 
}


//--------------------------------------------------------------------------------
/*
Used in the AS_Properties panel for getting the selected properties from an _ASConfig DP
and setting them onto the shapes
Parameters:
  dpProp ... name of DP for properties (must be of DP-Type _ASConfig); with trailing "."
*/

as_getPropsGeneral(string dpProp)
{
  langString header;
  
  if ( dpGet(dpProp + "Header:_online.._value", header) == -1 )
  {
    std_error("AS", ERR_SYSTEM, PRIO_SEVERE,
               E_AS_FUNCTION, "as_getPropsGeneral(): dpGet( ... Header ...)");
    return;
  }
  
  // we need the ge_headerList for storing all languages, because
  // the textfield does not store a langString but only a string
  
  setMultiValue("ge_header",     "text", header,
                "ge_headerList", "text", header);
}

//--------------------------------------------------------------------------------
/*
Used in the AS_Properties panel for getting the selected properties from an _ASConfig DP
and setting them onto the shapes
Parameters:
  dpProp ... name of DP for properties (must be of DP-Type _ASConfig); with trailing "."
*/

as_getPropsFilterTypes(string dpProp)
{
dyn_string dsTypeNames;
dyn_int    diTypeSelections;
int        n;
string     sFarbe;
string     sState;

bool       bAlertSummary;


 
  if( dpGet( dpProp + "Type.Selections:_online.._value", diTypeSelections,
             dpProp + "Type.AlertSummary:_online.._value", bAlertSummary ) == -1 )
  {
    std_error("AS", ERR_SYSTEM, PRIO_SEVERE,
               E_AS_FUNCTION, "as_getPropsFilterTypes(): dpGet( ... FilterTypes ...)");
    return;
  }
  if ( dynlen(getLastError()) )
  {
    dyn_errClass err = getLastError();
    errorDialog(err);
    return;
  }
  
  
  // Preparing table and filling with data
  dsTypeNames = AS_TYPEFILTER;
  setValue( "fi_typeTable", "deleteAllLines" );
  setValue( "fi_typeTable", "appendLines", dynlen( dsTypeNames ), "Selections", diTypeSelections,
                                                                  "TypeNames", dsTypeNames );
  
  // sign the choosen Types
  for( n = 1; n <= dynlen( diTypeSelections ); n ++ )
  {
    if( !diTypeSelections[n] )
    {
      sFarbe = "_3DText";
      sState = getCatStr( "sc", "display" );
    }
    else
    {
      sFarbe = "darkgrey";
      sState = getCatStr( "sc", "notDisplay" );
    }
    setValue( "fi_typeTable", "cellValueRC", n -1, "State", sState,
                              "cellForeColRC", n -1, "State", sFarbe,
                              "cellForeColRC", n -1, "TypeNames", sFarbe,
                              "lineVisible", 0 );
  }
  
  // preparing checkbox "alert summary"
  setValue( "fi_alertSummary", "state", 0, bAlertSummary );
}

//--------------------------------------------------------------------------------
/*
Used in the AS_Properties panel for getting the selected properties from an _ASConfig DP
and setting them onto the shapes
Parameters:
  dpProp ... name of DP for properties (must be of DP-Type _ASConfig); with trailing "."
*/

as_getPropsFilterSystem(string dpProp)
{
dyn_uint   duAllSystemIds;
dyn_string dsAllSystemNames;
int        iCheckSystemNames;
dyn_string dsSelectedSystemNames;
int        n;
int        iSystemPos;
string     sState;
string     sSelection;
string     sColor;
string     mySystemName;

 
  // Read names of all systems
  iCheckSystemNames = getSystemNames( dsAllSystemNames, duAllSystemIds );
  if( iCheckSystemNames == -1 )
  {
    std_error("AS", ERR_SYSTEM, PRIO_SEVERE,
               E_AS_FUNCTION, "as_getPropsFilterTypes(): dpGet( ... FilterSystems ...)");
    return;
  }
  if ( dynlen(getLastError()) )
  {
    dyn_errClass err = getLastError();
    errorDialog(err);
    return;
  }
  
  // Preparing table and filling with data
  setValue( "fi_systemTable", "deleteAllLines" );
  setValue( "fi_systemTable", "appendLines", dynlen( dsAllSystemNames ), "Ids",   duAllSystemIds,
                                                                         "Names", dsAllSystemNames );
  
  // read selected system names
  if( dpGet( dpProp + "System.Selections:_online.._value", dsSelectedSystemNames ) == -1 )
  {
    std_error("AS", ERR_SYSTEM, PRIO_SEVERE,
               E_AS_FUNCTION, "as_getPropsFilterTypes(): dpGet( ... FilterSystems ...)");
    return;
  }
  if ( dynlen(getLastError()) )
  {
    dyn_errClass err = getLastError();
    errorDialog(err);
    return;
  }
  // find out the selected system names and sign the table
  for( n = 1; n <= dynlen( dsAllSystemNames ); n ++ )
  {
    iSystemPos = dynContains( dsSelectedSystemNames, dsAllSystemNames[n] );
    if( iSystemPos > 0 )
    {
      sState     = getCatStr( "sc", "display" );
      sSelection = "1";
      sColor     = "_3DText";
    }
    else
    {
      sState     = getCatStr( "sc", "notDisplay" );
      sSelection = "0";
      sColor     = "darkgrey";
    }
    setValue( "fi_systemTable", "cellValueRC",   n -1, "State",      sState,
                                "cellValueRC",   n -1, "Selections", sSelection,
                                "cellForeColRC", n -1, "Ids",        sColor,
                                "cellForeColRC", n -1, "Names",      sColor,
                                "cellForeColRC", n -1, "State",      sColor,
                                "lineVisible", 0 );
  }
  // Find out my system at the table and sign it
  mySystemName = substr( getSystemName(), 0, strpos( getSystemName(), ":" ) );
  iSystemPos = dynContains( dsAllSystemNames, mySystemName );
  
  setValue( "fi_systemTable", "cellBackColRC", iSystemPos -1, "Ids",   "grey",
                              "cellBackColRC", iSystemPos -1, "Names", "grey",
                              "cellBackColRC", iSystemPos -1, "State", "grey" );
                              
  // Sort table by system-id
  setValue( "fi_systemTable", "sort", "Ids" );
}

//--------------------------------------------------------------------------------
/*
Set the shapes of the timerange-tab to enabled/disabled depending on the current type
of protocoll
Also calculate the begin- and end-time on special time-selections (e.g. yesterday, ...)
Parameters:
  num ... 0=current alerts, 1=open protocoll, 2=closed protocoll
*/

as_setTiPropsEnabled(int num)
{
  if ( num == 1 )  // open
  {
    setMultiValue("ti_maxLines",    "enabled", true,
                  "ti_maxLinesTxt", "enabled", true,
                  "ti_maxLines",    "backCol", "_Window");
  }
  else
  {
    setMultiValue("ti_maxLines",    "enabled", false,
                  "ti_maxLinesTxt", "enabled", false,
                  "ti_maxLines",    "backCol", "_3DFace");
  }

  if ( num == 2 )  // closed
  {
    int pos, shift;

    getMultiValue("ti_selection", "selectedPos", pos,    // today, yesterday, ...
                  "ti_shift",     "selectedPos", shift);

    setMultiValue("ti_chrono",    "enabled", true,
                  "ti_selection", "enabled", true,

                  "ti_shift",   "enabled", (pos <= 3),  // today, yesterday, any day

                  "tib_year",   "enabled", (pos == 3) || (pos == 6),
                  "tib_month",  "enabled", (pos == 3) || (pos == 6),
                  "tib_day",    "enabled", (pos == 3) || (pos == 6),
                  "tib_hour",   "enabled", (pos == 6),
                  "tib_minute", "enabled", (pos == 6),
                  "tib_second", "enabled", (pos == 6),
                  "tib_today",  "enabled", (pos == 3) || (pos == 6),
                  
                  "tie_year",   "enabled", (pos == 6),
                  "tie_month",  "enabled", (pos == 6),
                  "tie_day",    "enabled", (pos == 6),
                  "tie_hour",   "enabled", (pos == 6),
                  "tie_minute", "enabled", (pos == 6),
                  "tie_second", "enabled", (pos == 6),
                  "tie_today",  "enabled", (pos == 6) 
                  );

    if ( pos != 6 )   // not any period
    {
      time tb, te;  // time-begin, time-end
      
      if ( pos == 3 )  // any day
      {
        int tibYear, tibMonth, tibDay, tibHour, tibMinute, tibSecond;
      
        getMultiValue("tib_year",     "text",   tibYear,
                      "tib_month",    "text",   tibMonth,
                      "tib_day",      "text",   tibDay,
                      "tib_hour",     "text",   tibHour,
                      "tib_minute",   "text",   tibMinute,
                      "tib_second",   "text",   tibSecond);

        tb = makeTime(tibYear, tibMonth, tibDay, tibHour, tibMinute, tibSecond);
      }

      as_getBeginEndTime(tb, te, pos, shift);

      setMultiValue("tib_year",   "text", year(tb),
                    "tib_month",  "text", month(tb),
                    "tib_day",    "text", day(tb),
                    "tib_hour",   "text", hour(tb),
                    "tib_minute", "text", minute(tb),
                    "tib_second", "text", second(tb),
                    
                    "tie_year",   "text", year(te),
                    "tie_month",  "text", month(te),
                    "tie_day",    "text", day(te),
                    "tie_hour",   "text", hour(te),
                    "tie_minute", "text", minute(te),
                    "tie_second", "text", second(te));
    }
  }
  else
  {
    setMultiValue("ti_chrono",   "enabled", false,
                  "ti_selection","enabled", false,
                  "ti_shift",    "enabled", false,

                  "tib_year",   "enabled", false,
                  "tib_month",  "enabled", false,
                  "tib_day",    "enabled", false,
                  "tib_hour",   "enabled", false,
                  "tib_minute", "enabled", false,
                  "tib_second", "enabled", false,
                  "tib_today",  "enabled", false,
                  
                  "tie_year",   "enabled", false,
                  "tie_month",  "enabled", false,
                  "tie_day",    "enabled", false,
                  "tie_hour",   "enabled", false,
                  "tie_minute", "enabled", false,
                  "tie_second", "enabled", false,
                  "tie_today",  "enabled", false 
                  );
  }
}

//--------------------------------------------------------------------------------
/*
   Correct begin and end-time depending on range selection (today, yesterday, ...)
   and shift-selection
Parameters:
  tb (in/out) ... begin time (in only for "any day", "any time")
  te (out) ... end time
  pos      ... selected range (1 = today, ...)
  shift    ... selected shift (1= whole day, 2..n shifts)
*/

as_getBeginEndTime(time &tb, time &te, int pos, int shift)
{
  int startHour;  // hour at which a working-day begins
  int numShifts;
  
  dpGet("_Config.StartHour:_online.._value", startHour,
        "_Config.NumShifts:_online.._value", numShifts);

  if ( (pos != 3) && (pos != 6) ) tb = getCurrentTime(); // on "any day", "any time", calculate from given begin-time
      
  switch ( pos )
  {
    case 1:  // today
    case 2:  // yesterday
    case 3:  // any day
    {
      // shift1 = whole day; shift2 .. shiftN real shifts

      int shiftLen;

      shiftLen = (numShifts > 1) ? (24 / numShifts) : 24;   // shift length in hours

      if ( hour(tb) < startHour ) tb -= 86400; // select correct day
      if ( pos == 2 ) tb -= 86400;  // subtract seconds of 1 day
      
      tb = makeTime(year(tb), month(tb), day(tb),
                    (shift <= 2) ? startHour : (startHour + ((shift - 2) * shiftLen)),
                    0, 0);

      if ( shift == 1 )   // whole day
        te = tb + 86400 - 1;    // one day
      else
        te = tb + shiftLen*3600 - 1;  // one shift

      break;
    }

    case 4:  // this week
    case 5:  // last week
    {
      int day = weekDay(tb);
      
      // select startHour of last monday
      tb = tb - daySecond(tb) - ((day-1)*86400) + (startHour*3600);

      if ( pos == 5 ) tb -= 7 * 86400;  // last week: substract seconds of 1 week 
      
      te = tb + 7*86400 - 1;
      break;
    }
    
    case 6: break;  // any timerange

    case 7:  // last 24 hours
    {
      te = tb;
      tb -= 86400;    // from now, 24 hours back

      break;
    }
    
    default: ;
  }
  
  setPeriod(tb, period(tb),   0);  // start at 0 milliSeconds 
  setPeriod(te, period(te), 999);  // end at 999 milliSeconds 
}

//--------------------------------------------------------------------------------
/*
Splits the comment-string into seperate comment-entries (seperated by §)
Parameter:
  comment ... string to split
Returns:
  dyn_string .. list of extracted comments
*/

dyn_string as_splitComment(string comment)
{
  return strsplit(comment, "§");
}

//--------------------------------------------------------------------------------
/*
Create FROM and WHERE clause for SELECT statement with the given filter-criteria
Parameters:
  from (out) ... from clause
  where (out) ... where clause (starts with "AND ")
  
  valState ... 0=all alerts; 1=ackable; 2=pending; 3= 1 && 2
  valShortcut ... shortcut filter
  valPrio     ... priority filter
  valAlertText ... alertText filter
  valDpList ... dp-List filter
  valTypeSelections ... const of filter of DPE-Types which are selected
  valTypeAlertSummary ... parameter if summary alert should be shown
  valType ... 0=current, 1=open, 2=closed
*/

as_getFromWhere(string &from, string &where,
                int valState, string valShortcut, string valPrio, string valAlertText,
                dyn_string valDpList, dyn_int valTypeSelections, bool valTypeAlertSummary,
                int valType, bool dpList = false)
{
int n;

 
  // create FROM clause
  from = "'*'";
  
  // check for dp filter
  if ( dynlen(valDpList) )
  {
    int i;
    
    // Check if dp group is selected
    if (dynlen(valDpList)==1 && strpos(valDpList[1],"group:::")==0)
    {
      strreplace( valDpList[1], "group:::", "" );
      valDpList[1] = groupNameToDpName( valDpList[1] );
      valDpList[1] = dpSubStr( valDpList[1], DPSUB_DP_EL );
      valDpList[1] = "DPGROUP(" + valDpList[1] + ")";
    }
    
    // Create from statement
    from = "'{";
    for (i = 1; i <= dynlen(valDpList); i++)
      from += ((i == 1) ? "" : ",") + valDpList[i];
    from += "}'";
  }
  
  
  // create WHERE clause
  where = "";
  
  // in current-mode we have to receive all alerts and filter them out when we receive them
  // because lines may have to be removed when the state (_ackable) changes
  if ( valType != 0 )
    switch ( valState )
    {
      case 0: break;  // no filter, we want all alerts
      case 1: where = "AND ('_alert_hdl.._ackable' == 1)"; break;
      case 2: where = "AND ('_alert_hdl.._partner' == 0)"; break;
      case 3: where = "AND ('_alert_hdl.._ackable' == 1) AND ('_alert_hdl.._partner' == 0)"; break;
    }

  if ( valShortcut  != "" ) where += "AND ('_alert_hdl.._abbr' LIKE \"" + valShortcut + "\")";
  if ( valPrio      != "" ) where += "AND ('_alert_hdl.._prior' IN RANGE(" + valPrio + "))";
  if ( valAlertText != "" ) where += "AND ('_alert_hdl.._text' LIKE \"" + valAlertText + "\")";
  
  // find out the selected types and add to "where"
  for( n = 1; n <= dynlen( valTypeSelections ); n ++ )
  {
    if( valTypeSelections[n] > 0 )
      where += "AND _ELC != \"" + valTypeSelections[n] + "\"";
  }
  
  // if alert summary is off do not ask for summary alerts
// TI 11444 display sum alerts always
  if( !dpList && !valTypeAlertSummary )
    where += "AND ('_alert_hdl.._sum' == 0)";

}

//--------------------------------------------------------------------------------
/*
   Start the function for the specific cell in the table
Parameters:
  row, col ... clicked cell
*/

as_cellAction(int row, string col)
{
  string screenType;
  
  if ( col == "ack" )
    as_ackAction(row);
  else if ( col == "_panel" )
    {
    as_panelAction(row);
    }
  else
  {
  if (( col == "ranges" ) || ( col == "priority" )) 
    {  
    as_panelActionRanges(row);
    }
    
  if ( shapeExists("as_fieldValue") )
    {
      string value;
      time timevalue;
  
      getValue("", "cellValue", value);
        
      if (col == "timeStr")   //show the milliseconds in the value-field
      {  
      	DebugN("row: " + row);
		DebugN("col: " + col);

     	getValue("","cellValueRC",row,"time", timevalue);
		
// PW:29.01.03 SgAlertScreen properties
// format the time HH:MM:SS dd:mm:yy
 		getValue("", "type", screenType);

		DebugN("timevalue : " + timevalue); 		
 		if(screenType == "SgAlertScreen"){
			value = formatTime("qq: %H:%M:%S %d/%m/%y" ,timevalue);
			DebugN("as.ctl/ as_cellAction: value done with : %H:%M:%S %d/%m/%y: " +  value);
		}
		else{
      		value = formatTime("%c", timevalue, " (%d)");
			DebugN("as.ctl/ as_cellAction: value done with : %c " +  value);
      	}
      }
      
      setValue("as_fieldValue", "text", value);
    }
  } 
}

//--------------------------------------------------------------------------------
/*
This function does the acknowledging of an alert
This function is called when the user clicks on the ack-cell in the table-shape
Modification: 1999-03-15 by Matthias Schagginger - If Timerange.Type is "2" 
(Closed Mode) the user can not acknowledge an alert !
*/

as_ackAction(int row)
{
  bool ackable, oldest;
  atime ti;
  int timerangetype, permission;
  string dpe, screenType, dpProp, dpASProp, alertclass;

  // check wheter we are in AlertScreen or in AlertRow
  getValue("", "type", screenType);
  
  // gives the correct name of the properties datapoint for the current alertscreen
  dpProp = as_getPropDP(screenType == "AlertScreen");
  dpASProp = substr(dpProp, 0, strlen(dpProp)-1);  // remove "."

  dpGet(dpASProp + ".Settings.Timerange.Type:_online.._value",timerangetype);
  
  if (timerangetype == 2)                     //closed mode - no acknowledging possible
     {                                        //open information panel
     ChildPanelOnCentralModal("vision/MessageWarning", "",makeDynString("$1:"+getCatStr("sc","no_ack")));
     return;
     }
  

  // if timerange mode is current or open proceed with normal ack-handling !
  getValue("", "cellValueRC", row, "dpid", dpe,
               "cellValueRC", row, "time", ti,
               "cellValueRC", row, "ackable", ackable,
               "cellValueRC", row, "oldest_ack", oldest);

// if userpermission lower than requested permission for specific alert: do not ack !

      dpGet(dpe+"._class",alertclass);
      dpGet(alertclass+":_alert_class.._perm",permission);

      if (!getUserPermission(permission))     
         {
         ChildPanelOnCentralModal("vision/MessageWarning",getCatStr("sc","attention"),makeDynString("$1:"+getCatStr("sc","no_ack_perm_1")
                           +getUserName()+getCatStr("sc","no_ack_perm_2")+"\n"+getCatStr("sc","no_ack_perm_3")));
         return;
         }
         
         
  if ( ! ackable ) return;

  if ( oldest )
  {
    if ( alertSet(ti, getACount(ti), dpSubStr(getAIdentifier(ti), DPSUB_SYS_DP_EL_CONF_DET) + "._ack_state",
                  DPATTR_ACKTYPE_SINGLE) == -1 )
    {
      std_error("AS", ERR_SYSTEM, PRIO_SEVERE,
                E_AS_FUNCTION, "ack:main(): alertSet(... _ack_state ...)");
      return;
    }

    if ( dynlen(getLastError()) )
    {        dyn_errClass err = getLastError();
      errorDialog(err);
      return;
    }
    setMultiValue("", "cellForeColRC", row, "ack", "_3DText",
                  "", "cellBackColRC", row, "ack", "_3DFace");
  }
  else
  {
    dyn_dyn_anytype tab;
    string s;
    int i, j;
    
    bool bOnlyOwnSystem;
    string remote;
    int iSystemId;
    
    checkSystems( bOnlyOwnSystem );
    if( bOnlyOwnSystem )
    { // if there is only one system available
      if ( dpQuery("SELECT ALERT '_alert_hdl.._abbr','_alert_hdl.._prior',"
                   "'_alert_hdl.._text','_alert_hdl.._direction' FROM '" + 
                   dpSubStr(getAIdentifier(ti), DPSUB_DP_EL) + "' WHERE ('_alert_hdl.._oldest_ack' == 1)", tab) == -1 )
      {
        std_error("AS", ERR_SYSTEM, PRIO_SEVERE,
                  E_AS_FUNCTION, "ack:main(): dpQuery(... _oldest_ack ...)");
        return;
      }
      
      if ( dynlen(getLastError()) )
      {        dyn_errClass err = getLastError();
        errorDialog(err);
        return;
      }
    }
    else
    { // if there are more systems available
      remote = dpSubStr( dpe, DPSUB_SYS );
      iSystemId = getSystemId( remote );
      
      if ( dpQuery("SELECT ALERT '_alert_hdl.._abbr','_alert_hdl.._prior',"
                   "'_alert_hdl.._text','_alert_hdl.._direction' FROM '" + 
                   dpSubStr(getAIdentifier(ti), DPSUB_DP_EL) + "' REMOTE '" + remote + "' WHERE ('_alert_hdl.._oldest_ack' == 1)", tab) == -1 )
      {
        std_error("AS", ERR_SYSTEM, PRIO_SEVERE,
                  E_AS_FUNCTION, "ack:main(): dpQuery(... _oldest_ack ...)");
        return;
      }
      
      if ( dynlen(getLastError()) )
      {        dyn_errClass err = getLastError();
        as_checkQueryError( err, iSystemId );
      }
    } // End systems available
    
    ChildPanelOnCentralModal("vision/SC/AS_ackOldest", "",
       makeDynString("$dpe:"   + dpSubStr(dpe, DPSUB_SYS_DP_EL),
                     "$dpd:"   + dpSubStr(getAIdentifier(tab[2][2]), DPSUB_SYS_DP_EL_CONF_DET), // dp up to detail
                     "$time:"  +      (s = tab[2][2]),   // convert time to string
                     "$count:" + getACount(tab[2][2]),
                     "$abbr:"  +           tab[2][3],
                     "$prior:" +      (j = tab[2][4]),
                     "$text:"  +           tab[2][5],
                     "$direction:" +       tab[2][6]));
  }
}

//--------------------------------------------------------------------------
/*
   This function is called when the user clicks on the comment-cell in the table-shape
*/

as_commentAction(int row, string panel)
{
  string comment, dpe, tim, count, ackable, oldest;  // string for automatic conversion
  atime ti;
        
  getValue("", "cellValueRC", row, "commentStr", comment,
               "cellValueRC", row, "time", ti,
               "cellValueRC", row, "ackable", ackable,
               "cellValueRC", row, "oldest_ack", oldest);

  // start child panel for comment input
  ChildPanelOnCentralModal("vision/SC/AS_comments", "",
       makeDynString("$comment:" + comment,
                     "$dpid:" + dpSubStr(getAIdentifier(ti), DPSUB_SYS_DP_EL_CONF_DET),
                     "$time:" + (tim = ti),
                     "$count:" + (count = getACount(ti)),
                     "$ackable:" + ackable,
                     "$oldest:" + oldest,
                     "$detailPanel:" + panel));
}

//--------------------------------------------------------------------------
/*
   This function is called when the user clicks on the panel-cell in the table shape
   Modified: 3.3.99 by Matthias Schagginger -> FileSelector will be displayed if 
   no panel is selected in _alert_hdl.._panel !
*/

// Modification on 21-AUG-2002 by Vincent Lambercy: Remove confirmation dialog box
as_panelAction(int row)
{
  string      panel, dpelement;
  dyn_float   confirmation;
  dyn_string  textresult;
  dyn_string  param;                   // Änderungen von Thomas Schirk 30.8.1999

  getValue("", "cellValueRC", row, "_panel", panel);

  if ( panel == "" ) 
  {
    panelSelector(panel);
    //DebugN(panel);
    if (panel != "")
    {
      getValue("", "cellValueRC", row, "dpElement",dpelement);
      // parametrisation on the _alert_hdl are only allowed when alerthandling 
      // and pending alerts are acknowledged
      
      dpSet(dpelement+":_alert_hdl.._active",0);
      delay(0,100);
      dpSet(dpelement+":_alert_hdl.._ack",2);
      delay(0,100);
      dpSet(dpelement+":_alert_hdl.._panel",panel);
      delay(0,100);
      dpSet(dpelement+":_alert_hdl.._active",1);
      delay(0,100);
      dpGet(dpelement+":_alert_hdl.._panel",panel);
      setValue("", "cellValueRC", row, "_panel", panel);
      
      // start child panel for confirmation
/*      ChildPanelOnCentralModalReturn ("vision/MessageInfo",getCatStr("sc","Attention"),
      makeDynString("$1:" + getCatStr("sc","shureOpenPanel") + "\n" +
                    panel,"$2:" + "OK","$3:"+getCatStr("sc","cancel")),
                    confirmation, textresult);

      if (confirmation[1] != 0.0)
      { */
      dpGet(dpelement+":_alert_hdl.._panel_param",param);  // Änderungen von Thomas Schirk 30.8.1999
      if (isModuleOpen("mainModule"))                      // TI 13215
        RootPanelOnModule(panel, "", "mainModule", param); // TI 13215
      else                                                 // TI 13215
        RootPanelOn(panel, "", param);                     // Änderungen von Thomas Schirk 30.8.1999
//      }  
    }
  }
  else
  {
    // start child panel for confirmation
/*    ChildPanelOnCentralModalReturn ("vision/MessageInfo",getCatStr("sc","Attention"),
    makeDynString("$1:" + getCatStr("sc","shureOpenPanel") + "\n" +
                  panel,"$2:" + "OK","$3:"+getCatStr("sc","cancel")),
                  confirmation, textresult);

    if (confirmation[1] != 0.0)
    { 
*/ 
      getValue("", "cellValueRC", row, "dpElement",dpelement);  // TI 3017 mhaslop
      dpGet(dpelement+":_alert_hdl.._panel_param",param);       // TI 3017 mhaslop
      if (isModuleOpen("mainModule"))                           // TI 13215
        RootPanelOnModule(panel, "", "mainModule", param);      // TI 13215
      else                                                      // TI 13215
        RootPanelOn(panel, "", param);                          // TI 3017 mhaslop
//    }  
  }
}

/*
   This function is called when the user clicks on the "ranges" or an "alert_class" cell in
   the table shape of AS_status.
*/

as_panelActionRanges(int row)
{
  string dpelement, alertclass, range, prio;

  getValue("", "cellValueRC", row, "alert_class", alertclass);
  getValue("", "cellValueRC", row, "ranges", range);
  getValue("", "cellValueRC", row, "priority", prio);
    //****> following to be removed !
    //Debug(row);Debug(alertclass);Debug(range);Debug(prio);DebugN("  in as_panelActionRanges !");      

  if (( range != "1" ) || (prio == "..."))
      {
      //*************************************************************************
      getValue("", "cellValueRC", row, "dpe",dpelement);
      //DebugN(dpelement);
      // start child panel detail-information
      ChildPanelOnCentralModal("vision/SC/AS_detail_ranges", "",
                           makeDynString("$DP:" + dpelement));
      //*************************************************************************
      }
}

//--------------------------------------------------------------------------
/*
   This function is called when the user clicks on the detail-cell in the table shape
*/

as_detailAction(int row, string panel)
{
  string dpid, tim, count, ackable;    // strings for automatic conversion to string
      
  getValue("", "cellValueRC", row, "dpid", dpid,
               "cellValueRC", row, "time", tim,
               "cellValueRC", row, "count", count);

  // start child panel for detail information
  ChildPanelOnCentralModal(panel, "",
                   makeDynString("$dpid:" + dpSubStr(dpid, DPSUB_SYS_DP_EL),
                                 "$time:" + tim,
                                 "$count:" + count));
}

//--------------------------------------------------------------------------
/*
   Add one commentline to the list of comments (only in the shapes)
   Used only in AS_comments panel
*/

as_addComment()
{
  string text, ti = getCurrentTime(), user;
        
  getValue("text", "text", text);
          
  if ( text != "" )
  {
    sprintf(user, "%10s|%s|", getUserName(), ti);
    setMultiValue("comments", "appendItem", user + text,
                  "text", "text", "");  // clear own text
  }
}

//--------------------------------------------------------------------------
/*
This function receives the result from the query and puts it into the table
It uses the global var g_dpCommentFilter
Parameters:
  ident ... Identification of query
  tab   ... result of query
*/

as_alertsCB(string ident, dyn_dyn_anytype tab)
{
  int             i, dummy, count, oldcount, pos, iPos, connectId;
  bool            stopped;
  time            tCurr;
  string          dpProp, sortString, screenType;
  dyn_string      sortList;
  dyn_errClass    err;
  dyn_dyn_anytype xtab;

// PW: 30.01.03
// get the screen Type value
	getValue("", "type", screenType);

  if ( g_discarded )
  {
    if ( ( (tCurr = getCurrentTime()) - g_discardStart) > MINCB_TIME )
    {
      string dpProp;
      dyn_string state;

      g_discarded = false;
      if ( g_discardThread >= 0 ) stopThread(g_discardThread);
      if ( shapeExists("as_fieldValue") )
      {
        setValue("as_fieldValue", "text", "",
                                  "backCol", "");
      }

      // dpSet für refresh
 
      // Checks if the Properties DP exists. If not, it creates it.
      dpProp = as_getPropDP((screenType == "AlertScreen")||(screenType == "SgAlertScreen"));

      dpGet(dpProp+"Settings.System.Selections", state);
      dpSet(dpProp+"Settings.System.Selections", state);
    }
    else
    {
      g_discardStart = tCurr;
    }
    return;
  }

  err = getLastError();
  if( dynlen( err ) > 0 )
  {
    if ( getErrorCode(err[1]) == 114 )  // values discarded
    {
      if ( ! g_discarded )
      {
        g_discarded = true;
        g_discardStart = getCurrentTime();
        g_discardThread = startThread("as_discardTimeOut");

        if ( shapeExists("as_fieldValue") )
          setValue("as_fieldValue", "backCol", "vorwKamGingUnq",
                                    "text", getCatStr("sc","discardingdisplay"));
        table.deleteAllLines();
      }
      return;
    }
    else
    {
      // connection lost
      // Find out connectId
      iPos = strpos( ident, "_" );
      connectId = substr( ident, iPos + 1 );
      
      as_checkQueryError( err, connectId );
    }
  }
  
  if (g_asDisplayLines != 2 && dynlen(tab) > g_asMaxLinesToDisplay)
  {
    dyn_float  df;
    dyn_string ds;

    if (g_asDisplayLines == 1) // do not display
    {
    // PW: 29.01.03 for SgAlertScreen 
		if (screenType != "SgAlertScreen"){
      		std_stopBusy();
      	}
      state.text = getCatStr("sc","cancelledtoomuch");
      setValue("", "deleteAllLines");
      setValue("", "visible",true);
      return;
    }
    else
    { 
              string sTemp = getCatStr("sc","toomuchalert2");
              strreplace(sTemp, "§", dynlen(tab));
              strreplace(sTemp, "°", g_asMaxLinesToDisplay);

              ChildPanelOnCentralModalReturn("vision/MessageWarning2",
                         getCatStr("sc","Attention"),
                         makeDynString(sTemp,
                                       getCatStr("general","OK"),
                                       getCatStr("sc","cancel")),
                         df, ds );
    }

  if (!df[1])
    {
    // PW: 29.01.03 for SgAlertScreen 
	if (screenType != "SgAlertScreen"){
      	std_stopBusy();
	}
      g_asDisplayLines = 1;
      state.text = getCatStr("sc","cancelledtoomuch");
      setValue("", "deleteAllLines");
      setValue("", "visible",true);
      return;
    }
    else g_asDisplayLines = 2;
  }
  // clear all "_" in identifier
  pos = strpos( ident, "_" );
  if( pos > - 1 )
    ident = substr( ident, 0, pos );
  
  
  getValue("", "stop", stopped,
               "lineCount", oldcount);

//DebugN("alertsCB - len:", dynlen(tab));

  convertAlertTab(tab, g_colVis, g_dpCommentFilter, g_showInternals, xtab);

//DebugN("alertsCB - xlen:", dynlen(xtab[1]));


  if ( dynlen(xtab[1]) != 0 )
  {
    if ( ident == "currentMode" )
      dummy = as_removeLines(xtab, oldcount); // used as a function to not interrupt it

    if ( ident == "closedModeAppend" )
      setValue("", "appendLines", dynlen(xtab[1]),
                                  "dpid",  xtab[24],
                                  "time",  xtab[ 2],
                                  "count", xtab[25], 
                                  
                                  "_abbr",      xtab[ 4],
                                  "_prior",     xtab[ 5],
                                  "timeStr",    xtab[ 6],
                                  "dpElement",  xtab[ 7],
                                  "dpComment",  xtab[ 8],
                                  "_text",      xtab[ 9],
                                  "direction",  xtab[10],
                                  "_value",     xtab[11],
                                  "ack",        xtab[12],
                                  "commentStr", xtab[13],
                                  
                                  "_ack_time",  xtab[14],
                                  "_partner",   xtab[15],
                                  "partner",    xtab[16],
                                  "_comment",   xtab[17],
                                  "_panel",     xtab[18],
                                  "detail",     xtab[19],
                                  "ackable",    xtab[20],
                                  "oldest_ack", xtab[21],
                                  "_ack_user",  xtab[22]
                                 );
    else
      setValue("", "updateLines", 3,
                                  "dpid",  xtab[24],
                                  "time",  xtab[ 2],
                                  "count", xtab[25], 
                                  
                                  "_abbr",      xtab[ 4],
                                  "_prior",     xtab[ 5],
                                  "timeStr",    xtab[ 6],
                                  "dpElement",  xtab[ 7],
                                  "dpComment",  xtab[ 8],
                                  "_text",      xtab[ 9],
                                  "direction",  xtab[10],
                                  "_value",     xtab[11],
                                  "ack",        xtab[12],
                                  "commentStr", xtab[13],
                                  
                                  "_ack_time",  xtab[14],
                                  "_partner",   xtab[15],
                                  "partner",    xtab[16],
                                  "_comment",   xtab[17],
                                  "_panel",     xtab[18],
                                  "detail",     xtab[19],
                                  "ackable",    xtab[20],
                                  "oldest_ack", xtab[21],
                                  "_ack_user",  xtab[22]
                                 );
    
  }
  
  if ( (ident == "openMode") && (! stopped) )
  {
    getValue("", "lineCount", count);
 
     if ( count > (g_maxLines + (g_maxLines/20)) )
    {
      setValue("", "sort", "time", "count");
      setValue("", "deleteLinesN", 0, count - g_maxLines,
                   "sortUndo", 0);
    }
  }
  
  if (ident == "closedModeAppend")
  {
    dpProp = as_getPropDP(true);
    dpGet(dpProp + "Settings.Sorting.SortList:_online.._value", sortList);
    
    if (dynlen(sortList) > 0)
    {
      // do not sort the timeStr column, but sort the time column
      for (i = 1; i <= dynlen(sortList); i++)
      {
        if ( sortList[i] == "timeStr" )
        {
          sortList[i] = "time";   
        }
      }
    setValue("", "sortDyn",sortList);  
    } 
  }
  
  
  // update linecount
  getValue("", "lineCount", count);
  if ( shapeExists("as_lineCount") ) setValue("as_lineCount", "text", count);
  
  if ( ident == "currentMode" )
  {
    // in currentMode, the current Line is always the new line (AlertRow)
    // 2006.07.29 aj added "|| (count == 0)" to avoid "***" after ACK ALL or restart
    if ( shapeExists("ar_currentLine") && ((count != oldcount) || (count == 0)) )
    {
      setMultiValue("ar_currentLine", "text", count,
                    "table", "lineVisible", -1);  // show last line
    }
    setValue("", "visible", true);
    // PW: 29.01.03 for SgAlertScreen 
	if (screenType != "SgAlertScreen"){
	    std_stopBusy();
	}
  }
}

//--------------------------------------------------------------------------
/*
 helper function for as_alertsCB
 this is a function, so that the CTRL can not interrupt it for better performance
  Parameters:
    xtab (in/out) ... already converted table of lines for the widget
    oldcount (in/out) ... old linecount of table
*/

void as_discardTimeOut()
{
  while (true)
  {
    if ( (getCurrentTime() - g_discardStart) > MAXCB_TIME )
    {
      string screenType, dpProp;
      dyn_string state;

      g_discarded = false;
      g_discardThread = -1;

      if ( shapeExists("as_fieldValue") )
      {
        setValue("as_fieldValue", "text", "",
                                  "backCol", "");
      }

      // dpSet für refresh
      getValue("", "type", screenType);
      // Checks if the Properties DP exists. If not, it creates it.
      dpProp = as_getPropDP(screenType == "AlertScreen");
      dpGet(dpProp+"Settings.System.Selections", state);
      dpSet(dpProp+"Settings.System.Selections", state);
      return;
    }
    delay(1);
  }
}

//--------------------------------------------------------------------------

int as_removeLines(dyn_dyn_anytype &xtab, int &oldcount)
{
  // because we can also remove lines, we have to loop through all lines
  unsigned line, col;
  time     tEmpty;
    
  // check if we have to remove a line, because its state changed to one,
  // which we do not want to see

  for (line = 1; line <= dynlen(xtab[1]); line++)
    if ( (! xtab[23][line]) ||    // _visible is false => remove line
         ((g_state == 1) && (xtab[20][line] != 1)) ||   // we want only ackables; this is not
         ((g_state == 2) && (xtab[16][line] != tEmpty)) ||   // we want only pendings; this is not
         ((g_state == 3) && ((xtab[20][line] != 1) || (xtab[16][line] != tEmpty))) )  // 1 && 2
    {
      setValue("", "deleteLine", 3, "dpid", getAIdentifier(xtab[2][line]),
                                    "time", xtab[2][line],
                                    "count", getACount(xtab[2][line]));  
      oldcount = -1;  // we want to see the last line in AlertRow
                      // (one line plus, one line minus makes the same count,
                      // but different content of table)

      // now delete line from xtab so that it will not be inserted in the table afterwards
      for (col = 1; col <= dynlen(xtab); col++) dynRemove(xtab[col], line);
      line--;   // !!! important: on the next loop, we must look at the same index, because we
                // removed the current index
    }

  return 0;
}

//--------------------------------------------------------------------------
/*
convert all entries in the tab, so that they can be displayed in the table-widget
Parameters:
  tab ... result of query
  colVis ... which of colAll columns are visible
Returns:
  dyn_dyn_anytype for table widget
*/

as_convertTab(dyn_dyn_anytype &ret, dyn_dyn_anytype &tab, dyn_bool colVis, string dpCommentFilter)
{
  int i, j, idx, retIdx = 1, lineIdx;
  
  string tyString;
  int tyInt;
  time tyTime;
  
  string bCol, fCol, ack;
  
  dyn_anytype line;
  
  for (i = 2; i <= dynlen(tab); i++)  // skip first line
  {
    if ( // check the dpComment filter
         ((dpCommentFilter != "") &&
         (! patternMatch(dpCommentFilter, dpGetComment(tab[i][1])))) ||
         (! g_showInternals && (dpSubStr(tab[i][1], DPSUB_DP)[0] == '_'))
       )
      continue;

    line[ 1] = tab[i][1];  // DP
    line[ 2] = tab[i][2];  // time
    line[ 3] = tab[i][3];  // _alert_color
                   // 4 ... _ack_state
                   // 5 ... _visible
                   // 6 ... _ackable
                   // 7 ... _oldest_ack
                   // 8 ... _ack_oblig
                   // 9 ... _direction

    idx = 10;  // start index of optional fields in current line of tab[i]

    line[ 4] = colVis[1] ? (tyString = tab[i][idx++]) : -1;   // _abbr
    line[ 5] = colVis[2] ? (tyInt    = tab[i][idx++]) : -1;   // _prior

//   PW:  30.01.03 modif SgAlertScreen
//OLD:    line[ 6] = colVis[3] ? formatTime("%c", tyTime = tab[i][2]): -1;   // timeStr
    line[ 6] = colVis[3] ? formatTime("%H:%M:%S %d/%m/%y", tyTime = tab[i][2]): -1;   // timeStr

    line[ 7] = dpSubStr(tab[i][1], DPSUB_DP_EL);              //dpElement

    line[ 8] = colVis[5] ? std_getDpName(tab[i][1]) : -1; // dpComment or dpElement

    line[ 9] = colVis[6] ? tab[i][idx++] : -1;  // _text

    line[10] = colVis[7] ? (tab[i][9] ? strEntered : strLeft) : -1;  // _direction
    line[11] = colVis[8] ? tab[i][idx++] : -1;  // _value

    if ( colVis[9] )
    {
      // generate content of ack column
      bCol = "_3DFace"; fCol = "_3DText";

      if ( tab[i][4] == DPATTR_ACKTYPE_SINGLE )  // _ack_state
        ack = "  x  ";
      else if ( tab[i][4] == DPATTR_ACKTYPE_MULTIPLE )  // _ack_state
        ack = " xxx ";
      else
      {
        if ( tab[i][6] )  // _ackable
        {
          if ( tab[i][7] ) // _oldest_ack
          {
            ack = " !!! ";
            bCol = "_Window"; fCol = "[80,0,0]";
          }
          else
          {
            ack = "  !  ";
            fCol = "[80,0,0]";
          }
        }
        else
          ack =  tab[i][8] ? " --- " : "";  // _ack_oblig
      }
    }

    line[12] = makeDynString(bCol, fCol, ack);  // ack and colors
    line[13] = "";  // set later

    if ( colVis[11] )  // _ack_time
    {
      if ( getType(tab[i][idx]) == ANYTYPE_VAR ) // undefined
        line[14] = "";
      else
        line[14] = tab[i][idx] ? formatTime("%c", tab[i][idx]) : "";

      idx++;
    }
    else
      line[14] = -1;

    if ( colVis[12] )  // _partner
    {
      line[15] = tab[i][idx] ? formatTime("%c", tab[i][idx]) : "";
      line[16] = tab[i][idx];
      idx++;
    }
    else
    {
      line[15] = -1;
      line[16] = -1;
    }

    // handle multi-comment entries
    if ( colVis[13] || colVis[10] )
    {
      if ( (getType(tab[i][idx]) == ANYTYPE_VAR) || (tab[i][idx] == "") )   // undefined or empty
        line[17] = "";
      else
        line[17] = dynlen(as_splitComment(tab[i][idx]));

      line[13] = (getType(tab[i][idx]) == ANYTYPE_VAR) ? "" : tab[i][idx];   // store full comment

      idx++;
    }
    else
      line[17] = -1;

    line[18] = colVis[14] ? tab[i][idx++] : -1;  // _panel
    line[19] = "...";  // detail child panel
    line[20] = tab[i][6];  // _ackable
    line[21] = tab[i][7];  // _oldest_ack

    if ( colVis[18] )  // _ack_user
    {
      if ( getType(tab[i][idx]) != ANYTYPE_VAR ) // undefined    
        line[22] = getUserName(tab[i][idx]);
      else
        line[22] = "";

      idx++;
    }
    else
      line[22] = -1;

    line[23] = tab[i][5];  // _visible

    ret[retIdx++] = line;
    
    dynClear(line);
  }
}

//--------------------------------------------------------------------------
/*
check if there is only one systeme available. If so this must be the own system
Returns:
  bOnlyOwnSystem ... 1: Only this system
                     0: More than this system
*/

checkSystems( bool &bOnlyOwnSystem )
{
int        errorFlag;
dyn_string names;
dyn_uint   ids;
string screenType;

 
  // Getting all systems
  errorFlag = getSystemNames( names, ids );

// Get the screentype
	getValue("", "type", screenType);
  
  if( errorFlag == - 1 )
  {
   // PW: 29.01.03 for SgAlertScreen 
	if (screenType != "SgAlertScreen"){
    	std_stopBusy();
    }
    std_error("AS", ERR_SYSTEM, PRIO_SEVERE,
      E_AS_FUNCTION, "checkSystems(): getSystemNames(...)");
      return;
  }
  if ( dynlen(getLastError()) )
  {        dyn_errClass err = getLastError();
     // PW: 29.01.03 for SgAlertScreen 
	if (screenType != "SgAlertScreen"){
    	std_stopBusy();
    }
      errorDialog(err);
      return;
  }
  
  // If there is only one system available it must be this system
  if( dynlen( names ) == 1 )
    bOnlyOwnSystem = true;
  else
    bOnlyOwnSystem = false;
}

//--------------------------------------------------------------------------
/*
The cancel-dp takes two functions:
For a closed protocol the user can stop query by pushing "cancel"-button.
For other protocols this bit is high, when user pushes "stop"-button with the
option "with disconnect".

Parameters:
  bCancel ... value from cancel-datapoint
*/

as_cancel( string dpCancel, bool bCancel )
{
int n;

 
  if( ( g_connectId == "currentMode" || g_connectId == "openMode" ) && bCancel )
  { // Diconnect all selected systems
    for( n = 1; n <= dynlen( g_counterConnectId ); n ++ )
      dpQueryDisconnect( "as_alertsCB", g_connectId + "_" + g_counterConnectId[n] );
    
    g_connectId = "";
    dynClear( g_counterConnectId );
  }
}

//--------------------------------------------------------------------------
/*
CheckError when query is not successful and delete the connect-Id
*/

as_checkQueryError( dyn_errClass err, int iSystemId )
{
int        iPos;
int        errCode;
string     msg;
string     sSystemName;

 
  if( dynlen( err ) > 0 )
  { // Find out type of error
    errCode = getErrorCode( err[1] );
    
    sSystemName = getSystemName( iSystemId );
    sSystemName = strrtrim( sSystemName, ":" );
    
    if( errCode == 110 )
    {
      if ( !shapeExists("ar_currentLine") ) // If there is a row, show no error because of autom. reconnect
      {
        msg = getCatStr("sc","reduSwitched");
        strreplace(msg, "§", "\n");
        ChildPanelOnCentral("vision/MessageWarning",
                            getCatStr("sc","Attention") + "_" + sSystemName,
                            makeDynString("$1:" + msg + sSystemName + " (" + iSystemId + ")" )
                           );
      }
    }
    else if( errCode == 111 )
    {
      msg = getCatStr("sc","reduConnectionLost");
      strreplace(msg, "§", "\n");
      ChildPanelOnCentral("vision/MessageWarning",
                          getCatStr("sc","Attention") + "_" + sSystemName,
                          makeDynString("$1:" + msg + sSystemName + " (" + iSystemId + ")" )
                         );
    }
    else
    {
      // 13.02.2014 yca use message
      msg = getCatStr("sc","distConnectionLost");
      strreplace(msg, "§", "\n");
      DebugTN(msg);
			//01.04.2005 aj avoid popup window when connection to a distributed system is lost
			/*
      ChildPanelOnCentral("vision/MessageWarning",
                          getCatStr("sc","Attention") + "_" + sSystemName,
                          makeDynString("$1:" + msg + sSystemName + " (" + iSystemId + ")" )
                         );
			*/                         
    }
    throwError( err ); // Write error to stderr
  }
  
  // Delete connect-Id
  iPos = dynContains( g_counterConnectId, iSystemId );
  if( iPos > 0 )
    dynRemove( g_counterConnectId, iPos );
}

//--------------------------------------------------------------------------
/*
Saving the table to a file
*/
as_tableToFile()
{
int        iCount;
string     sFile;
dyn_string dsFileNames;
dyn_float  dfAnswer;
dyn_string dsAnswer;

string     sData;
string     dpProp;
string     dummy;
langString headerText;

unsigned   valState;
string     stateText;
string     valShortcut;
string     valPrio;
string     valDpComment;
string     valAlertText;
dyn_string valDpList;
                        
unsigned   valType;
time       valBegin;
time       valEnd;

dyn_int    valTypeSelections;
bool       valTypeAlertSummary;
bool       bFirstType;
int        i;
string     valTypeFooter;
dyn_string valSystemSelections;
string     valSystemFooter;
string     valDpListFooter;

int        err;
file       fFile;


  getValue( "table", "lineCount", iCount );
  if( iCount <= 0 )
  {
    // No data available
    ChildPanelOnCentralModalReturn( "vision/MessageInfo",
                                    getCatStr( "general", "information" ),
                                    makeDynString( getCatStr( "sc", "noData" ),
                                                   getCatStr( "sc", "yes" ),
                                                   getCatStr( "sc", "no" )),
                                    dfAnswer, dsAnswer );
    if( dfAnswer[1] == 0 )
      return;
  }
  
  // Select file
  fileSelector( sFile, getPath( DPLIST_REL_PATH ), false );
  if( strlen( sFile ) == 0 )
    return;
  else
  {
    // Check if file still exists
    dsFileNames = getFileNames( sFile, "*" );
    if( dynlen( dsFileNames ) > 0 )
    {
      // File exists. Ask to overwrite
      ChildPanelOnCentralModalReturn( "vision/MessageInfo",
                                      getCatStr( "general", "information" ),
                                      makeDynString( getCatStr( "sc", "overwrite" ),
                                                     getCatStr( "sc", "yes" ),
                                                     getCatStr( "sc", "no" )),
                                      dfAnswer, dsAnswer );
      if( dfAnswer[1] == 1 )
      {
        // Overwrite file
        setValue( "table", "writeToFile", sFile, false, "\t" );
      }
    }
    else
    {
      // File does not exist
      setValue( "table", "writeToFile", sFile, false, "\t" );
    }
  }
  
  
  //Writing Footer
  dpProp = as_getPropDP("AlertScreen");
  
  dpGet(dpProp + "Settings.Header:_online.._value",              headerText,
  
        dpProp + "Settings.Filter.State:_online.._value",        valState,
        dpProp + "Settings.Filter.Shortcut:_online.._value",     valShortcut,
        dpProp + "Settings.Filter.Prio:_online.._value",         valPrio,
        dpProp + "Settings.Filter.DpComment:_online.._value",    valDpComment,
        dpProp + "Settings.Filter.AlertText:_online.._value",    valAlertText,
        dpProp + "Settings.Filter.DpList:_online.._value",       valDpList,

        dpProp + "Settings.Timerange.Type:_online.._value",      valType,
        dpProp + "Settings.Timerange.Begin:_online.._value",     valBegin,
        dpProp + "Settings.Timerange.End:_online.._value",       valEnd,
        
        dpProp + "Settings.Type.Selections:_online.._value",     valTypeSelections,
        dpProp + "Settings.Type.AlertSummary:_online.._value",   valTypeAlertSummary,
        
        dpProp + "Settings.System.Selections:_online.._value",   valSystemSelections
       );


  // Building footer for filterTypes and filterAlertSummary
  valTypeFooter = "";
  if( dynMax( valTypeSelections ) != 0 )
  {
    bFirstType = 0;
    for( i = 1; i <= dynlen( valTypeSelections ); i ++ )
    {
      if( valTypeSelections[i] == 0 )
      {
        if( bFirstType == 0 )
        {
          valTypeFooter += AS_TYPEFILTER[i];
          bFirstType = 1;
        }
        else
          valTypeFooter += ", " + AS_TYPEFILTER[i];
      }
    }
    if( !bFirstType )
    {
      valTypeFooter += getCatStr("sc", "notDisplay");
    }
  }
  
  // Building footer for systems
  valSystemFooter = "";
  for( i = 1; i <= dynlen( valSystemSelections ); i ++ )
  {
    if( i != 1 )
      valSystemFooter += ", ";
    valSystemFooter += valSystemSelections[i];
  }
  
  // Building footer for DP's
  valDpListFooter = "";
  for( i = 1; i <= dynlen( valDpList ); i ++ )
  {
    if( i != 1 )
      valDpListFooter += ", ";
    valDpListFooter += valDpList[i];
  }
  
  switch ( valState )
  {
    case 0: stateText = getCatStr("sc", "all");       break;
    case 1: stateText = getCatStr("sc", "noack");     break;
    case 2: stateText = getCatStr("sc", "pending");   break;
    case 3: stateText = getCatStr("sc", "noackPend"); break;
    default:
      std_error("AS", ERR_PARAM, PRIO_WARNING, E_AS_DP_VAL, "");
      stateText = "????";
  }
  
  sData = "\n" +
          getCatStr( "sc", "alerts" ) + ", " + ((headerText == "") ? "" : (headerText + ",")) + 
          formatTime("%c", getCurrentTime()) + "\n" +
          formatTime("%c", valBegin) + " - " + formatTime("%c", valEnd) + "\n" +
          getCatStr("sc", "filter") + ":\n" + stateText + 
          ((valShortcut  == "") ? "" : ("\n" + getCatStr("sc", "shortcut")     + valShortcut )) +
          ((valPrio      == "") ? "" : ("\n" + getCatStr("sc", "prio")         + valPrio     )) +
          ((valDpComment == "") ? "" : ("\n" + getCatStr("sc", "dpComment")    + valDpComment)) +
          ((valAlertText == "") ? "" : ("\n" + getCatStr("sc", "alertText")    + valAlertText)) +
          ((valTypeFooter== "") ? "" : ("\n" + getCatStr("sc", "types") + ": " + valTypeFooter)) +
          ((valTypeAlertSummary == 0) ? "" : ("\n" + getCatStr("sc", "alert_summary"))) +
          ((valSystemFooter == "") ? "" : ("\n" + getCatStr("sc", "systems") + ": " + valSystemFooter)) +
          ((valDpList == "") ? "" : ("\n" + getCatStr("sc", "dpList") + " " + valDpListFooter));


  // Write data to file
  err = 0;
  fFile = fopen( sFile, "a" );
  err = ferror( fFile );

 if( err == 0 )
    fputs( sData, fFile );
  else
   ChildPanelOnCentralModal( "vision/MessageInfo1",
                              getCatStr( "general", "information"),
                              makeDynString( getCatStr( "ac", "notSaved" )));
  fclose( fFile );
}
as_getDpesOfFilter(string from, bool as, int &noOfDps)
{
  int        i, j, overflow;
  string     select, dpeT;
  dyn_string ds, ds1, ds2, dss, dps,
             typeFilter=makeDynString(""),
             dpeFilter=makeDynString(""),
             tdFilter=makeDynString("");
  // do not query if one of the filters is equal to one of the following patterns
  dyn_string badFilter = makeDynString( "**","*.**","*.*.**","*.*.*.**");
  dyn_dyn_anytype tab;

  noOfDps = 0;

//  DebugN(getCurrentTime(), "START Überwachung", from);

// the dpNames solution
  if (strpos(from,"{DPGROUP(") > 0)
  {
    string gName = substr(from,strpos(from,"{DPGROUP(")+9,
                               strpos(from,")}")-(strpos(from,"{DPGROUP(")+9));
    groupGetFilterItemsRecursive(gName,ds1,ds2,overflow);
    if (overflow==-1 || overflow>20)
    {
      groupErrorScreen(-11);
      return;
    }
    dynAppend(typeFilter,ds1);
    dynAppend(dpeFilter,ds2);

    for (i=1;i<=dynlen(typeFilter);i++)
    {
      groupGetFilteredDps(typeFilter[i],dpeFilter[i],ds,overflow);
      if (overflow==-1)
      {
        groupErrorScreen(-11);
        return;
      }
      dynAppend(dps,ds);
    }

  }
  else
  {
    if ( from == "'*'" )
    {
      noOfDps = -1;
      return;
    }
    else
    {
      string filter;

      filter = substr(from,strpos(from,"{")+1,
                           strpos(from,"}")-(strpos(from,"{")+1));
      ds = strsplit(filter,",");
      for (i = 1; i <= dynlen(ds); i++)
      {
        // system name and config in filter are not needed, only dp(e)-filter
        dss=strsplit(ds[i], ":");
        for ( j = 1; j <= dynlen(dss); j++)
        {
          if ( dynContains(badFilter,dss[j]) > 0 )
          {
            noOfDps = -1;
            return;
          }
        }
        ds1 = dpNames(ds[i]);
        dynAppend(dps,ds1);
      }
    }
  }

  dynSortAsc(dps);
  dynUnique(dps);

  noOfDps = dynlen(dps);
  
  //DebugN("Mengenoptimierung: ALERTSCREEN="+as,"Elemente: "+dynlen(dps),getCurrentTime());

}
