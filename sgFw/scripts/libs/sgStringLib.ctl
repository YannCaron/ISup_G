//** constant
const char STR_PLACE_CHARACTER = '%';

//** methode
int strlastpos(string str, string search) {
  int len = strlen(search);
  for (int i = strlen(str) - len; i >=0; i--) {
    if (substr(str, i, len) == search) return i;
  }
  return -1;
}

string dpParent(string dp) {
  int lastPoint = strlastpos(dp, ".");
  return substr(dp, 0, lastPoint);
}

bool isInStr (string s, string searchstr)
{
	return (strpos(s, searchstr) != -1);
}

bool isInStrBegin (string s, string searchstr)
{
	return (strpos(s, searchstr) == 0);
}

bool isInStrEnd (string s, string searchstr)
{
	return (strpos(s, searchstr) == strlen(s) - strlen(searchstr));
}

string strconcat(dyn_string dyn, char delimiter)
{

	// variable
	int i;
	string value;
	
	for (i=1; i<=dynlen(dyn); i++)
	{
		
		// set delimiter
		if (value != "") value += delimiter;
		
		// add value
		value += dyn[i];
		
	}
	
	return value;
	
}

string strplace(string s, ...)
{

	// variable
	va_list parameters;
	int i;
	int len;
	string toReplace;
	string value = s;

	// get parameters length
	len = va_start (parameters);

	// loop on parameters
	for (i=1; i<=len; i++)	
	{
		// replace %1, %2 ...
		toReplace = STR_PLACE_CHARACTER + (string)i;
		strreplace(value, toReplace, va_arg (parameters));
	}
	
	va_end (parameters);

	return value;

}

string strchar(int number, char chr)
{

	string value = "";

	for (int i=1; i<=number; i++)
	{
		value += chr;
	}
	
	return value;
	
}

string strspace(int number)
{
	return strchar(number, ' ');
}