const dyn_string WAGO_ALARMS = makeDynString(
    getSystemName() + "alert.", 
    getSystemName() + "disturbance.", 
    getSystemName() + "warning.");

const int WAGO_DELAY_MIN = 0;
const int WAGO_DELAY_MAX = 600;

const bool WAGO_THRESHOLD_INCLUDE_LOW = TRUE;

const float WAGO_DEFAULT_PT100_OFFSET = 0;
const float WAGO_DEFAULT_PT100_GAIN = 10;
const float WAGO_DEFAULT_PT100_Y1 = 0;
const float WAGO_DEFAULT_PT100_Y2 = 100;
const dyn_float WAGO_DEFAULT_PT100_THRESHOLDS = makeDynFloat(5, 10, 28, 40);
const string WAGO_PT100_FORMULA = "(p1 / p3) + p2"; // raw / gain

const float WAGO_DEFAULT_4_20MA_OFFSET = 0;
const float WAGO_DEFAULT_4_20MA_GAIN = 32768;
const float WAGO_DEFAULT_4_20MA_Y1 = 20;
const float WAGO_DEFAULT_4_20MA_Y2 = 32;
const dyn_float WAGO_DEFAULT_4_20MA_THRESHOLDS = makeDynFloat(23, 24, 28, 29);
const string WAGO_4_20MA_FORMULA = "((p1 * (p5 - p4)) / p3) + p4";

const string WAGO_ALARM_FORMAT_ANALOCIG = "Alarm - %s";
const int WAGO_ALARM_LEN_ANALOCIG = 8;
const string WAGO_WARNING_FORMAT_ANALOCIG = "Warning - %s";

anytype getOptionalParam(string name, anytype defaultValue) {
  if (isDollarDefined(name)) {
    return getDollarValue(name);
  } else {
    return defaultValue;
  }
}

public string wagoAlarmSubString(string alarm) {
  return substr(alarm, strpos(alarm, ":") + 1);
}

void saveDpFunction(string dp, string formula) {
  // get datapoints
	string raw = dp + ".RawValue:_original.._value";
	string offset = dp + ".Offset:_original.._value";
	string gain = dp + ".Gain:_original.._value";
	string Y1 = dp + ".Y1:_original.._value";
	string Y2 = dp + ".Y2:_original.._value";

	// set  
	dpSetWait(
		dp + ".Value:_dp_fct.._type", DPCONFIG_DP_FUNCTION, 
		dp + ".Value:_dp_fct.._param", makeDynString(raw, offset, gain, Y1, Y2),
		dp + ".Value:_dp_fct.._fct", formula);     

}

void saveLogicAlert(string dp, bool active, bool nonc, string alarm, string text, string description) {
  
  // text
  string text0 = "", text1 = "";
  
  if (nonc == TRUE) {
    text0 = text;
    } else {
    text1 = text;
  }
  
  // create alert
  dpSetWait(dp + ":_alert_hdl.._type", DPCONFIG_ALERT_BINARYSIGNAL,
            dp + ":_alert_hdl.._text0", text0,
            dp + ":_alert_hdl.._text1", text1,
            dp + ":_alert_hdl.._class", alarm,
            dp + ":_alert_hdl.._ok_range", nonc,
            dp + ":_alert_hdl.._help", description,
            dp + ":_alert_hdl.._orig_hdl", true,
            dp + ":_alert_hdl.._active", active);  
  
}

void saveAnalogicAlert(string dp, string help, string alarmText, string warningText, float thVL, float thL, float thH, float thVH, bool active) {
  
  // create alert
  dpSetWait(dp + ":_alert_hdl.._type", DPCONFIG_ALERT_NONBINARYSIGNAL,
            dp + ":_alert_hdl.1._type", DPDETAIL_RANGETYPE_MINMAX,
            dp + ":_alert_hdl.2._type", DPDETAIL_RANGETYPE_MINMAX,
            dp + ":_alert_hdl.3._type", DPDETAIL_RANGETYPE_MINMAX,
            dp + ":_alert_hdl.4._type", DPDETAIL_RANGETYPE_MINMAX,
            dp + ":_alert_hdl.5._type", DPDETAIL_RANGETYPE_MINMAX,
            dp + ":_alert_hdl.1._u_limit", thVL,
            dp + ":_alert_hdl.2._l_limit", thVL,
            dp + ":_alert_hdl.2._u_limit", thL,
            dp + ":_alert_hdl.3._l_limit", thL,
            dp + ":_alert_hdl.3._u_limit", thH,
            dp + ":_alert_hdl.4._l_limit", thH,
            dp + ":_alert_hdl.4._u_limit", thVH,
            dp + ":_alert_hdl.5._l_limit", thVH,
            dp + ":_alert_hdl.1._u_incl", WAGO_THRESHOLD_INCLUDE_LOW,
            dp + ":_alert_hdl.2._l_incl", !WAGO_THRESHOLD_INCLUDE_LOW,
            dp + ":_alert_hdl.2._u_incl", WAGO_THRESHOLD_INCLUDE_LOW,
            dp + ":_alert_hdl.3._l_incl", !WAGO_THRESHOLD_INCLUDE_LOW,
            dp + ":_alert_hdl.3._u_incl", !WAGO_THRESHOLD_INCLUDE_LOW,
            dp + ":_alert_hdl.4._l_incl", WAGO_THRESHOLD_INCLUDE_LOW,
            dp + ":_alert_hdl.4._u_incl", !WAGO_THRESHOLD_INCLUDE_LOW,
            dp + ":_alert_hdl.5._l_incl", WAGO_THRESHOLD_INCLUDE_LOW,
            dp + ":_alert_hdl.1._text", alarmText,
            dp + ":_alert_hdl.2._text", warningText,
            dp + ":_alert_hdl.4._text", warningText,
            dp + ":_alert_hdl.5._text", alarmText,
            dp + ":_alert_hdl.1._class", WAGO_ALARMS[1],
            dp + ":_alert_hdl.2._class", WAGO_ALARMS[3],
            dp + ":_alert_hdl.4._class", WAGO_ALARMS[3],
            dp + ":_alert_hdl.5._class", WAGO_ALARMS[1],
            dp + ":_alert_hdl.._orig_hdl", TRUE,
            dp + ":_alert_hdl.._help", help,
            dp + ":_alert_hdl.._active", active);
}

void saveArchive(string dp) {

  // create alert
  dpSetWait(dp + ":_archive.._type", DPCONFIG_DB_ARCHIVEINFO, 
            dp + ":_archive.._archive", TRUE, 
            dp + ":_archive.1._type", DPATTR_ARCH_PROC_SIMPLESM, 
            dp + ":_archive.1._class", "_ValueArchive_0",
            dp + ":_archive.1._std_type", 7,
            dp + ":_archive.1._std_tol", 0.5); 
  
}
