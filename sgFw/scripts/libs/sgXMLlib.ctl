// File: sgXMLLib.ctl
//
// Version 1.1
//
// Date 24-JUL-03
//
// This library contains XML processing and generation functions
//
// History
// =======
// 24-JUL-03 : First version (VL)
// 14-AUG-03 : Bugfix for extraction of last property of a self closing tag
// 15-AUG-03 : Modification for XMLsplit to return a dyn_dyn_string in case of several XML message in one frame

// process a XML frame, detect if several XML message, and return each one in a respective dyn_string
dyn_dyn_string XMLsplit(string xml)
{
	dyn_string res;
	dyn_string temp;
	dyn_string empty;
	string tag;
	int cpt;
	int index;
	string content;
	dyn_dyn_string output;
	int outputIndex = 1;

	// first split: all tags begin

	res = strsplit(xml, "<");

	// normally res[1] must be empty because text starts with "<"
	if (dynlen(res) == 0)
	{
			DebugN("XMLsplit >> receive an empty string !");
			return empty;
	}

	if(res[1] == "")
		dynRemove(res, 1);
	else
	{
		//20070111 aj added logging of xml message
		sgHistoryAddEvent("XMLUtils.XMLHistory", SEVERITY_SYSTEM, "XMLSplit: invalid first character - message:", xml);
		//DebugTN("sgXMLlib >> xmlstring: " + xml);

		return empty;
	}

	// re-insert the "<" removed by strsplit
	for(cpt = 1; cpt <= dynlen(res); cpt++)
	{
		res[cpt] = "<" + res[cpt];
	}

	temp = res;

	dynClear(res);
	// separate tag contents
	for(cpt = 1; cpt <= dynlen(temp); cpt++)
	{
		tag = temp[cpt];
		index = strpos(tag, ">");
		if(index == strlen(tag) - 1) // tag has no field
		{
			tag = strltrim(tag, " ");
			if(strlen(tag) != 0)
				dynAppend(res, tag);
		}
		else
		{
			dynAppend(res, substr(tag, 0, index + 1));
			content = substr(tag, index + 1);
			content = strltrim(content, " ");
			if(strlen(content) != 0)
				dynAppend(res, content);
		}
	}

	outputIndex = 0;
	for(cpt = 1; cpt <= dynlen(res); cpt++)
	{
		if(res[cpt] == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
			outputIndex++;
		dynAppend(output[outputIndex], res[cpt]);
	}

	return output;
}

// Check XML the structure of a XML message and return the result
// VL 15-AUG-03: added check for empty dyn_string
bool XMLcheckStructure(dyn_string xml)
{
	dyn_string stack;
	string tag;
	int cpt;
	if(dynlen(xml) == 0)
	{
		DebugN("XMLcheckStructure: dyn_string is empty");
		return false;
	}

	// check that the first tag contains the standard <?xml version="1.0" encoding="UTF-8"?> header
	if(xml[1] != "<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
	{
		DebugN("XMLcheckStructure: standard header not found");
		return false;
	}
	// check the hierarchy
	for(cpt = 2; cpt <= dynlen(xml); cpt++) // starts at 2 because of standard header
	{
		tag = xml[cpt];
		if((strlen(tag) < 3) && XMLisTag(tag))
		{
			DebugN("XMLcheckStructure: tag " + tag + " is too short");
			return false;
		}
		if(XMLisTag(tag))
		{
//			DebugN("TagName: " + XMLgetTagName(tag));
			if(!XMLisSelfClosingTag(tag))
			{
				if(XMLisClosingTag(tag))
				{
					if(dynlen(stack) == 0)
					{
						DebugN("XMLcheckStructure: unexpected closing tag, stack is empty " + tag);
						return false;
					}
					if(stack[dynlen(stack)] != XMLgetTagName(tag))
					{
						DebugN("XMLcheckStructure: non-matching closing tag " + tag + " != " + stack[dynlen(stack)]);
						return false;
					}
					dynRemove(stack, dynlen(stack));
				}
				else
				{
//					DebugN("Will stack " + XMLgetTagName(tag));
					dynAppend(stack, XMLgetTagName(tag));
				}
			}
		}
		else
		{
//			DebugN("Content: " + tag);
		}
	}
	if(dynlen(stack) == 0)
	{
		return true;
	}
	else
	{
		DebugN("XMLcheckStructure: stack is not empty in the end");
		return false;
	}
}

// Check if the string is a XML tag
bool XMLisTag(string tag)
{
	return (tag[0] == "<") && (strpos(tag, ">") != -1);
}

// Check if the tag is a self closing tag (self closing with a "/")
bool XMLisSelfClosingTag(string tag)
{
	if(!XMLisTag(tag))
		return false;

	if(tag[strlen(tag) - 2] == "/")
		return true;

	return false;
}

// Check if the tag is a closing tag
bool XMLisClosingTag(string tag)
{
	if(!XMLisTag(tag))
		return false;

	if(tag[1] == "/")
		return true;

	return false;
}

// Return the tag Name of a XML string
string XMLgetTagName(string tag)
{
	string res;
	int index;

	// remove the brackets
	res = strltrim(tag, "</ ");
	res = strrtrim(res, "> ");

	index = strpos(res, " ");
	if(index == -1)
		return res;
	else
		return(substr(res, 0, index));
}

// Return the index of the specified tag in the dyn_string containing XML message
dyn_int XMLfindTagIndex(dyn_string xml, string tagName)
{

	dyn_int res;
	string tag;
	int cpt;

	for(cpt = 1; cpt <= dynlen(xml); cpt++)
	{
		tag = xml[cpt];
		if(XMLisTag(tag))
		{
			if(!XMLisClosingTag(tag))
			{
				if(XMLgetTagName(tag) == tagName)
					dynAppend(res, cpt);
			}
		}
	}
	return res;
}

int XMLfindTagOffset(dyn_string xml, string tagName, int offset)
{
	int pos = -1;
	int cpt;

	dyn_int indexes;



	bool needSearch = true;

	if((offset > 0) && (XMLisTag(xml[offset])))
	{
		if(XMLgetTagName(xml[offset]) == tagName)
		{
			pos = offset;
			needSearch = false;
//			DebugTN("sgXMLLib, XMLextractSubTag: use direct way for tag " + tagName);
		}
	}

	if(needSearch)
	{
		indexes = XMLfindTagIndex(xml, tagName);
		for(int cpt = 1; cpt <= dynlen(indexes); cpt++)
		{
			if(indexes[cpt] >= offset)
			{
				pos = indexes[cpt];
				break;
			}
		}
	}

	return pos;

}

// Extracts the elements of tag corresponding to the name at or after the given offset
dyn_string XMLextractSubTag(dyn_string xml, string tagName, int offset)
{
	dyn_string empty;
	dyn_string res;
	dyn_int indexes;
	int pos = -1;
	int depth = 1;

//	indexes = XMLfindTagIndex(xml, tagName);
//	if(dynlen(indexes) == 0)
//	{
//		DebugN("XMLextractSubTag: tagName not found");
//		return empty;
//	}

	pos = XMLfindTagOffset(xml, tagName, offset);

	if(pos == -1)
		return empty;

	// append the starting tag to res
	dynAppend(res, xml[pos]);

	// if tag is self closing, extraction is already finished
	if(XMLisSelfClosingTag(xml[pos]))
		return res;

	while(depth != 0)
	{
		pos = pos + 1;
		if(pos > dynlen(xml))
		{
			DebugN("XMLextractSubTag: unexpected end of xml");
			return empty;
		}
		dynAppend(res, xml[pos]);
		if(XMLisTag(xml[pos]))
		{
			// check for embeded sub tags with the same name
			if(XMLgetTagName(xml[pos]) == tagName)
			{
				if(!XMLisSelfClosingTag(xml[pos]))
				{
					if(XMLisClosingTag(xml[pos]))
					{
						depth = depth - 1;
					}
					else
					{
						depth = depth + 1;
					}
				}
			}
		}
	}
	return res;
}

// Return the content of a specified tag name
string XMLgetTagContent(dyn_string xml, string tagName, int offset)
{
	dyn_int indexes;
	int pos = -1;
	int cpt;

//	indexes = XMLfindTagIndex(xml, tagName);
//	if(dynlen(indexes) == 0)
//	{
//		DebugN("XMLgetTagContent: tagName not found");
//		return "";
//	}
	// find starting index

	pos = XMLfindTagOffset(xml, tagName, offset);
	if(pos == -1)
	{
		return "";
	}
//	DebugN("XMLgetTagContent: found tag at pos = " + pos);
	if(dynlen(xml) == pos)
	{
		if(!XMLisSelfClosingTag(xml[pos]))
			DebugN("XMLgetTagContent: unexpected end found");

		return "";
	}

	if(!XMLisTag(xml[pos + 1]))  // check that next tag is content
	{
		return xml[pos + 1];
	}
	else
	{
//		DebugN("XMLgetTagContent: no content in this tag");
		return "";
	}
}

// Return the properties of a specified tag
dyn_string XMLgetTagPropertiesNames(string tag)
{
	dyn_string empty;
	dyn_string res;
	dyn_string temp;
	string s;
	int cpt;
	int index;

	if(!XMLisTag(tag))
	{
		DebugN("XMLgetTagPropertiesNames: invalid XML tag");
		return empty;
	}

	// remove the brackets
	s = strltrim(tag, "</ ");
	s = strrtrim(s, "> ");

	// split using " "
	temp = strsplit(s, " ");

	// process properties
	for(cpt = 1; cpt <= dynlen(temp); cpt++)
	{
		s = temp[cpt];
		index = strpos(s, "=");
		if(index != -1)
		{
			dynAppend(res, substr(s, 0, index));
		}
	}
	return res;
}

// Return the value of a specified property
string XMLgetTagProperty(string tag, string propertyName)
{
	dyn_string empty;
	dyn_string temp;
	string s;
	int cpt;
	int index;

	if(!XMLisTag(tag))
	{
		DebugN("XMLgetTagProperty: invalid XML tag");
		return empty;
	}

	// remove the brackets and slashes
	s = strltrim(tag, "</ ");
	s = strrtrim(s, "/> ");

	// split using " "
	temp = strsplit(s, " ");

	// process properties
	for(cpt = 1; cpt <= dynlen(temp); cpt++)
	{
		s = temp[cpt];
		index = strpos(s, "=");
		if(index != -1)
		{
			if(substr(s, 0, index) == propertyName)
			{
				 s = substr(s, index + 1);
				 s = strltrim(s, "\"");
				 s = strrtrim(s, "\"");
				 return s;
			}
		}
	}
//	DebugN("XMLgetTagProperty: property not found");
	return "";
}

// Add XML chars to the specified name, properties names and value to create a XML tag
string XMLcreateTag(string name, dyn_string propertiesNames, dyn_string propertiesValues, string content)
{
	string res;
	int cpt;

	if(dynlen(propertiesNames) != dynlen(propertiesValues))
	{
		DebugN("XMLcreateTag: propertiesNames has not the same size than propertiesValues");
		return "";
	}

	res = "<" + name;

	if(dynlen(propertiesNames) != 0)
	{
		for(cpt = 1; cpt <= dynlen(propertiesNames); cpt++)
		{
			res += " " + propertiesNames[cpt] + "=\"" + propertiesValues[cpt] + "\"";
		}
	}

	if(content == "")
		res = res + "/>";
	else
		res = res + ">" + content + "</" + name + ">";

	return res;
}

// Add the XML header to a xml string
string XMLaddHeader(string xml)
{
	return "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" + xml;
}