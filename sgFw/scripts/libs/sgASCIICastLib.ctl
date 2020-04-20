//** constant
const string HEXA_BEGINER = "0x";
const string ASCIIMANAGER_TIME_FORMAT = "%d.%m.%Y %H:%M:%S";
const string ASCIIMANAGER_MILLI_FORMAT = ".%03d";
const time NULL_DATE;

// ** property
bool isDyn(int elementType)
{

	// variable
	int type;
	bool value = false;
	
	type = elementType;
	
	if (type == DPEL_DYN_BIT32 || type == DPEL_DYN_BOOL || type == DPEL_DYN_BLOB || 
			type == DPEL_DYN_CHAR || type == DPEL_DYN_DPID || type == DPEL_DYN_FLOAT ||
			type == DPEL_DYN_INT || type == DPEL_DYN_LANGSTRING || type == DPEL_DYN_STRING ||
			type == DPEL_DYN_TIME || type == DPEL_DYN_UINT)
	{
		value = true;
	}
	
	return value;

}

// ** methode
string castFromBit32 (bit32 binValue)
{

	// constant
	dyn_char hexValue = makeDynChar ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F');

	// variable
	int i;
	bool isNumber;
	string stringBin;
	bit32 binByte;
	int intByte;
	string value;

	// convert bit32 to string
	stringBin = (string)binValue;
	
	// initialize
	isNumber = false;
	value = HEXA_BEGINER;
	
	// loop on 8 bytes of bit32 value
	for (i=0; i<32; i+=4)
	{
		binByte = (bit32)substr (stringBin, i, 4);
		intByte = (int)binByte;

		if (!isNumber)
			isNumber = (intByte > 0);
	
		if (isNumber || i == 28) // is number or last bit (if value = 0x0)
			value += hexValue[intByte + 1];
	}
	
	return value;

}

string castFromBool(bool boo)
{
	return (string)(int)boo;
}

string castFromChar(char chr)
{
	return "\\" + (int)chr;
}

string castFromLangstring(langString lan)
{

	// variable
	int i;
	string value;
	
	// initialize value
	value = "";

	// loop on local languages	
	for (i=0; i<getNoOfLangs(); i++)
	{
	
		// separator
		if (value != "")
			value += " ";
	
		// add lang value
		value += "LANG:" + getGlobalLangId(i) + " ";
		value += castFromString(lan[i]);
	}

	// number of langs	
	value = "lt:" + getNoOfLangs() + " " + value;

	return value;

}

string castFromString(string str)
{
	
	// variable
	string value;
	
	// initialize value
	value = str;
	
	// replace specials caracters
	strreplace (value, "\\", "\\\\");
	strreplace (value, "\"", "\\\"");
	
	// set quotes
	value = "\"" + value + "\"";
	
	return value;
	
}

string castFromTime(time tim)
{
	return formatTime (ASCIIMANAGER_TIME_FORMAT, tim, ASCIIMANAGER_MILLI_FORMAT);
}

string castFromAnyType(anytype valueToCast, int elementType)
{

	// variable
	string value;
	
	// case type
	switch (elementType)
	{
		// simple type
		case DPEL_BIT32 :
		case DPEL_DYN_BIT32 :
			value = castFromBit32(valueToCast);
		break;
		case DPEL_BOOL :
		case DPEL_DYN_BOOL :
			value = castFromBool(valueToCast);
		break;
		case DPEL_BLOB :
		case DPEL_DYN_BLOB :
			value = castFromString(valueToCast);
		break;
		case DPEL_CHAR :
		case DPEL_DYN_CHAR :
			value = castFromChar(valueToCast);
		break;
		case DPEL_LANGSTRING :
		case DPEL_DYN_LANGSTRING :
			value = castFromLangstring(valueToCast);
		break;
		case DPEL_STRING :
		case DPEL_DYN_STRING :
			value = castFromString(valueToCast);
		break;
		case DPEL_TIME :
		case DPEL_DYN_TIME :
			value = castFromTime(valueToCast);
		break;
		// for anothers : float, int, identifier, unsigned
		default :
			value = (string)valueToCast;
		break;
	}
	
	return value;

}

string castFromDynAnyType(anytype valueToCast, int elementType)
{

	// variable
	int i;
	string value;
	
	// initialize
	value = "";

	// loop on dyn	
	for (i=1; i<=dynlen(valueToCast); i++)
	{
	
		if (value != "")
			value += ", ";
	
		value += castFromAnyType(valueToCast[i], elementType);
		
	}
	
	return value;

}

string toString (anytype valueToCast, int elementType)
{

	// variable
	string value;

	if (!isDyn(elementType))
	{
		// anytype
		value = castFromAnyType(valueToCast, elementType);
	}
	else
	{
		// dyn any type
		value = castFromDynAnyType(valueToCast, elementType);
	}
	
	return value;

}
