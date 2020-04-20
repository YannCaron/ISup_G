// File: sgXMLInterface.ctl
// 
// Version 1.1
//
// Date 11-AUG-03
//
// This library contains the XML interface script
//
// History
// =======
// 11-AUG-03 : First version from test panel(VL)

dyn_string XMLPatterns;
dyn_string PvssPatterns;


void XMLCallBack(int socketNumber, string text)
{
	dyn_string xml;
	dyn_string ISupStatus;

	dyn_int indexes;
	int cpt;

	string s = text;
	string res;
	
	strreplace(s, "\0", " ");
	strreplace(s, "\n", " ");
	strreplace(s, "\r", " ");

//	DebugN("XMLCallBack; Received message " + s + " from socket " + socketNumber);
	xml = XMLsplit(s);
	
	if(!XMLcheckStructure(xml))
	{
		DebugN("XMLCallBack; Invalid xml expression");
		return;
	}
	indexes = XMLfindTagIndex(xml, "ISupStatus");	

	for(cpt = 1; cpt <= dynlen(indexes); cpt++)
	{
		ISupStatus = XMLextractSubTag(xml, "ISupStatus", indexes[cpt]);
		res = res + processISupStatus(ISupStatus);
	}	

	// adding the header
	res = XMLaddHeader(res);
	
//	DebugN("In XMLCallBack; for ACk. Res = " + res);
	// Sending the acknowledge message
	serverSocketSendMessage(socketNumber, res);
	// Sending the closing socket command
	serverSocketSendCommand("CloseSocket;" + socketNumber + ";");		
	
}

string processISupStatus(dyn_string status)
{
	dyn_int indexes;
	int cpt;
	dyn_string systemTags;
	string res;
	
	indexes = XMLfindTagIndex(status, "System");	

	// check version

	for(cpt = 1; cpt <= dynlen(indexes); cpt++)
	{
		systemTags = XMLextractSubTag(status, "System", indexes[cpt]);
		res = res + processSystem(systemTags);
	}	
	return XMLcreateTag("ISupCommand", makeDynString("Version"), makeDynString("1.0"), res);
}

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
	}
	
	systemPrefix = XMLmatchPVSSName(systemName + "." + subSystemName, XMLPatterns, PvssPatterns);
	
	dpSet(systemPrefix + LABEL1_POSTFIX, label1);
	dpSet(systemPrefix + LABEL2_POSTFIX, label2);
	dpSet(systemPrefix + LABEL3_POSTFIX, label3);
	dpSet(systemPrefix + LABEL4_POSTFIX, label4);

	dpSet(systemPrefix + MESSAGE_POSTFIX, message);
	dpSet(systemPrefix + PRE_STATUS_POSTFIX, status);
	
	//returning the value
	return XMLcreateTag("SubSystem", makeDynString("Name", "Status"), makeDynString(subSystemName, status), "");  
}

// return a string containing the pvss name matching the XML name
string XMLmatchPVSSName(string XMLName, dyn_string XMLPatterns, dyn_string PvssPatterns)
{
	int i;
	string s;
	string res;
	string starValue;
	
	for(i = 1; i <= dynlen(XMLPatterns); i++)
	{
//		DebugN("XMLName: " + XMLName);
				
		if(stringMatchPattern(XMLName, XMLPatterns[i]))
		{
			starValue = findStarValue(XMLPatterns[i], XMLName);
			res = replaceStar(PvssPatterns[i], starValue);
//			DebugN("Match " + XMLName + " to " + res);
			return res;
		}
	}
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


main()
{
	dpGet("XMLUtils.XMLMatchingTable.Input", XMLPatterns);
	dpGet("XMLUtils.XMLMatchingTable.Output", PvssPatterns);

	
	serverSocketListen(7000, "XMLCallBack");
}