const string SERVICE_REL_PATH = "services/";

string tryConf(string arg) {
	string path = arg;
	if (!patternMatch("-*", arg)) {
		string p = getPath(CONFIG_REL_PATH, arg);
		if (p != "") path = p;
	}
	return path;
}

void connectionMonitor(int port) {

	int tries = 1;
	string data = "";
	while (data == "") {
		DebugTN("Try to establish connection [" + tries + "] with connectionMonitor at 127.0.0.1:" + port);
		int socket = tcpOpen("127.0.0.1", port, 0.5);
		int read = tcpRead(socket, data, 1); 

		tries++;
		if (tries > 15) {
			DebugTN("ServiceLauncher was unable to establish connection with connectionMonitor at 127.0.0.1:" + port);
			DebugTN("WARNING: Service will not be stopped automatically with CtrlManager.");
			break;
		};
	}

}

main(string type, string fileName, ...) {
	string path = getPath(SERVICE_REL_PATH, fileName);
	string cmd;
	int port = 9900 + myManNum();

	if (type == "jar") {
		cmd = "java -jar " + path;
	} else {
		cmd = path;
	}

	// read parameters
	va_list parameters;
	int len = va_start(parameters);  
	for (int i = 1; i <= len; i++) {
		cmd += " " + tryConf(va_arg(parameters));
	}
	va_end(parameters);
	cmd += " -m " + port;

	cmd = "start \"" + fileName + "\" /WAIT " + cmd + "";

	int threadId = startThread("connectionMonitor", port);

	DebugTN("Launching [" + cmd + "]");
	int res = system(cmd);

	DebugTN("Service stopped");
	stopThread(threadId);
}