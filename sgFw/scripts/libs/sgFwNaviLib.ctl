global dyn_string naviHistoryPanels;
global dyn_dyn_string naviHistoryParams;
global int naviIndex;

void sgFwInitNaviPanel(string rootPanelName, dyn_string rootPanelParams)
{
	naviHistoryPanels = makeDynString(rootPanelName);
	naviHistoryParams[1] = rootPanelParams;
	naviIndex = 1;

//	DebugN("sgFwLib.ctl : naviHistoryPanels[1] :" + naviHistoryPanels[1]);
//	DebugN("sgFwLib.ctl : naviHistoryParams[1] :" + naviHistoryParams[1]);
//	DebugN("sgFwLib.ctl : After naviHistoryParams:");

}

void sgFwNaviPanelOn()
{
//	setTrace(EXECUTION_TRACE);


	string currentPanel = naviHistoryPanels[naviIndex];
	dyn_string currentParams = naviHistoryParams[naviIndex];
	// Th.V logg event on system queue
	string client;
	client = getHostname();
//	sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "HMI >> client: " + client + ", new panel: " + currentPanel + ", parameters: " + currentParams);
	RootPanelOnModule(currentPanel, "", "mainModule", currentParams);
	enableDisableBckFwdButtons();
}

void sgFwSetNaviParams(string panelFileName, dyn_string panelParams)
{
// setTrace(EXECUTION_TRACE);

//	DebugN("sgFwNaviLib: panelFileName:" + panelFileName);
//	DebugN("sgFwNaviLib : panelParams:" + panelParams);

	if(panelFileName == naviHistoryPanels[naviIndex] && panelParams == naviHistoryParams[naviIndex])
	{
		return;
	}

// if new panel, erase the next values
	for(int i = dynlen(naviHistoryPanels); i >= naviIndex + 1; i--)
	{
		dynRemove(naviHistoryPanels, i);
		dynRemove(naviHistoryParams, i);
	}

// increase index for the navigation
	naviIndex++;
// update tables
	naviHistoryPanels[naviIndex] = panelFileName;
	naviHistoryParams[naviIndex] = panelParams;
	//history queue as maximum 10 positions, if > we remove the first position
	if(naviIndex > 10 )
	{
		dynRemove(naviHistoryPanels, 1);
		dynRemove(naviHistoryParams, 1);
		naviIndex--;
	}
}

void naviGoBackward()
{
	if(naviIndex > 1)
	{
		naviIndex--;
		sgFwNaviPanelOn();
	}
}

void naviGoForward()
{
	if(naviIndex < 10)
	{
		naviIndex++;
		sgFwNaviPanelOn();
	}
}

void enableDisableBckFwdButtons()
{
//	setTrace(EXECUTION_TRACE);
	// for backbutton if index <= 1 -> disabled
	if(shapeExists("BackButton"))
	{
		if(naviIndex <= 1)
		{
			setValue("BackButton", "enabled", false);
		}
		else
		{
			setValue("BackButton", "enabled", true);
		}
	}
	else
	{
		// sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwNaviLib.ctl; Shape BackButton in Navipanel.pnl doesn't exist");
	}
	// for fwdbutton if index >= 10 -> disabled  or if the position is the last in the table
	if(shapeExists("FwdButton"))
	{
		if(naviIndex >= 10 || dynlen(naviHistoryPanels) == naviIndex)
		{
			setValue("FwdButton", "enabled", false);
		}
		else
		{
			setValue("FwdButton", "enabled", true);
		}
	}
	else
	{
		// sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgFwNaviLib.ctl; Shape FwdButton in Navipanel.pnl doesn't exist");
	}
}

string naviReturnPanelNameOnModule(string moduleName)
{
	string fileOnModule;
	dyn_string params;
	int i;

	params = naviHistoryParams[naviIndex];

	 for(i =1 ; i <= dynlen(params); i++)
	 {
	 		int position = strpos(params[i], moduleName);

	 		if(position >= 0)
	 		{
				fileOnModule = substr(params[i], strpos(params[i], ":") + 1);
		//		dynRemove(params, i);
				return fileOnModule;
				break;
	 		}
	}
	if(i = dynlen(params))
	{
		DebugN("NaviLib.ctl: naviReturnPanelNameOnModule: $Module Name : " + moduleName + " in params is'nt available !");
		DebugN("NaviLib.ctl: naviReturnPanelNameOnModule: Params are: " + params);
	}
}

dyn_string naviReturnCurrentParams()
{
	return naviHistoryParams[naviIndex];
}

void naviSetCurrentParams(dyn_string params)
{
  naviHistoryParams[naviIndex] = params;
}//naviSetCurrentParams
