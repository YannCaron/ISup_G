global dyn_string gBytesTable;
global dyn_string gInputCacheNames;
global dyn_string gInputCacheValues;
global dyn_time gOutputChangeTimesCache;
global dyn_dyn_bool gModuleStatus;
global int gErrorsCounter = 0;
global dyn_string gClearCacheOfModules;

global dyn_string gAnalogInputsNamesCache;
global dyn_float gAnalogInputValuesCache;

const int WAGO_US  = 0;
const int WAGO_INI = 1;
const int WAGO_SBY = 2;
const int WAGO_OPS = 3;

const int WAGO_BUS_US = 0;
const int WAGO_BUS_DEG = 1;
const int WAGO_BUS_SBY = 2;
const int WAGO_BUS_OPS = 3;

time largestAccessTime = 0;

void clearCache(string dp)
{
	int index;

	index = dynContains(gInputCacheNames,dp);
	if (index > 0)
	{
// 16.03.2006 aj not removing but setting cache to ""
// more safe as indexes don't get changed
//		dynRemove(gInputCacheNames,index);
//		dynRemove(gInputCacheValues,index);
		gInputCacheValues[index] = "";

	}

	index = dynContains(gAnalogInputsNamesCache,dp);
	if (index > 0)
	{
// 16.03.2006 aj not removing but setting cache to ""
// more safe as indexes don't get changed
//		dynRemove(gAnalogInputsNamesCache,index);
//		dynRemove(gAnalogInputValuesCache,index);
		gAnalogInputValuesCache[index] = "";
	}
}

void connectToClearCacheDPEs()
{
	dpQueryConnectSingle ("clearModuleCache", false, "WAGOClearCache", "SELECT '_online.._value' FROM '*" + WAGO_CLEARCACHE_POSTFIX + "' WHERE _DPT = \"sgWAGOExt\"");

	//dpConnect ("clearModuleCache", false, dpAppend(modules, ".ClearCache"));
}

void clearModuleCache(string ident, dyn_dyn_anytype val)
{

	string dpe;
	bool clear;
	int index;

	// loop on values
	for (int i=2; i<=dynlen(val); i++)
	{
		// get values
		dpe = dpSubStr(val[i][1], DPSUB_DP);
		clear = val[i][2];

		if (clear)
		{
			// add module to clear
			index = dynContains(gClearCacheOfModules, dpe);
			if (index < 1)
				dynAppend(gClearCacheOfModules,dpe);
		}
		else
		{
			// remove module from clear table
			index = dynContains(gClearCacheOfModules, dpe);
			if (index > 0)
				dynRemove(gClearCacheOfModules, index);
		}

	}


//	if (clearCache)
//		dynAppend(gClearCacheOfModules,dpSubStr(dpe,DPSUB_DP));
}

void initModbusLib()
{
	sgDBWaitForInit(); // initialization of the data base (memory caching)

	gErrorsCounter = 0;

	sgDBCreateTable("PENDING_ALARMS");

	gBytesTable = makeDynString(
								"0000",
								"0001",
								"0010",
								"0011",
								"0100",
								"0101",
								"0110",
								"0111",
								"1000",
								"1001",
								"1010",
								"1011",
								"1100",
								"1101",
								"1110",
								"1111");

	dyn_string modules;
	dyn_string busses;
	dyn_string modulesOnBusses;

	dynAppend(modules, getPointsOfType("sgWAGO"));
	dynAppend(modules, getPointsOfType("sgWAGOExt"));
	dynAppend(busses, getPointsOfType("sgWAGOBus"));
	dynAppend(busses, getPointsOfType("sgWAGOBusExt"));

	connectToClearCacheDPEs();

	//DebugN("modules: " + modules);
	//DebugN("busses: " + busses);

	// separate loops because connectWAGOModule takes lot of time
	for(int cpt = 1; cpt <= dynlen(modules); cpt++)
	{

		if(isServerA(getHostname()))
			dpSet(modules[cpt] + ".Status_A", WAGO_US);
		else if(isServerB(getHostname()))
			dpSet(modules[cpt] + ".Status_B", WAGO_US);

		// create the module status, and intialize it
		//dynAppend(gModuleStatus, true);
	}

	// Match each modules with his bus

	for(int cpt = 1; cpt <= dynlen(modules); cpt++)
	{
		string bus;
		int busIndex;

		dpGet(modules[cpt] + ".Bus", bus); // bus of the module

		busIndex = dynContains(busses, bus);

		if(busIndex != 0)
		{
			modulesOnBusses[busIndex] = modulesOnBusses[busIndex] + modules[cpt] + ";";
			sgHistoryAddEvent(modules[cpt] + ".History", SEVERITY_SYSTEM,  "Matching module " + modules[cpt] + " with bus " + busses[busIndex]);
			connectWAGOModule(modules[cpt]);
			sgDBCreateTable(modules[cpt]);

			dyn_string dummy;
			sgDBSet(modules[cpt], "ModeRule", dummy);
			// get mode for the module
			dyn_string names, dpValues;
			for (int x = 1; x <= 32; x++)
			{
				string modeName;
				sprintf(modeName, modules[cpt] + ".AnalogInputs.%03d.Mode", x);
				dynAppend(names, modeName);
			}
			dpGet(names, dpValues);

			for (int x = 1; x <= 32; x++)
			{
				sgDBAppend(modules[cpt], "ModeRule", dpValues[x]);
			}

			// test
			//dyn_string temp = sgDBGet(modules[cpt], "ModeRule");
			// DebugTN("WD: modeRule for inputs are: " + temp);
		}
		else
		{
			sgHistoryAddEvent(modules[cpt] + ".History", SEVERITY_SYSTEM,  "Host: " + getHostname() + " Don't achieve to match any bus to this module");
		}

	} // loop on modules


	//DebugN("busses: " + busses);
	//DebugN("modulesOnBusses: " + modulesOnBusses);

	startThread("expiryChecker");

	for(int cpt = 1; cpt <= dynlen(busses); cpt++)
	{
//		DebugTN("Will start module " + strsplit(modulesOnBusses[cpt], ";"));
		if (dynlen(modulesOnBusses) < cpt)
		{
			DebugTN("WAGO: bus " + busses[cpt] + " has no module declared !");
			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "WAGO: bus " + busses[cpt] + " has no module declared !");
			continue;
		}

		startThread("wagoPollingThread", busses[cpt], cpt, strsplit(modulesOnBusses[cpt], ";"));
	}
} // void initModbusLib()

void wagoPollingThread(string bus, int busIndex, dyn_string modules)
{
	string port;
	string params;
	int baudRate;
	int pollingRate;
	int busState;
	int handle;
	int address;

//	WAGO_BUS_US = 0;
//  WAGO_BUS_DEG = 1;
//  WAGO_BUS_OPS = 3;

	busState = "OPS";

	dpGet(bus + ".Port", port,
			  bus + ".Settings", params,
			  bus + ".BaudRate", baudRate,
			  bus + ".PollingRate", pollingRate);

	 //init modulestatus and addresses
	dyn_int addresses;
	int address;
	for(int cpt = 1; cpt <= dynlen(modules); cpt++)
	{
		gModuleStatus[busIndex][cpt] = true; // initialize the module on the bus
		dpGet(modules[cpt] + ".Address", address);
		dynAppend(addresses, address);
	}

	while(true)
	{

	  handle = v24Open(port, baudRate, params);
	 	if (-1 == handle)
	 	{
			for(int cpt = 1; cpt <= dynlen(modules); cpt++)
			{
				sgHistoryAddEvent(modules[cpt] + ".History", SEVERITY_SYSTEM,  "Host: " + getHostname() + " Unable to have the RS232 handle with port " + port);
				DebugTN("WAGO: unable to open the RS232/485 port, arguments was: \nport: " + port + "\nsettings: " + params + "\nbaudRate: " + baudRate);
			}

			busState = WAGO_BUS_US;
			delay(10,0); // retry every ten seconds
		}
		else
		{
			time startTime;
			time stopTime;
			time delta;

			busState = WAGO_BUS_OPS;
			while(busState != WAGO_BUS_US)
			{
				//DebugN("Start polling bus " + bus);

				startTime = getCurrentTime();
				bool totalOPS = true;
				bool opsReceived = false;
				for(int cpt = 1; cpt <= dynlen(modules); cpt++)
				{
					bool temp;
					temp = WAGOPollModule(modules[cpt], handle, busIndex, cpt, addresses[cpt]);

					if(temp)
						opsReceived = true;
					else
						totalOPS = false;
				}

				if(totalOPS)
				{
					busState = WAGO_BUS_OPS;
				}
				else if(opsReceived)
				{
					busState = WAGO_BUS_DEG;
				}
				else
				{
					busState = WAGO_BUS_US;
				}


				stopTime = getCurrentTime();

				delta = stopTime - startTime;


				int deltaMilli;
				deltaMilli = 1000 * second(delta) + milliSecond(delta);

				if(deltaMilli < pollingRate)
				{
					delay((pollingRate - deltaMilli) / 1000, (pollingRate - deltaMilli) % 1000);
				}
				else
				{
					;
					//DebugN("Bus: " + bus + ": requested rate is " + pollingRate + " but elasped time was " + deltaMilli);
				}

				string activeChain;
				dpGet("FwUtils.Framework.ActiveChain", activeChain);

				if(isServerA(getHostname()))
				{

					if (activeChain == "A")
						dpSet(bus + ".Status_A", busState);
					else
					{
						// script run on A machine but activ chain is B
						if (busState == WAGO_BUS_OPS)
						{
							//DebugN("BUS: server is A but activ chain is B");
							dpSet(bus + ".Status_A", WAGO_BUS_SBY);
						}
						else
						{
						//	DebugN("BUS: server is A, activ chain is B, but busState is: " + busState);
							dpSet(bus + ".Status_A", busState);
						}
					}
				}
				else
				{
					// server is not A
					if(isServerB(getHostname()))
					{
						// DebugN("server is B");

						if (activeChain == "B")
							dpSet(bus + ".Status_B", busState);
						else
						{
							// script run on B machine but activ chain is not B
							if (busState == WAGO_BUS_OPS)
								dpSet(bus + ".Status_B", WAGO_BUS_SBY);
							else
								dpSet(bus + ".Status_B", busState);
						} // activ chain is not B
					} // server is not A
				} // else

				// if the bus us U/S wait longer
				// maybe for future use :-) currently we could miss events during this 10 seconds (not very probable but possible)
				//if (busState == WAGO_BUS_US)
				//	delay(10);

			} // while
		}
		if (handle != -1)
			v24Close(handle);
	} // while
} // void wagoPollingThread(string bus, dyn_string modules)

void connectWAGOModule(string dpName)
{
		if(isServerA(getHostname()))
			dpSet(dpName + ".Status_A", WAGO_INI);
		else if(isServerB(getHostname()))
			dpSet(dpName + ".Status_B", WAGO_INI);

	// output caching system:
	// each output point is connected to the point module.outputChanged
	// Any change of output point run the outputChanged function

	// equal for inputs

	bool outputsEnabled;

	dpGet(dpName + ".OutputsEnabled", outputsEnabled);

	for(int cpt = 1; cpt <= 512; cpt++)
	{
		if(outputsEnabled)
		{
			string output;
			sprintf(output, dpName + ".Outputs.%03d.Value", cpt);
			dpConnect("outputChanged", false,  output);
		}

	}

	string input;
	dyn_string names;
	dyn_string inputs;
	dyn_anytype values;
	for(int cpt = 1; cpt <= 512; cpt++)
	{

		sprintf(input, dpName + ".Inputs.%03d", cpt);

		dynAppend(inputs, input);
		dynAppend(names, input + ".Delay");
		dynAppend(names, input + ".Invert");
	}

	dpGet(names, values);

	for(int cpt = 1; cpt <= dynlen(inputs); cpt++)
	{
		input = inputs[cpt];
	  bool b;
		b = sgDBCreateTable(input);
		if (!b)
		{
			DebugTN("connectWAGOModule: unable to create the table: " + input);
			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "connectWAGOModule: unable to create the table: " + input);
			return;
		}

		b = sgDBSet(input, "DELAY", values[(cpt - 1) * 2 + 1]);

		sgDBSet(input, "INVERT", values[cpt * 2]);

//		DebugN(input + " delay = " + values[(cpt - 1) * 2 + 1] + " invert = " + values[cpt * 2]);

		// dpConnect("inputChanged", false, input + ".RawValue", input + ".Invert", input + ".Delay");

	}

	 // DebugN("End of dpConnect");
	dpSet(dpName + ".OutputsChanged", getCurrentTime());
	// DebugN("dpName: "+ dpName);

	// connect analog inputs
	for(int cpt = 1; cpt <= 32; cpt++)
	{
		string input;
		sprintf(input, dpName + ".AnalogInputs.%03d", cpt);
		dpConnect("analogInputChanged", false, input + ".RawValue", input + ".Y1", input + ".Y2");
	}
}

void analogInputChanged(string rawDpName, float rawDpVal, string Y1Name, float Y1Value, string Y2Name, float Y2Value)
{
	string finalDpName;

	finalDpName = dpSubStr(rawDpName, DPSUB_DP_EL);
	strreplace(finalDpName,".RawValue",".Value");


	float newVal;
	newVal = Y1Value + (Y2Value - Y1Value) * (rawDpVal - 4) / 16;

	// DebugTN("WD: Will set analog value name: " + finalDpName + " with value: " + newVal);
	string moduleName = dpSubStr(finalDpName, DPSUB_DP);
	// DebugTN("WD module dpName: " + moduleName);

	dpSet(finalDpName, newVal);
}

void outputChanged(string dpName, string dpVal)
{
	string WAGOName;

	WAGOName = dpSubStr(dpName, DPSUB_SYS_DP);

	dpSet(WAGOName + ".OutputsChanged", getCurrentTime());
}

string modbusFormatFrame(int address, int function, dyn_int data)
{
	string res;
	string s;


	sprintf(res, ":%02X%02X", address, function);

	int lrc;

	lrc = address + function;

	for(int cpt = 1; cpt <= dynlen(data); cpt++)
	{
		sprintf(s, "%02X", data[cpt]);
		res += s;
		lrc += data[cpt];
	}

	lrc = lrc % 256;
	lrc = 255 - lrc;
	lrc = lrc + 1;
	sprintf(s, "%02X", lrc);
	res += s;

	res += "\r\n";

	return res;
}

bool checkLRC(string modbusRes)
{
	int lrc;
	string lrcRec;
	string lrcCalc;

	//13.04.2005 aj just for trying to make an error
	//string temp = substr(modbusRes,0,50);
	//modbusRes = temp + substr(modbusRes,58); // will not be found by LRC
	//modbusRes = temp + substr(modbusRes,57); // will be found by LRC

	lrcRec = substr(modbusRes, (strlen(modbusRes) - 4), 2);

	for(int cpt = 1; cpt < (strlen(modbusRes) - 4); cpt += 2)
	{
		lrc += hexToInt("00" + substr(modbusRes,cpt,2));
	}

  // DebugTN("lrc int", lrc);

	lrc = lrc % 256;
	lrc = 255 - lrc;
	lrc = lrc + 1;

	// Th.V if lrc is 0..
	if (lrc == 256)
		lrc = 0;

	sprintf(lrcCalc, "%02X", lrc);

	// DebugTN("calculated LRC: ", lrcCalc, "received LRC: ", lrcRec);

	return (lrcCalc == lrcRec);
}


string modbusSendFrame(int handle, string data, string dpName)
{
	string read;
	string res;
	int nbBytes;
	nbBytes = v24Write(handle, data);
	if (nbBytes != strlen(data))
	{
		if (nbBytes == -1)
			sgHistoryAddEvent(dpName + ".History" , SEVERITY_SYSTEM, "Host: " + getHostname() + " dpName: " + dpName + " unable to write to the WAGO bus (dont try to read the response)");
		else
			sgHistoryAddEvent(dpName + ".History" , SEVERITY_SYSTEM, "Host: " + getHostname() + " dpName: " + dpName + " the number of writted bytes is not corresponding to the number sended (dont try to read the response)");

		return "";
	}

	time startTime = getCurrentTime();
	dyn_string rcv;
	while(strpos(res, "\n") == -1)
	{
//		dynClear(rcv);
		delay(0,50);
		int readTimeout;
		readTimeout = 5;
		int status = v24Read(handle, read, readTimeout);
		if (status != 0)
		{
			sgHistoryAddEvent(dpName + ".History" , SEVERITY_SYSTEM, "Host: " + getHostname() + " dpName: " + dpName + " read error");
			return "";
		}

		dynAppend(rcv, read);
		res += read;

		if(getCurrentTime() - startTime > readTimeout + 1)
		{
			sgHistoryAddEvent(dpName + ".History" , SEVERITY_SYSTEM, "Host: " + getHostname() + " dpName: " + dpName + " timeout...");
			return "";
		}

		int seconds = second(getCurrentTime() - startTime);
		int milliseconds = milliSecond(getCurrentTime() - startTime);

		if (getCurrentTime() - startTime > largestAccessTime)
		{
			// DebugTN("WAGO: largest access time is: " + seconds + "." + milliseconds + " (for dpName: " + dpName + ")");
			sgHistoryAddEvent(dpName + ".History" , SEVERITY_SYSTEM, "Host: " + getHostname() + " Largest access time is: " + seconds + "." + milliseconds + " (for dpName: " + dpName + ")");
			largestAccessTime = getCurrentTime() - startTime;
		}

		if (getCurrentTime() - startTime > 1)
		{
			sgHistoryAddEvent(dpName + ".History" , SEVERITY_SYSTEM, "Host: " + getHostname() + " Delta time for reading WAGO: " + seconds + "." + milliseconds + " (dpName is: " + dpName + ")");
		}


	}
	// DebugTN("modbusSendFrame >> receive message in: " + dynlen(rcv) + " parts, taking: " + milliSecond(getCurrentTime() - startTime) + " milliseconds");
	// checkLRC(res);
	return res;
}

bool extractBit(char byte, int bit)
{
	int index;

	switch(byte)
	{
		case '0': index = 0;
			break;
		case '1': index = 1;
			break;
		case '2': index = 2;
			break;
		case '3': index = 3;
			break;
		case '4': index = 4;
			break;
		case '5': index = 5;
			break;
		case '6': index = 6;
			break;
		case '7': index = 7;
			break;
		case '8': index = 8;
			break;
		case '9': index = 9;
			break;
		case 'A': index = 10;
			break;
		case 'B': index = 11;
			break;
		case 'C': index = 12;
			break;
		case 'D': index = 13;
			break;
		case 'E': index = 14;
			break;
		case 'F': index = 15;
			break;
		default:
			return false;
	}

	string s;

	s = gBytesTable[index + 1];
	bool res;

	string s2;
	s2 = s[3 - bit];

	res = s2 == "1";

//	if(res)
//		DebugN("Bit " + bit + " of byte " + byte + " (index: " + index + " ==> " + s + ") is " + s2 + " will return " + res);

	return res;
}

int hexByteToInt(char byteString)
{
	switch(byteString)
	{
		case '0': return 0;
		case '1': return 1;
		case '2': return 2;
		case '3': return 3;
		case '4': return 4;
		case '5': return 5;
		case '6': return 6;
		case '7': return 7;
		case '8': return 8;
		case '9': return 9;
		case 'A': return 10;
		case 'B': return 11;
		case 'C': return 12;
		case 'D': return 13;
		case 'E': return 14;
		case 'F': return 15;
		default:
			return -1;
	}
}

// convert an hex string of two bytes (expressed as 4 chars) to an int (only 12 bits)
int hexToInt(string hexString)
{
	int byte1, byte2, byte3, byte4;
	int result;

	//2005.08.10 aj hexString can be 3 or 4 bytes - for 3 bytes just add a "0"
	while (strlen(hexString) < 4)
	{
		hexString = "0" + hexString;
	}

	// DebugTN("sgFwWAGOLib >> hexToInt: " + hexString);
	byte1 = hexByteToInt(hexString[3]);
	if(byte1 == -1)
		return -1;
	byte2 = hexByteToInt(hexString[2]);
	if(byte2 == -1)
		return -1;
	byte3 = hexByteToInt(hexString[1]);
	if(byte3 == -1)
		return -1;
	byte4 = hexByteToInt(hexString[0]);
	if(byte4 == -1)
		return -1;

	return byte1 + 16 * byte2 + 256 * byte3 + 4096 * byte4;

}

void setModuleToUS(string dpName, string message)
{
		sgHistoryAddEvent(dpName + ".History", SEVERITY_SYSTEM,  message);
		if(isServerA(getHostname()))
			dpSet(dpName + ".Status_A", WAGO_US);
		else if(isServerB(getHostname()))
			dpSet(dpName + ".Status_B", WAGO_US);
}

void setModuleToOPS(string dpName)
{
//		if(isServerA(getHostname()))
//			dpSet(dpName + ".Status_A", WAGO_OPS);
//		else if(isServerB(getHostname()))
//			dpSet(dpName + ".Status_B", WAGO_OPS);
//
		string activeChain;
		dpGet("FwUtils.Framework.ActiveChain", activeChain);

		if(isServerA(getHostname()))
		{
			if (activeChain == "A")
			{
				// DebugN("WAGO: server is A and activ chain is A");
				dpSet(dpName + ".Status_A", WAGO_OPS);
			}
			else
			{
				// script run on A machine but activ chain is B
				// DebugN("WAGO: server is A but activ chain is B");
				dpSet(dpName + ".Status_A", WAGO_SBY);
			}
		}
		else
		{
			// server is not A
			if(isServerB(getHostname()))
			{
				if (activeChain == "B")
				{
					// DebugN("WAGO: server is B and activ chain is B");
					dpSet(dpName + ".Status_B", WAGO_OPS);
				}
				else
				{
					// script run on B machine but activ chain is not B
					dpSet(dpName + ".Status_B", WAGO_SBY);
					// DebugN("WAGO: server is B but activ chain is A");
				} // server is not A
			}
		} // else
} // void setModuleToOPS(string dpName)

void expiryChecker()
{
	while(true)
	{
		dyn_string keys;
		dyn_string ds;
		time expiry;
		time currentTime;

		currentTime = getCurrentTime();

		keys = sgDBTableKeys("PENDING_ALARMS");
		for(int cpt = 1; cpt <= dynlen(keys); cpt++)
		{
			ds = sgDBGet("PENDING_ALARMS", keys[cpt]);
			expiry = ds[1];

			if(expiry < currentTime)
			{
				// alarm still present after expiry, set DP to false
				dpSet(keys[cpt] + ".Value", false);
				sgDBRemove("PENDING_ALARMS", keys[cpt]);
			}
		}
		delay(0,200);
	}
}

bool checkModbusResponse(string modbusRes, string address, string function,  string dpName)
{
	//DebugTN("checkModbusResponse: ", modbusRes);
	if(modbusRes == "")
	{
		gErrorsCounter++;
		sgHistoryAddEvent(dpName + ".History", SEVERITY_SYSTEM, "Host: " + getHostname() + " No response from module address: " + address + " nb errors from statup of the manager: " + gErrorsCounter);
		return false;
	}

	string expectedPrefix;
	// string function = substr(modbusRe,3,2);

	int expectedLength;
	string tail;
	// function code 0x0F = 15 = digital output
	if (function == "0F")
	{
	  expectedLength = 17;
	  tail = "00";
	}
	else
	{
		expectedLength = 139;
		tail = "40";
	}

  // sprintf(expectedPrefix, ":%02d" + function + "40", address);

	// 29.06.2005 aj changed %02d to %02X as hex numbers have to be used (for writing this has been like this already)
	sprintf(expectedPrefix, ":%02X%s%s", (int)address, function, tail);


	// DebugTN("checkModbusResponse: ", expectedPrefix);
	if(strpos(modbusRes, expectedPrefix) != 0)
	{
		gErrorsCounter++;
		sgHistoryAddEvent(dpName + ".History", SEVERITY_SYSTEM, "Host: " + getHostname() + " Invalid header received from module address: " + address + " dpName: " + dpName + " function: " + function + " expected: " + expectedPrefix + " received: " + substr(modbusRes, 0, 7) +
		                                       " nb errors from statup of the manager: " + gErrorsCounter);
		return false;
	}

	if (!checkLRC(modbusRes))
  {
		gErrorsCounter++;
		sgHistoryAddEvent(dpName + ".History", SEVERITY_SYSTEM, "Host: " + getHostname() + "  received from module address: " + address + " dpName: " + dpName + " function: " + function + " modbus response length: " + strlen(modbusRes) + " modbusResponse: " + modbusRes +
		                                       " nb errors from statup of the manager: " + gErrorsCounter);
		return false;
	}

	if (strlen(modbusRes) != expectedLength)
	{
		gErrorsCounter++;
		sgHistoryAddEvent(dpName + ".History", SEVERITY_SYSTEM, "Host: " + getHostname() + " Incorrect message length received from module address: " + address + " dpName: " + dpName + " function code: " + function + " expected: " + expectedLength + " received: " + strlen(modbusRes) +
		                                       " nb errors from statup of the manager: " + gErrorsCounter);
	  return false;
	}
	return true;
}

bool WAGOPollModule(string dpName, int handle, int busIndex, int moduleNumber, int address)
{
	// int address;
	string frame;
	// dpGet(dpName + ".Address", address);
	string modbusRes;
	int cacheIndex;
	string cacheString;
	int res;

	time startTime;
	time now;
	int deltaTime;

	bool isClear;

	if (dynContains(gClearCacheOfModules,dpName) > 0)
	{
		clearCache(dpName);
		dpSet(dpName + WAGO_CLEARCACHE_POSTFIX, FALSE);
	}



	startTime = getCurrentTime();

	// get the digital inputs
	string function = "01";
	frame = modbusFormatFrame(address, function, makeDynInt(0, 0, 2, 0));

//	DebugN("Get inputs frame: " + frame);

	cacheString = "";
	cacheIndex = dynContains(gInputCacheNames, dpName);

	modbusRes = modbusSendFrame(handle, frame, dpName);

	//13.04.2005 aj just for trying to make an error
	//string temp = substr(modbusRes,0,50);
	//modbusRes = temp + substr(modbusRes,58); // will not be found by LRC
	//modbusRes = temp + substr(modbusRes,57); // will be found by LRC


	bool res = checkModbusResponse(modbusRes, address, function,  dpName);

  if (res == false)
  {
  	if (gModuleStatus[busIndex][moduleNumber])
  	{
  		gModuleStatus[busIndex][moduleNumber] = false;
			sgHistoryAddEvent(dpName + ".History" , SEVERITY_SYSTEM, "Host: " + getHostname() + " address: " + address + " single error is neglected, stay OPS, dpName is: " + dpName + " module is: " + moduleNumber);
			sgHistoryAddEvent(dpName + ".History" , SEVERITY_SYSTEM, "Host: " + getHostname() + " error caused by message: " + modbusRes);
		  return true;
		}
  	else
  	{
  		setModuleToUS(dpName, "Host: " + getHostname() + " address: " + address + " repeated errors found will turn modbus interface to U/S, dpName is: " + dpName + " module is: " + moduleNumber);
  	  return false;
  	}
  }
  else
  {
		if (gModuleStatus[busIndex][moduleNumber] == false)
		{
			sgHistoryAddEvent(dpName + ".History" , SEVERITY_SYSTEM, "Host: " + getHostname() + " address: " + address + " Will reset status flag for dpName: " + dpName + " module: " + moduleNumber);
			gModuleStatus[busIndex][moduleNumber] = true;  // reset
		}
	}

	if(cacheIndex != 0)
	{
		cacheString = gInputCacheValues[cacheIndex];
	}

	// DebugTN("Received inputs digital: " + modbusRes);

	if(cacheString != modbusRes)
	{
		// DebugN("sgFwWAGOLib: inputs string changed");
		if(cacheIndex == 0)
		{
			dynAppend(gInputCacheNames, dpName);
			dynAppend(gInputCacheValues, modbusRes);
			dynAppend(gOutputChangeTimesCache, 0);
			//sgHistoryAddEvent(dpName + ".History", SEVERITY_SYSTEM, "address: " + address + " modbusRes length: " + strlen(modbusRes));
		}
		else
		{
			gInputCacheValues[cacheIndex] = modbusRes;
		}
		// parse and set the database
		dyn_string inputNames;
		dyn_bool inputValues;
		dyn_bool bits;
		string inputName;


		// DebugTN("sgFwWAGO: CacheString: " + cacheString);


		for(int cpt = 7; cpt <= strlen(modbusRes) - 5; cpt++) // -5 to remove CRC and CRLF
		{
			if((cacheString == "") || (cacheString[cpt] != modbusRes[cpt]))
			{
				int firstBitIndex;
				int offset;

				offset = cpt - 7;

				if((offset % 2) == 0)  // even
				{
					firstBitIndex = offset * 4 + 5;
				}
				else // odd
				{
					firstBitIndex = offset * 4 - 3;
				}

				// DebugN("First impacted bit: " + firstBitIndex);
				for(int bitCpt = 0; bitCpt < 4; bitCpt++)
				{
					sprintf(inputName, dpName + ".Inputs.%03d", firstBitIndex + bitCpt);
					dynAppend(inputNames, inputName);

					int bitIndex;

					bitIndex = (firstBitIndex + bitCpt - 1) % 4;
					dynAppend(inputValues, extractBit(modbusRes[cpt], bitIndex));
				}
			}
		}

		for (int cpt = 1; cpt <= dynlen(inputNames); cpt++)
		{
			string tableName;
			dyn_string ds;
			int delayTime;

			tableName = inputNames[cpt];

			ds = sgDBGet(tableName, "INVERT");

			bool b, value;
			b = ds[1];

			if (b)
				value = !inputValues[cpt];
			else
				value =	inputValues[cpt];

			if(value) // no delay if new status is TRUE
			{
				dpSet(tableName + ".Value", value);
				dyn_string pending;

				pending = sgDBTableKeys("PENDING_ALARMS");
				if(dynContains(pending, tableName))
				{
					sgDBRemove("PENDING_ALARMS", tableName);
				}
			}
			else
			{
				ds = sgDBGet(tableName, "DELAY");
				delayTime = ds[1];
				if(delayTime == 0)
				{
					dpSet(tableName + ".Value", value);
				}
				else
				{
					string expiry;
					time expiryTime;

					expiryTime = getCurrentTime() + delayTime;
					expiry = expiryTime;
					sgDBSet("PENDING_ALARMS", tableName, expiry);
				}
			}
		}
	//	DebugN("dpSet of " + dynlen(inputNames) + " values returned " + res);
		//DebugN("Set " + dynlen(inputNames) + " digital inputs");
	}



	now = getCurrentTime();
	deltaTime = milliSecond(now - startTime);
// 	DebugN("sgFwWAGOLib: time after digital inputs: " + deltaTime);
	startTime = getCurrentTime();


	// Analogue inputs
	function = "03";
	frame = modbusFormatFrame(address, function, makeDynInt(0, 0, 0, 32));
	modbusRes = modbusSendFrame(handle, frame, dpName);

	//13.04.2005 aj just for trying to make an error
	//strreplace(modbusRes, ":","0");
	// DebugTN("sgFwWAGOLib: modbusRes with analog function: " + modbusRes);


	res = checkModbusResponse(modbusRes, address, function, dpName);

  if (res == false)
  {
  	DebugTN("sgFwWAGOLib: lrc incorrect for analog function");
  	if (gModuleStatus[busIndex][moduleNumber])
  	{
  		gModuleStatus[busIndex][moduleNumber] = false;
			sgHistoryAddEvent(dpName + ".History" , SEVERITY_SYSTEM, "Host: " + getHostname() + " address: " + address + " dpName: " + dpName + " Single error is neglected, stay OPS, busIndex (not COM port) is: " + busIndex + " module is: " + moduleNumber);
			sgHistoryAddEvent(dpName + ".History" , SEVERITY_SYSTEM, "Host: " + getHostname() + " lengh of message: " + strlen(modbusRes) + " Error caused by message: " + modbusRes);
  	  return true;
  	}
  	else
  	{
  		setModuleToUS(dpName, "Host: " + getHostname() + " address: " + address + " dpName: " + dpName + " Repeated errors found will turn modbus interface to U/S, busIndex (not COM port) is: " + busIndex + " module is: " + moduleNumber);
  	  return false;
  	}
  }
  else
		if (gModuleStatus[busIndex][moduleNumber] == false)
		{
			sgHistoryAddEvent(dpName + ".History" , SEVERITY_SYSTEM, "Host: " + getHostname() + " address: " + address + " dpName: " + dpName + " Will reset status flag busIndex (not COM port): " + busIndex + " module: " + moduleNumber);
			gModuleStatus[busIndex][moduleNumber] = true;  // reset
		}

	// DebugN("sgFwWagoLib: modbus response for analog inputs: " + modbusRes);

	// DebugTN("Received inputs analog: " + modbusRes);

	// parse and set the database
	dyn_string inputNames;
	dyn_int inputValues;
	dyn_int bits;
	string inputName;

	dyn_string analogInputNames;
	dyn_float analogInputValues;

	// get the analog rule
	dyn_string rules = sgDBGet(dpName, "ModeRule", rules);
	// DebugTN;
	// DebugTN("WD Analogs Rules: " + rules);

	for(int cpt = 1; cpt <= 32; cpt++)
	{
		sprintf(inputName, dpName + ".AnalogInputs.%03d.RawValue", cpt);

		string valueString;

		//valueString = substr(modbusRes, 6 /*7*/ + 4 * (cpt - 1), 4);
		valueString = substr(modbusRes, 7 + 4 * (cpt - 1), 4);

		string rule = rules[cpt];
		// DebugTN("WD: rule: " + rule);

		int value;
		float analogValue, level;

		if (rule == "PT100")
		{
			level = 0.5;
			// checking if "loop open"
			if (valueString == "2134")
			{
				analogValue = -99;
				// DebugTN("PT100, open loop, set to -99");
			}
			else
			{
				value = hexToInt(valueString);
				analogValue = AnalogConvPT100(value);
			}
		}
		else
		{
			level = 0.1;
			char status = valueString[3];
			// DebugTN("WD status for analog (4-20): " + cpt + " is: " + status);
			// checking status if "loop open"
			if (status == "3")
			{
				analogValue = -1;
				// DebugTN("4-20, open loop, set to -1");
			}
			else
			{
				// for analog inputs the fourth byte is the status - the value is only the first 12 bits
				value = hexToInt(substr(valueString,0,3));
				analogValue = AnalogConv4_20(value);
				// DebugTN("WD 4-20 hex value: " + valueString + " int value: " + analogValue);
			}
		}
	 // 	DebugN("WD: analog value for input from the vago: " + cpt + " is: " + value + " analog value after the rule is: " + analogValue);

		int analogCacheIndex;
		bool analogAddValue = false;

		analogCacheIndex = dynContains(gAnalogInputsNamesCache, inputName);
		if(analogCacheIndex == 0)
		{
			dynAppend(gAnalogInputsNamesCache, inputName);
			dynAppend(gAnalogInputValuesCache, analogValue);
			analogAddValue = true;
		}
		else
		{
			analogValue = smooth(analogValue, gAnalogInputValuesCache[analogCacheIndex], level);

			if(analogValue != gAnalogInputValuesCache[analogCacheIndex])
			{
				// DebugTN("sgFwWAGOLib: cached value was: " + gAnalogInputValuesCache[analogCacheIndex] + " and new value is " + analogValue);
				gAnalogInputValuesCache[analogCacheIndex] = analogValue;
				analogAddValue = true;
			}
		}

		if(analogAddValue)
		{
			// DebugN("sgFwWAGOLib: analog value " + cpt + " changed");
			dynAppend(analogInputNames, inputName);
			dynAppend(analogInputValues, analogValue);
		}

//		if(cpt == 1)
//		{
//			DebugN("sgFwWagoLib: analog input " + cpt + " has milliAmps value " + milliAmpsValue + " after rounding");
//		}
	}
	// DebugTN("WD: Will set: " + analogInputNames + " with values: " + analogInputValues);
	dpSet(analogInputNames, analogInputValues);

	// DebugN("Set " + dynlen(analogInputNames) + " analog inputs");


	now = getCurrentTime();
	deltaTime = milliSecond(now - startTime);
	// DebugN("sgFwWAGOLib: time after analogue inputs: " + deltaTime);
	startTime = getCurrentTime();

	// Logical outputs

	bool processOutputs = false;
	time outputsChanged;
	bool outputsEnabled;
	dpGet(dpName + ".OutputsChanged", outputsChanged,
				dpName + ".OutputsEnabled", outputsEnabled);

	if(outputsEnabled)
	{

		cacheIndex = dynContains(gInputCacheNames, dpName);

		if(cacheIndex == 0)
		{
			// DebugN("sgWAGOLib: cache index = 0 for outputs processing of module " + dpName + ". Should never happend");
			setModuleToUS(dpName, "No cache found, should never happend");
			if(cacheIndex != 0)
			{
	//			gInputCacheValues[cacheIndex] = "";
	//			gOutputChangeTimesCache[cacheIndex] = 0;
			}

			return false;
		}
		else
		{
			time cachedOutputsChanged;
			cachedOutputsChanged = gOutputChangeTimesCache[cacheIndex];
			if(outputsChanged > cachedOutputsChanged)
			{
				gOutputChangeTimesCache[cacheIndex] = outputsChanged;
				processOutputs = true;
			}
		}

		if(processOutputs)
		{
			// DebugN("Process outputs for module " + dpName);
			// get the outputs
			dyn_string outputNames;
			dyn_anytype outputValues;
			string outputName;

			for(int cpt = 1; cpt <= 512; cpt++)
			{
				sprintf(outputName, dpName + ".Outputs.%03d.Value", cpt);
				dynAppend(outputNames, outputName);
			}

			res = dpGet(outputNames, outputValues);

		//	DebugN("dpGet of " + dynlen(outputNames) + " values returned " + res);

			// build the set string
			dyn_string data;
			data = makeDynString(0, 0, 2, 0, 64); // set 512 bits in 64 bytes

			for(int cpt = 1; cpt <= 64; cpt ++)
			{
				// append byte for bits cpt * 8 -> cpt * 8 + 8
				int byte;

				byte =   1 * outputValues[8 * cpt - 7] +
							   2 * outputValues[8 * cpt - 6] +
							   4 * outputValues[8 * cpt - 5] +
							   8 * outputValues[8 * cpt - 4] +
							  16 * outputValues[8 * cpt - 3] +
							  32 * outputValues[8 * cpt - 2] +
							  64 * outputValues[8 * cpt - 1] +
							 128 * outputValues[8 * cpt - 0];
				dynAppend(data, byte);
			}

			// append the 64 bytes from the outputs

			frame = modbusFormatFrame(address, 15, data);

	//		DebugN(frame);

			modbusRes = modbusSendFrame(handle, frame, dpName);

			// DebugTN("sgFWWagoLib, sentframe:", frame, "receivedframe:", modbusRes);

			res = checkModbusResponse(modbusRes, address, "0F",  dpName);

// replacing the block below to be "safe" and not miss anything
		  if (res == false)
		  {
	  		setModuleToUS(dpName, "Host: " + getHostname() + " address: " + address + " repeated errors found will turn modbus interface to U/S, busIndex (not COM port) is: " + busIndex + " module is: " + moduleNumber);
			  return false;
			 }
/* for safety reasons when writing there is no error tolerated
		  if (res == false)
		  {
		  	if (gModuleStatus[busIndex][moduleNumber])
		  	{
		  		gModuleStatus[busIndex][moduleNumber] = false;
					sgHistoryAddEvent(dpName + ".History" , SEVERITY_SYSTEM, "Host: " + getHostname() + " address: " + address + " single error, stay OPS, busIndex (not COM port) is: " + busIndex + " module is: " + moduleNumber);
					sgHistoryAddEvent(dpName + ".History" , SEVERITY_SYSTEM, "Host: " + getHostname() + " error caused by message: " + modbusRes);
					// write to OutputsChanged to have another try in the next loop
					dpSet(dpName + ".OutputsChanged", getCurrentTime());
		  	  return true;
		  	}
		  	else
		  	{
		  		setModuleToUS(dpName, "Host: " + getHostname() + " address: " + address + " repeated errors found will turn modbus interface to U/S, busIndex (not COM port) is: " + busIndex + " module is: " + moduleNumber);
		  	  return false;
		  	}
		  }
		  else
				if (gModuleStatus[busIndex][moduleNumber] == false)
				{
					sgHistoryAddEvent(dpName + ".History" , SEVERITY_SYSTEM, "Host: " + getHostname() + " address: " + address + " Will reset status flag, busIndex (not COM port) is: " + busIndex + " module is: " + moduleNumber);
					gModuleStatus[busIndex][moduleNumber] = true;  // reset
				}
				//	DebugN("Answer to set outputs: " + modbusRes);
*/

	 }
	} // outputs enabled
	now = getCurrentTime();
	deltaTime = milliSecond(now - startTime);
	// DebugN("sgFwWAGOLib: time after digital outputs: " + deltaTime);

	setModuleToOPS(dpName);
	return true;
} // bool WAGOPollModule(string dpName, int handle)

float AnalogConv4_20(float value)
{
	// conversion to milliAmps
		return value / 128.0 + 4;
}

float smooth(float input, float cachedValue, float level)
{
	if (fabs(input - cachedValue) > level)
	{
		return input;
	}
	else
		return cachedValue;
}

float AnalogConvPT100(float rawValue)
{
	return rawValue / 10;
}

void wagoForceToUnknown(string systemName, string name)
{

		dyn_string connections;
		dyn_string names, dpes;
		string cash, oldCash, refName;
		string connectionsDpe, historyDpe;

		// 20060927 aj dpGetDpFromType doesn't work for remote systems!!!!!!!
		if (systemName == getSystemName())
		{
			// get connection dpe
			connectionsDpe = dpGetDpFromType(systemName + name, "sgFwConnections");
			historyDpe = dpGetDpFromType(systemName + name, "sgFwHistory");
		}
		else
		{
			dpes = dpNames(systemName + name + ".*"); // only search in one level - faster as connections and history should be only in this level
			for (int i = 1; i <= dynlen(dpes); i++)
				{
					refName = dpTypeRefName(dpes[i]);
					if (refName == "sgFwConnections")
						connectionsDpe = dpes[i];
					else if (refName == "sgFwHistory")
						historyDpe = dpes[i];
				}
		}

		// get connections
		dpGet(connectionsDpe + INPUTS_POSTFIX, connections);
		names = getPointsFromPattern(systemName + patternConcat(connections));

		for(int i=1; i<=dynlen(names); i++)
		{

			dpSet(names[i], -1);
			cash = dpSubStr(names[i], DPSUB_DP);

			if (cash != oldCash)
				dpSet(systemName + cash + ".ClearCache", TRUE);

		}

		sgHistoryAddEvent(historyDpe, SEVERITY_COMMAND, "<<Force to UKN>> sent");

		//20060619 aj added for PVSS Dole
		//DebugTN(systemName + name + ".DoleGlobalStatus",dpExists(systemName + name + ".DoleGlobalStatus"));
		if (dpExists(systemName + name + ".DoleGlobalStatus"))
			sgHistoryAddEvent(systemName + "DoleHistory", SEVERITY_COMMAND, dpGetDescription(systemName + name + ".GlobalStatus") + ": User pushed the 'force to UKN' button");

}
