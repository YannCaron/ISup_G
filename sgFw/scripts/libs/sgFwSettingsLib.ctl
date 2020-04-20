public string SETTINGS_PATH = isLinux() ? "/project/settings" : "E:/settings";
public const string SETTINGS_FORMAT_FILE_NAME = "%s/%s.%s.xml";

public string getFileName(string systemName, string controlName) {
  string fileName;
  sprintf(fileName, SETTINGS_FORMAT_FILE_NAME, SETTINGS_PATH, systemName, controlName);
	return fileName;
}

public void saveXMLSettings(string systemName, string controlName, string xml) {
  string fileName = getFileName(systemName, controlName);
	if (!isdir(SETTINGS_PATH)) mkdir(SETTINGS_PATH, 777);
  file f;
  int err;
  f = fopen(fileName, "w+");
  err = ferror(f);
  if (err!=0) {
    DebugN("Error no. ",err," occurred");
    return;
  }
  
  fputs(xml, f);
  fclose(f);
}

public string loadXMLSettings(string systemName, string controlName) {
  string fileName = getFileName(systemName, controlName);
	if (!isfile(fileName)) return "";
  
  string xml;
  fileToString(fileName, xml);
  return xml;
}
