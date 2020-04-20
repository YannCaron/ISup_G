// used by DatabaseSaver.pnl
const string ALL_PATTERN = "*";
const string DP_VALUE = ":_original.._value";
const string DP_STATUS = ":_original.._status";
const string DP_TIME = ":_original.._stime";
const string DP_ACTIVE = ":_original.._active";
const char DP_SEPARATOR = '.';
const char PATTERN_OR_BEGIN = '{';
const char PATTERN_OR_END = '}';
const char PATTERN_OR_SEPARATOR = ',';

string patternConcat(dyn_string patterns)
{

	string pattern = "";

	if (dynlen(patterns) > 1)
	{
		pattern = PATTERN_OR_BEGIN; // append {
		pattern += strconcat(patterns, PATTERN_OR_SEPARATOR); // concat with ,
		pattern += PATTERN_OR_END; // append }
	}
	else if (dynlen(patterns) == 1)
	{
		pattern = patterns[1];
	}
	
	return pattern;

}

dyn_string addPatternToDpElements (dyn_string dpElements, string pattern)
{

	// variable
	int i;
	string dpe;
	dyn_string dpes;
	dyn_string value;

	if (dynlen(dpElements) != 0)
	{
		// get type + pattern
		for (i=1; i<=dynlen(dpElements); i++)
		{
			dpes = dpNames(dpElements[i] + DP_SEPARATOR + pattern + DP_VALUE);
			dynAppend(value, dpes);
		}
	}
	else
	{
		// get only pattern
		value = dpNames(pattern + DP_VALUE);
	}
	
	// remove extract only datapoint element
	for (i=1; i<=dynlen(value); i++)
	{
		value[i] = dpSubStr (value[i], DPSUB_DP_EL);
	}
	
	return value;

}
dyn_string getPointsOfTypeFromPattern(string typePattern)
{

	// variable
	dyn_string types;
	dyn_string values;
	int i;
	
	// get from variable
	types = dpTypes(typePattern);
	
	// loop on types
	for (i=1; i<=dynlen(types); i++)
	{
		dynAppend (values, getPointsOfType (types[i]));
	}
	
	return values;

}

dyn_string getDpElementsFromPattern (string typePattern, string pattern)
{

	// variable
	int i;
	dyn_string dpElements;
	dyn_string value;
	
	if (typePattern != "" && typePattern != ALL_PATTERN)
		dpElements = getPointsOfTypeFromPattern (typePattern);
	
	if (pattern != "")
	{
		value = addPatternToDpElements(dpElements, pattern);
	}
	else
	{
		// get only type
		value = dpElements;
	}
	
	return value;

}

void appendDpElementsToFile(file f, dyn_string dpElements, bool writeType=true)
{

	// variable
	int i;
	dyn_anytype originalValues;
	dyn_anytype originalStatus;
	dyn_anytype originalSTimes;
	const time NULL_DATE;

	// get values
	originalValues = getDpValues (dpElements, DP_VALUE);
	originalStatus = getDpValues (dpElements, DP_STATUS);
	originalSTimes = getDpValues (dpElements, DP_TIME);
	
	// loop on datapoints
	for (i=1; i<=dynlen(dpElements); i++)
	{
	
		// verify data is not empty
		if (originalSTimes[i] != NULL_DATE)
		{
	
			// put on file
			fputs (getASCIIDPValueLine (dpElements[i], originalValues[i], originalStatus[i], originalSTimes[i], writeType), f);
		
		}
	}
}

int appendDPPatternToFile (file f, string type, string pattern, bool writeType=true)
{

	// variable
	int i;
	dyn_string dpElements;
	string fileLine;

	// get datapoints
	dpElements = getDpElementsFromPattern(type, pattern);

	appendDpElementsToFile (f, dpElements, writeType);
	fflush (f);
	
	return dynlen(dpElements);

}

void removeMissingDPEs(dyn_string &dpElements, string subPoint)
{

	string dpElement;

	for (int i=dynlen(dpElements); i>=1 ; i--)
	{
	
		dpElement = dpElements[i] + subPoint;
	
		if (!dpExists(dpElement))
		{
			dynRemove(dpElements, i);
		}
	}
}

dyn_anytype getDpValues (dyn_string dpElements, string dpParameter)
{

	// variable
	dyn_string dpIDs;
	dyn_anytype dpValues;
	
	dpIDs = dpAppend(dpElements, dpParameter);
	
	// get datapoints values
	dpGet (dpIDs, dpValues);
	
	return dpValues;

}

dyn_anytype getDpDescriptions (dyn_string dpElements, string dpParameter)
{

	// variable
	dyn_string dpIDs;
	
	dpIDs = dpAppend(dpElements, dpParameter);
	
	// get datapoints values
	return dpGetDescription (dpIDs);

}

dyn_string dpAppend (dyn_string dpElements, string dpAdd)
{

	// variable
	dyn_string dpIDs;
	
	// loop on datapoints
	for (int i=1; i<=dynlen(dpElements); i++)
	{
		dynAppend (dpIDs, dpElements[i] + dpAdd);
	}
	
	return dpIDs;

}

string dpGetDpFromType (string dpe, string dpt)
{

	dyn_dyn_string dpes;
	string dpeReturn = "";
	
	// get refs
	dpes = dpGetDpTypeRefs (dpTypeName(dpe));
	
	// search in refs
	for (int i=1; i<=dynlen(dpes); i++)
	{
		if (dpes[i][1] == dpt)
		{
			dpeReturn = dpe + "." + dpes[i][2];
		}
	}
	
	return dpeReturn;

}


dyn_string dpGetDpsFromType (string dpe, string dpt)
{

	dyn_dyn_string dpes;
	dyn_string rets = makeDynString();
	
	// get refs
	dpes = dpGetDpTypeRefs (dpTypeName(dpe));
	
	// search in refs
	for (int i=1; i<=dynlen(dpes); i++)
	{
		if (dpes[i][1] == dpt)
		{
			dynAppend(rets, dpe + "." + dpes[i][2]);
		}
	}
	
	return rets;

}

bool isExistDpType (string dpe, string dpt)
{
	return (dpGetDpFromType (dpe, dpt) != "");
}
