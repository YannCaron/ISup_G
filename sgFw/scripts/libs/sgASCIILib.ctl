#uses "sgASCIICastLib.ctl"

//** constant
const string ASCII_HEADER = "# ascii dump of database";
const string ASCII_COMMENT_DPVALUE = "# DpValue";
const string ASCII_VALUETABLE_HEADER = "ElementName\tTypeName\t_original.._value\t_original.._status\t_original.._stime";
const char ASCII_COMMENT_CHAR = "#";
const char ASCII_LINE_SEPARATOR = '\n';
const char ASCII_COLUMN_SEPARATOR = '\t';
const string ASCII_INFO_FILE = "PVSS00ascii_info.log";
const string ASCII_LOG_FILE = "PVSS00ascii_log.log";

const string PATTERN_1_NAME = "Disabled";
const string PATTERN_1_TYPE = "sgFwSystem";
const string PATTERN_1_PATTERN = "{Disabled,Comment}";

//** ASCII document
string getASCIIDocumentHeader()
{
	
	// variable
	string content = "";
	
	content += ASCII_HEADER + ASCII_LINE_SEPARATOR;
	content += ASCII_LINE_SEPARATOR; // line break

	return content;
	
}

string getASCIIDPValuesHeader()
{

	// variable
	string content = "";
	
	content += ASCII_COMMENT_DPVALUE + ASCII_LINE_SEPARATOR;
	content += ASCII_VALUETABLE_HEADER + ASCII_LINE_SEPARATOR;

	return content;

}

string getASCIIComment(string comment)
{

	// variable
	string content;
	
	content = ASCII_COMMENT_CHAR + " " + comment + ASCII_LINE_SEPARATOR;

	return content;

}
string getASCIIDPValueLine(string dpElement, anytype originalValue, bit32 originalStatus, time originalSTime, bool writeType=true)
{

	// variable
	string content;
	
        string typeName = "";
        if (writeType == true) {
          typeName = dpTypeName(dpElement);
        }
        
	content = 
		dpElement + ASCII_COLUMN_SEPARATOR +
		typeName + ASCII_COLUMN_SEPARATOR +
		toString(originalValue, dpElementType(dpElement)) + ASCII_COLUMN_SEPARATOR +
		castFromBit32 (originalStatus) + ASCII_COLUMN_SEPARATOR +
		(string)originalSTime + ASCII_LINE_SEPARATOR;

	return content;

}

string getASCIIInfoFilename()
{
	return getPath(LOG_REL_PATH) + ASCII_INFO_FILE;
}

string getASCIILogFilename()
{
	return getPath(LOG_REL_PATH) + ASCII_LOG_FILE;
}

//** ASCII Command
void addASCIICmdIn(string &ASCIICommand, string fileName)
{
	ASCIICommand += " -in " + fileName;
}

void addASCIICmdLog(string &ASCIICommand)
{
	ASCIICommand += " -log +stderr -log -file > " + getASCIIInfoFilename() + " 2> " + getASCIILogFilename();
}

string getASCIICommand()
{
	return "PVSS00ascii";
}

//** Disaboled and comments

int disabledAndComments (string filename)
{

	// variable
	file f;
  int count;
	
	// write new file
	f = fopen (filename, FILE_CREATE);
	
	// header
	fputs (getASCIIDocumentHeader(), f);
	fputs (getASCIIDPValuesHeader(), f);
	
	// execute pattern 1
	fputs (getASCIIComment(PATTERN_1_NAME), f);
	count += appendDPPatternToFile(f, PATTERN_1_TYPE, PATTERN_1_PATTERN, false);
	
	// close
	fflush(f);
	fclose(f);
        
	return count;

}
