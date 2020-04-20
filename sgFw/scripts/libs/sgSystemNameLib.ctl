const char SYSTEM_NAME_DELIMITER = '-';
const string SYSTEM_NAME_FORMAT = "%s-%s-%s";

dyn_string sysnSplitParts(string complete) {
  return strsplit (complete, SYSTEM_NAME_DELIMITER);
}

string sysnGetCompleteName (string name, string site, string machine) {
  
  string value;
  sprintf(value, SYSTEM_NAME_FORMAT, name, site, machine);
  return value;
  
}

string sysnGetPart(string complete, int i) {
  dyn_string result = sysnSplitParts (getHostname());
  
  if (dynlen(result) >= i) {
    return result [i];
  } else {
    return "";
  }
  
}

string sysnGetHostName () {
  
  return sysnGetPart (getHostname(), 1);
  
}

string sysnGetHostSite () {
  
  return sysnGetPart (getHostname(), 2);
  
}

string sysnGetHostMachine () {
  
  return sysnGetPart (getHostname(), 3);
  
}
