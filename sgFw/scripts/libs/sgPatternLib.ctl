// File: sgPatternLib.ctl
// 
// Version 1.1
//
// Date 07-AUG-03
//
// This library contains pattern functions
//
// History
// =======
// 07-AUG-03 : First version (PW)



// VL: modified to return the system name if not identical to the local system
// return all the points of the specified pattern
dyn_string getPointsFromPattern(string pattern)
{
	int i;
	dyn_string points;
	
	points = dpNames(pattern);

	string localSystem;
	
	localSystem = getSystemName();

	//cutting "system1:"
	for(i = 1; i <= dynlen(points); i++)
	{
		string pointName;
		string systemName;
		
		systemName = substr(points[i], 0, strpos(points[i], ":") + 1);
		
		if(systemName == localSystem)
			points[i] = substr(points[i], strpos(points[i], ":")+1);

	}
	
	return points;
}

dyn_string getPointsFromDynPatterns(dyn_string patterns) {
  dyn_string points;
  
  for (int i=1; i<=dynlen(patterns); i++) {
    dynAppend(points, getPointsFromPattern(patterns[i]));
  }
  
  return points;
}

// return the value of the star, in the case of using a pattern .*.
string findStarValue(string pattern, string text)
{
	int index;
	int patternLength;
	int textLength;
	string res;
		
// searching "*"
	index = strpos(pattern, "*");
	if(index == -1)
		return "";
	
	res = substr(text, index);
	
	patternLength = strlen(pattern);
	textLength = strlen(res);
	
	res = substr(res, 0, textLength - patternLength + index + 1);
	
	return res;
}

// replace the star in a pattern using a star
string replaceStar(string pattern, string starValue)
{
	string res;
	
	res = pattern;
	strreplace(res, "*", starValue);
	
	return  res;
}

bool stringMatchPattern(string s, string pattern)
{
	int index;
	string prefix;
	string postfix;
	string foundPostfix;
	
	index = strpos(pattern, "*");
	if(index == -1)
		return s == pattern;
	
	prefix = substr(pattern, 0, index);
	postfix = substr(pattern, index + 1);
	
	if(strpos(s, prefix) != 0)
		return false;
//	DebugN("Prefix match");
//	DebugN("postfix:" + postfix);
//	DebugN("found position postfix : " + strpos(s, postfix));
	
//	DebugN("expected position postfix : " + strlen(s) - strlen(postfix));

	if(strlen(postfix) == 0)
		return true;
	
	foundPostfix = substr(s, strlen(s) - strlen(postfix));
	if(postfix != foundPostfix)
		return false;
	
	return true;

}
