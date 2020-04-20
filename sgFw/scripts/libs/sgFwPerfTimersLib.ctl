global dyn_time times;
global dyn_string names;

void timerStart(string name, string history)
{
	int index;
	time startTime;
	string stringStartTime;

	startTime =	getCurrentTime();
	stringStartTime = startTime;

//	DebugN("timerStart: startTime for " + name + ": " + stringStartTime);
//	historyAddEvent(history, "timerStart: startTime for " + name + ": " + stringStartTime);

	index = dynContains(names, name);

	if(index != 0)
	{
		times[index] = startTime;
	}
	else
	{
		dynAppend(names, name);
		dynAppend(times, startTime);
	}
}
void timerStop(string name, string history)
{
	int index;
	time stopTime;
	time startTime;
	time deltaTime;
	string deltaTimeString;

	stopTime =	getCurrentTime();

	index = dynContains(names, name);

	if(index != 0)
	{
		startTime = times[index];
		deltaTime = stopTime - startTime;

		if(hour(deltaTime) < 10)
			deltaTimeString = "0";
		deltaTimeString += hour(deltaTime) + ":";

		if(minute(deltaTime) < 10)
			deltaTimeString += "0";
		deltaTimeString += minute(deltaTime) + ":";

		if(second(deltaTime) < 10)
			deltaTimeString += "0";
		 deltaTimeString += second(deltaTime) + ":";

		 if(milliSecond(deltaTime) < 100)
		 {
		 	if(milliSecond(deltaTime) < 10)
		 		deltaTimeString += "00";
		 	else
		 		deltaTimeString += "0";
		 }
		deltaTimeString += milliSecond(deltaTime);

//		DebugN("timerStop: deltaTime for " + name + ": " + deltaTimeString);
		sgHistoryAddEvent(history, SEVERITY_SYSTEM, "Time for " + name + ": " + deltaTimeString);
		dynRemove(names, index);
		dynRemove(times, index);
	}
	else
	{
//		DebugN("Timer:  " + name + " not found");
		historyAddEvent(history, "Timer:  " + name + " not found");
	}
}

