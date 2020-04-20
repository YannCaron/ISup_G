
const string WindowspanelPath = "sgFw\\sgFwConfirmWindow.pnl";
const string GENERIC_PANEL = "sgFw\\GenericConfig\\GenericPanel.pnl";
const string ENLARGED_PANEL = "sgFw\\GenericConfig\\GenericEnlargedPanel.pnl";

const string DBKEY_MODIFIED_VALUES = "MODIFIED_VALUES";
const string DBKEY_UPDATED_VALUES = "UPDATED_VALUES";

void CallPanel(string selectedPoint, string selectedType)
{
	// remove keys from sgDB
	dyn_string dynKeys;
	dynKeys = sgDBTableKeys(DBKEY_MODIFIED_VALUES);
	
	for (int cpt = 1; cpt <= dynlen(dynKeys); cpt++)
	{
		bool b;
		b = sgDBRemove(DBKEY_MODIFIED_VALUES, dynKeys[cpt]);
		if (!b)
			DebugN("GenericConfigPanel: unable to remove key: " + dynKeys[cpt]);
	}
	
	//DebugN("sgGenerciConfigPanel >> SelectedType: " + selectedType);
	if (selectedType != "sgFwConnections" && selectedType != "sgAETable" && selectedType != "sgFwTruthTable"  && selectedType != "sgConnectWithConvertTable")
	{
		dyn_float dummyFloat;
		dyn_string dummyString;
		ChildPanelOnModalReturn(GENERIC_PANEL, "Config",makeDynString("$DPName:" + selectedPoint, "$DPType:" + selectedType), 0, 0,	dummyFloat, dummyString);
	}	
	else
	{
		// DebugN("sgGenerciConfigPanel >> CALL ENLARGED PANEL");	
		ChildPanelOnModal(ENLARGED_PANEL, "Config",makeDynString("$DPName:" + selectedPoint, "$DPType:" + selectedType), 0, 0);	
	}
} // void CallPanel(string selectedPoint, string selectedType)

dyn_string SummaryDblClick(string selectedPoint, string selectedType)
{
	 // The user make a double click on the right pan
 // We want to run a panel for edditing/add/ modify characteristics
  sgDBCreateTable(DBKEY_UPDATED_VALUES);
  	
	string panelPath;
	//string selectedPoint;
	//selectedPoint = PointsList.selectedText;
	string pointType;
	pointType = dpTypeRefName(selectedPoint);	
	if (pointType == "")
	pointType = dpTypeName(selectedPoint);
	
	panelPath = "sgFw\\GenericConfig\\GenericConfig_" + pointType + ".pnl";
 
	if (isPanelExist(panelPath) == false)
	{
		dyn_float dummyFloat;
		dyn_string dummyString;
		ChildPanelOnModal(WindowspanelPath, "Warning !!!", makeDynString("$1:" + "The configuration panel for the type '"  + pointType + "' doesn't exist", "$2:" + "OK", "$3: "), 0, 0);
		// DebugN("try to run panel: " + panelPath);
  	dyn_string dummy;
  	return dummy;
	}
	
	// Call the config panel	
	CallPanel(selectedPoint, selectedType);	
	
	return  Eval(selectedPoint, selectedType);
} // SummaryDblClick

bool isPanelExist(string panelPath)
{
	for (int i = 0; i < 10; i++)
	{
		string path = getPath(PANELS_REL_PATH, panelPath, "", i);
		if (path != "")
		{
			// DebugN("the panel: " + panelPath + " is existing");	
			return true;
		}
	}
	return false;
} // bool isPanelExist(string panelPath);

dyn_string Eval(string selectedPoint)
{
	// DebugN("selectedPoint: " + selectedPoint);
	string pointType;
	
	pointType = dpTypeRefName(selectedPoint);
	if (pointType == "")
	pointType = dpTypeName(selectedPoint);
	
	// DebugN("Selected point from the points list: " + selectedPoint);
	// DebugN("Type of selected point: " + pointType);
	dyn_string pointsList;

	dyn_string summary;
	
	string script = "dyn_string main() { return generateSummary_" + pointType + "(\"" + selectedPoint + "\");}";

  //DebugN(script);
	dyn_string dummy;
	int res;
		
	res = evalScript(summary, script, dummy);
	if(0 != dynlen(summary))
	{
		//SummaryList.items = summary;
	}
	else
	{
		// there is no function to generate a summary...
		pointsList =getPointsFromPattern(selectedPoint + ".*" );
		//DebugN("Summary: " + pointsList);
		
		//SummaryList.deleteAllItems();
		
		for (int i = 1; i < dynlen(pointsList); i++)
		{
			dyn_string detailsPoint = getPointsFromPattern(pointsList[i] + ".*");
			
			for (int x = 1; x < dynlen(detailsPoint); x++)
			{
				//SummaryList.appendItem("    " + detailsPoint[x]);
				dynAppend(summary, "    " + detailsPoint[x]);
			}
		}// loop on pointsList
	} // default
//	DebugTN("sgFwGenericConfigLib >> Eval() summary: " + summary);
	return summary;
} // Eval

void upDateTableValues(string dpName)
{
		dyn_string updatedKeys;
		dyn_string values;
		updatedKeys = sgDBTableKeys(updatedKeys);
		
		if (!dynContains(updatedKeys, dpName))
			sgDBSet(DBKEY_UPDATED_VALUES, dpName, values);
		else
			sgDBAppend(DBKEY_UPDATED_VALUES, dpName, values);
}		