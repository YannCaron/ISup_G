

private const string SMART_SYSTEM_FORMAT = "SmartRadio.Components.Radio%d.Status";
private const string SMART_HOST_FORMAT = "SMARTRADIO_%d";

private const string SMART_RADIO_FORMAT = "SmartRadio.Components.Radio%d.Data";
private const string SMART_LINE_FORMAT = "SMARTRADIO_%d; - ; - ; - ; - ; - ; - ; - ";

void initSmartRadio() {
	dyn_string dataDps, dataValues;
	dataDps = getPointsFromPattern("SmartRadio.Components.Radio*.Data");
	
	for(int i = 1; i <= dynlen(dataDps); i++)
	{
		string statusDp;
		string host, ipAddress;
		string value;
		int number;

		sscanf(dataDps[i], SMART_RADIO_FORMAT, number);

		sprintf(statusDp, SMART_SYSTEM_FORMAT, number);
		sprintf(host, SMART_HOST_FORMAT, number);
		sprintf(value, SMART_LINE_FORMAT, number);

		dynAppend(dataValues, value);
	}

	dpSetWait(dataDps, dataValues);	
}
