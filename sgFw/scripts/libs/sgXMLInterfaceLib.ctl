// File: sgXMLInterfaceLib.ctl
//
// Version 1.1
//
// Date 24-JUL-03
//
// This library contains the XML Callback function
//
// History
// =======
// 14-AUG-03 : First version (PW)

// Process the XML message, and call the ISup XML analyzer
void XMLCallBack(int socketNumber, string text)
{
	string res, str;
	dyn_dyn_string xmls;
	int xmlsIndex;

//	DebugN("XMLCallBack; Received message " + text + " from socket " + socketNumber);
	sgHistoryAddEvent("XMLUtils.XMLHistory", SEVERITY_SYSTEM, "Starting of receiving XML message");
	xmls = XMLsplit(text);
//	if(dynlen(xmls) > 1)
//	{
//		DebugN("XMLCallBack; Received " + dynlen(xmls) + " xml messages in a single frame");
//	}
	for(xmlsIndex = 1; xmlsIndex <= dynlen(xmls); xmlsIndex++)
	{
		res = XMLanalyseISupStatus(xmls[xmlsIndex], false);
		// Sending the acknowledge message
		serverSocketSendMessage(socketNumber, res);
		str = "\tXML message: " + xmls[xmlsIndex] ;
		sgHistoryAddEvent("XMLUtils.XMLHistory", SEVERITY_SYSTEM, str);
		str = + "\tXML after analyse: " + res;
		sgHistoryAddEvent("XMLUtils.XMLHistory", SEVERITY_SYSTEM, str);
//		DebugN("sgXMLInterfaceLib: Will send response " + res);
	}


	// Sending the closing socket command
	sgHistoryAddEvent("XMLUtils.XMLHistory", SEVERITY_SYSTEM, "End of XML message");
	serverSocketSendCommand("CloseSocket;" + socketNumber + ";");

	// sgHistoryAddEvent("XMLUtils.XMLHistory", SEVERITY_SYSTEM, "End of receiving XML message");
}
