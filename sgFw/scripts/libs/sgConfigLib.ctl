const string CONFIG_LIB = "sgConfigLib";
const string CONFIG_FILENAME = "sgConfig";
const string CONFIG_COMMENT_CHAR = "#";
const string CONFIG_EOL_CHAR = "\n";
const string CONFIG_SEPARATOR_CHAR = "\t";
const string NULL = "";
dyn_string configKeys, configValues;

void loadConfig() {
  file f;
  int i = 1, pos, fok;
  string filename, line, name, value;
  
  filename = getPath(CONFIG_REL_PATH + CONFIG_FILENAME);
 	fok = access(filename, F_OK);
  
  if (fok != 0) {
  	DebugTN(CONFIG_LIB + ".loadConfig() : File [" + filename + "] doesn't exist! ");
    exit;    
  }            
        
	f = fopen(filename, "r");
  
	while(i != EOF && i != 0) {
    i = fgets(line, 255, f);
		
    strreplace(line, CONFIG_EOL_CHAR, "");
    pos = strpos(line, CONFIG_SEPARATOR_CHAR + CONFIG_COMMENT_CHAR);
    if (pos == -1) pos = strpos(line, CONFIG_COMMENT_CHAR);
    if (pos != -1) {
      line = substr(line, 0, pos);
    }
    
    if (line != "") {
      	pos = strpos(line, CONFIG_SEPARATOR_CHAR);
      	name = substr(line, 0, pos);
	value = substr(line, pos);
	value = strltrim(value);
	value = strrtrim(value);
                        
      	dynAppend(configKeys, name);
      	dynAppend(configValues, value);
    }
  }
  fclose(f);
}

string getConfigValue(string name) {
  // lazy initialization
  if (dynlen(configKeys) == 0) {
		loadConfig();
  }
  
  int index = dynContains(configKeys, name); 
  if (index > 0) {
    return configValues[index];
  } else {
    DebugTN(CONFIG_LIB + ".getConfigValue() : Key [" + name + "] does not exist in file [" + CONFIG_FILENAME + "]");
    return NULL;
  }
}

bool isLinux() {
	string os = getConfigValue ("OS");
	return (strtoupper(os) == "LINUX");
}

string getPathSeparator () {
  if (isLinux()) {
    return "/";
  } else {
    return "\\";
  }
}
