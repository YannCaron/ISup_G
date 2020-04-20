void launchEmradioSNMPSet() {
  string log4jconfigPath = getPath(CONFIG_REL_PATH, "emradio.log4j.properties");
  string emradioconfigPath = getPath(CONFIG_REL_PATH, "emradio.config.xml");
  string jarPath = getPath(BIN_REL_PATH, "EmradioSNMPSet.jar");
  string command;

  if (isLinux()) {
    sprintf(command, "java -jar \"%s\" -l \"%s\" -c \"%s\"", jarPath, log4jconfigPath, emradioconfigPath); 
  } else {
    sprintf(command, "start cmd /k 'java -jar \"%s\" -l \"%s\" -c \"%s\"'", jarPath, log4jconfigPath, emradioconfigPath); 
  }

  while (true) {
    DebugTN("Shell launch: " + command);
    system(command);
    delay(10);
  }

}

main () {

  startThread("launchEmradioSNMPSet");
  
}

