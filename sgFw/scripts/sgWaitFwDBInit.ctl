main()
{
	time clockTime;
	float delta;
	do
	{
		delay(1);
		dpGet("FwUtils.Framework.ActiveCtrlClock:_original.._stime", clockTime);
		delta = getCurrentTime() - clockTime;
		delta = fabs(delta);
	}while(delta > 1);

//	DebugTN("FW Ready, Will call sgDBInit");
	sgDBInit();
}