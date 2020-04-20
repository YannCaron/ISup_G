// File: sgISupXMLLib.ctl
//
// Version 1.1
//
// Date 14-AUG-03
//
// This library contains XML functions for ISup
//
// History
// =======
// 07-AUG-03 : First version (PW)
// 02-MAR-04 : Each XML system has a XMLMatchingTable point (Th.V)
// 03-MAR-04 : No dpSet if the matched point does not exists (VL)
// 04-MAR-04 : Invalid XML expression logged into the XMLUtil history queue

global dyn_string XMLPatterns;
global dyn_string PvssPatterns;

const string DBKEY_XML_MATCHING_CACHE = "XMLMatchingCache";
const string DBKEY_XML_VALUES_CACHE = "XMLValuesCache";

global bool isISupXMLLibInitialized = false;

global bool isInitInProgress = false;

// Get the matching table between the XML name and the PVSS name
bool initISupXMLLib()
{
	// Th.V 06.16.05 to avoid mutilple initialization
	while (isInitInProgress == true)
	{
		delay(2);
	}

	if (isISupXMLLibInitialized)
	{
		return true;
	}

	// Th.V 06.16.05 to avoid mutilple initialization
	isInitInProgress = true;

	dyn_string XMLEntries;
	dyn_string input, output;

	sgDBWaitForInit();

	sgDBCreateTable(DBKEY_XML_MATCHING_CACHE);
	sgDBCreateTable(DBKEY_XML_VALUES_CACHE);

	dpConnect("XMLEmtpyValuesCache", false, "XMLUtils.Commands.EmptyCache");

	XMLEntries = getPointsOfType("sgXMLMatchingTable");
	//DebugN("XMLEntries: " + XMLEntries);

	for (int XMLId = 1;  XMLId <= dynlen(XMLEntries); XMLId++)
	{
		dpGet(XMLEntries[XMLId] + ".Input", input);
		dpGet(XMLEntries[XMLId] + ".Output", output);

		// 06.16.05 Th.V check if length are the same, return false if not
		if (dynlen(input) != dynlen(output))
		{
			dynClear(XMLPatterns);
			dynClear(PvssPatterns);

			DebugTN("initISupXMLLib >> XML matching problem: nb fields not the same for: " + XMLEntries[XMLId] + " (input: " + dynlen(input) + " output: " + dynlen(output));
			return false;
		}

		dynAppend(XMLPatterns, input);
		dynAppend(PvssPatterns, output);
	}

//	DebugN("XMLPatterns: " + XMLPatterns);
//	DebugN("PvssPatterns: " + PvssPatterns);

	//dpGet("XMLUtils.XMLMatchingTable.Input", XMLPatterns);
	//dpGet("XMLUtils.XMLMatchingTable.Output", PvssPatterns);
	isISupXMLLibInitialized = true;
	isInitInProgress = false;
	// DebugTN("initISupXMLLib is now true");
	return true;
}

void sgXMLPrepareForceToUKN(string source = "", string systemName = "")
{
	// 07.03.2006 aj added optional parameter systemName to be able to empty the cache on another system (e.g. EMSup!!)
	// if the systemName is given, source has to be given as well !!!!!!!!!!!!!!
	if (source != "")
		sgHistoryAddEvent(systemName + "XMLUtils.XMLHistory", SEVERITY_SYSTEM,"empty XML cache due to: " + source);
	else
		sgHistoryAddEvent(systemName + "XMLUtils.XMLHistory", SEVERITY_SYSTEM,"empty XML cache");
	dpSet(systemName + "XMLUtils.Commands.EmptyCache", true);
}

void XMLEmtpyValuesCache(string dpName, bool dpVal)
{
	dyn_string keys;

	keys = sgDBTableKeys(DBKEY_XML_VALUES_CACHE);
	for(int cptKey = 1; cptKey <= dynlen(keys); cptKey++)
	{
		sgDBSet(DBKEY_XML_VALUES_CACHE, keys[cptKey], "-");
	}
}

// Check the XML structure and call the processing XML for ISup
string XMLanalyseISupStatus(dyn_string xml, bool returnStatus)
{
	dyn_int indexes;
	dyn_string ISupStatus;
	int cpt;
	string res;


	if(!XMLcheckStructure(xml))
	{
		sgHistoryAddEvent("XMLUtils.XMLHistory", SEVERITY_SYSTEM, "Invalid xml expression");
		//DebugN("XMLanalyseISupStatus; Invalid xml expression");
		return "";
	}
	indexes = XMLfindTagIndex(xml, "ISupStatus");

	for(cpt = 1; cpt <= dynlen(indexes); cpt++)
	{
		ISupStatus = XMLextractSubTag(xml, "ISupStatus", indexes[cpt]);
		res = res + processISupStatus(ISupStatus, returnStatus);
	}

	// adding the headerhistoryAdd
	// res = XMLaddHeader(res);


	return res;
}

// Process the XML to set the status in ISup
string processISupStatus(dyn_string status, bool returnStatus)
{
	dyn_int indexes;
	int cpt;
	dyn_string systemTags;
	string res;

	indexes = XMLfindTagIndex(status, "System");

	for(cpt = 1; cpt <= dynlen(indexes); cpt++)
	{
		systemTags = XMLextractSubTag(status, "System", indexes[cpt]);
		res = res + processSystem(systemTags);
	}
	if(returnStatus)
		return XMLcreateTag("ISupStatus", makeDynString("Version"), makeDynString("1.0"), res);
	else
		return XMLcreateTag("ISupCommand", makeDynString("Version"), makeDynString("1.0"), res);
}

// Process XML for the system
string processSystem(dyn_string systemTags)
{
	dyn_int indexes;
	int cpt;
	dyn_string subSystem;
	string systemName;
	string content;

	indexes = XMLfindTagIndex(systemTags, "SubSystem");

	systemName = XMLgetTagProperty(systemTags[1], "Name");

//	DebugN("Process system " + systemName);
	for(cpt = 1; cpt <= dynlen(indexes); cpt++)
	{
		subSystem = XMLextractSubTag(systemTags, "SubSystem", indexes[cpt]);

		content = content + processSubSystem(subSystem, systemName);
	}
	return XMLcreateTag("System", makeDynString("Name"), makeDynString(systemName), content);
}

// Process XML for the subsystem
string processSubSystem(dyn_string tags, string systemName)
{

	dyn_int indexes;
	int cpt;
	dyn_string labelTags;
	string subSystemName;
	string status;
	string message = "";
	string label1 = "";
	string label2 = "";
	string label3 = "";
	string label4 = "";
	dyn_string labelValues;
	dyn_string outputs;
	string systemPrefix;

	indexes = XMLfindTagIndex(tags, "Label");

	subSystemName = XMLgetTagProperty(tags[1], "Name");

	status = XMLgetTagProperty(tags[1], "Status");

//	DebugN("Process subsystem " + systemName + "." + subSystemName + " with status " + status);
	for(cpt = 1; cpt <= dynlen(indexes); cpt++)
	{
		labelTags = XMLextractSubTag(tags, "Label", indexes[cpt]);

		labelValues = processLabel(labelTags, systemName, subSystemName);
		if(labelValues[1] == "Label1")
			label1 = labelValues[2];
		else if(labelValues[1] == "Label2")
			label2 = labelValues[2];
		else if(labelValues[1] == "Label3")
			label3 = labelValues[2];
		else if(labelValues[1] == "Label4")
			label4 = labelValues[2];
	}

	indexes = XMLfindTagIndex(tags, "Message");
	if(dynlen(indexes) != 0)
	{
		message = XMLgetTagContent(tags, "Message", 0);

		dyn_string temp;
		temp = strsplit(message, "\r");
		message = temp[1];

		//DebugTN("processSubSystem >> message: " + message);
	}

	time start = getCurrentTime();
	outputs = XMLmatchPVSSName(systemName + "." + subSystemName);

	systemPrefix = outputs[1];

	if(!dpExists(systemPrefix))
	{
		sgHistoryAddEvent("XMLUtils.XMLHistory", SEVERITY_SYSTEM, "matched point " + systemPrefix + " does not exist");
	}
	else
	{

		string currentValues;
		string cachedValues;

		string reference = "";
		if(dynlen(outputs) > 1)
		{
			reference = outputs[2];
			dpSet(reference, true);
		}

		currentValues = status + "-" + label1 + "-" + label2 + "-" + label3 + "-" + label4 + "-" + message;

		cachedValues = sgDBGet(DBKEY_XML_VALUES_CACHE, systemPrefix);
		if(cachedValues != currentValues)
		{
			sgDBSet(DBKEY_XML_VALUES_CACHE, systemPrefix, currentValues);
			dpSet(systemPrefix + LABEL1_POSTFIX, label1,
						systemPrefix + LABEL2_POSTFIX, label2,
						systemPrefix + LABEL3_POSTFIX, label3,
						systemPrefix + LABEL4_POSTFIX, label4,
						systemPrefix + MESSAGE_POSTFIX, message,
						systemPrefix + PRE_STATUS_POSTFIX, status);

		}
	}
	//returning the value

	return XMLcreateTag("SubSystem", makeDynString("Name", "Status"), makeDynString(subSystemName, status), "");
}

// return a string containing the pvss name matching the XML name
dyn_string XMLmatchPVSSName(string XMLName)
{
	int i;
	string s;
	string starValue;

	string cachedValue;

	cachedValue = sgDBGet(DBKEY_XML_MATCHING_CACHE, XMLName);
	if(cachedValue != "")
	{
		//DebugTN("XMLmatchPVSSName: use cache");
		return strsplit(cachedValue, "+");
	}

//	DebugN("XMLmatchPVSSName: XMLPatterns : " + XMLPatterns);
//	DebugN("XMLmatchPVSSName: PvssPatterns : " + PvssPatterns);

	for(i = 1; i <= dynlen(XMLPatterns); i++)
	{
//		DebugN("XMLName: " + XMLName);

		if(stringMatchPattern(XMLName, XMLPatterns[i]))
		{
			dyn_string allPatterns;
			string newCacheValue = "";
			starValue = findStarValue(XMLPatterns[i], XMLName);
			allPatterns = strsplit(PvssPatterns[i], "+");
			for(int cptPatterns = 1; cptPatterns <= dynlen(allPatterns); cptPatterns++)
			{
				newCacheValue += replaceStar(allPatterns[cptPatterns], starValue) + "+";
			}
			sgDBSet(DBKEY_XML_MATCHING_CACHE, XMLName, newCacheValue);
			return strsplit(newCacheValue, "+");
		}
	}
	sgHistoryAddEvent("XMLUtils.XMLHistory", SEVERITY_SYSTEM, "Unable to match XMLName " + XMLName);
	return "";
}

//returns a dyn_string containing the name of the label in first cell and its value in the second cell
dyn_string processLabel(dyn_string tags, string systemName, string subSystemName)
{
	dyn_string labelTags;
	string labelName;
	string value;

	labelName = XMLgetTagProperty(tags[1], "Name");

	value = XMLgetTagContent(tags, "Label", 0);
//	DebugN("Process label " + systemName + "." + subSystemName + "." + labelName + " = " + value);
	return(makeDynString(labelName, value));
}
