
// The main goal is when no traps are received between 2 minutes the state of the automatic eraser bloc must be turned to OPS
// If the clock is turned to UKN because the watchdog expired, the automatic eraser must be turned off to
// This last functionality is realized by a frame work watch dog.

const string RRR_A = "RRR_A";
const string RRR_B = "RRR_B";

// Record from the dpQueryConnectAll
const int RECORD_NAME  = 1;
const int RECORD_VALUE = 2;
const int RECORD_TIME  = 3;

// dyn_int returned by the function returnLastUpdate
const int LAST_TIME	   = 1;
const int LAST_VALUE   = 2;

const int WATCH_DOG	= 120;

dyn_int returnLastUpdate(string dp, dyn_dyn_anytype valueTable)
{
	// the function return a dyn_int: pos 1 is the last time update and pos 2 is the last value updated
	dyn_int dn;
	dn[LAST_TIME] = 0;
	time lastTime = 0;
	
	for (int id = 2; id <= dynlen(valueTable); id++)
	{
		if (strpos((string)valueTable[id][RECORD_NAME], dp) > 0)
		{
			if (valueTable[id][RECORD_TIME]	> lastTime)
			{
				lastTime = valueTable[id][RECORD_TIME];
				dn[LAST_VALUE] = valueTable[id][RECORD_VALUE];
			}
		}
	}
	dn[LAST_TIME] = lastTime;
	// DebugTN("sgRecording >> returnLastUpdate dn: " + dn);
	return dn;
}

void sgRecordingTrapReceive(string recordingChain, int rr, int dd)
{
// DebugTN("sgRecording >> traps receive for chain:" + recordingChain + " rr: " + rr + " dd: " + dd);
 dpSet("Recording.RawData." + recordingChain + ".AutomaticEraser.SubstractionResult", dd-rr);
}


//Function Button1_EventClick()

main()
{

	dpQueryConnectAll("sgRecordingWriteSubstractionResult",RRR_A,"SELECT '_online.._value', '_online.._stime' FROM '{Recording.RawData.RRR_A.ClockStatus,Recording.RawData.RRR_A.AutomaticEraser.dd,Recording.RawData.RRR_A.AutomaticEraser.rr}'",1000);
	dpQueryConnectAll("sgRecordingWriteSubstractionResult",RRR_B,"SELECT '_online.._value', '_online.._stime' FROM '{Recording.RawData.RRR_B.ClockStatus,Recording.RawData.RRR_B.AutomaticEraser.dd,Recording.RawData.RRR_B.AutomaticEraser.rr}'",1000);

}

void sgRecordingWriteSubstractionResult(string ident, dyn_dyn_anytype valueTable)
{
	dyn_int rr, dd, clock;
	
	// DebugTN("sgRecordingWriteSubstractionResult >>",valueTable);

	// as we have a blocking time we can get the three DPEs several time
	// therefore get the latest values for all three
	// seach the last update for rr chain A
	
	rr    = returnLastUpdate("Recording.RawData." + ident + ".AutomaticEraser.rr", valueTable);
	dd    = returnLastUpdate("Recording.RawData." + ident + ".AutomaticEraser.dd", valueTable);
	clock = returnLastUpdate("Recording.RawData." + ident + ".ClockStatus", valueTable);

	// DebugTN(valueTable);	
	
	// DebugTN("sgRecordingWriteSubstractionResult >>",valueTable[2][1]);
	
	// check if dd and rr have been updated within the last 2 minutes
	// if they got updated (meaning a trap arrived) write the substraction value to the substractionResult
	
	// else, if they didn't get updated write a value which means OPS to the substractionResult
	
	time currentTime = getCurrentTime();
		// 
	if ((currentTime - clock[LAST_TIME]) < 30)
	{	

//		DebugTN("sgRecording clock is updated");

		if (clock[LAST_VALUE] == 0)
		{
			// -1000 corresponds to UKN in the conversion table
//			DebugTN("sgRecording >> clock is UKN, will turn automatic eraser to UKN");
			dpSet("Recording.RawData." + ident + ".AutomaticEraser.SubstractionResult", -1000);
		}
		else if ((currentTime - rr[LAST_TIME]) < WATCH_DOG && (currentTime - dd[LAST_TIME]) < WATCH_DOG)
		{
			sgRecordingTrapReceive(ident, rr[LAST_VALUE], dd[LAST_VALUE]);	
		}
		else if ((currentTime - rr[LAST_TIME]) > WATCH_DOG && (currentTime - dd[LAST_TIME]) > WATCH_DOG)
		{
			// the state corresponding to the value -1 is ops
//			DebugTN("sgRecording >> will turn the chain: " + 	ident + " to ops");
			dpSet("Recording.RawData." + ident + ".AutomaticEraser.SubstractionResult", -1);
		}
	}
	else
	{
		int currentTimeint = currentTime;
//		DebugTN("sgRecording >> clock is out of date, currentTime: " + currentTimeint + " clockTime: " + clock[LAST_TIME] + " age is:" + (currentTimeint - clock[LAST_TIME]));
	}
}

