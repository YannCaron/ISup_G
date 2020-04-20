const string OPTINET_DP                                = "OptiNet";
const string OPTINET_DP_FRIENDLYNAME_POSTFIX           = ".FriendlyNames";
const string OPTINET_DP_PROBABLECAUSE_POSTFIX          = ".ProbableCauses";
const string OPTINET_DP_SEVERITY_POSTFIX               = ".Severities";
const string OPTINET_DP_EVENTTYPE_POSTFIX              = ".EventTypes";
const string OPTINET_DP_EVENTTIME_POSTFIX              = ".EventTimes";
const string OPTINET_DP_ACKNOWLEDGEMENTSTATUS_POSTFIX  = ".AcknowledgementStatus";
const string OPTINET_DP_LINKTONMS_POSTFIX              = ".LinkToNMS";
const string OPTINET_DP_ERRORLIST_POSTFIX              = ".ErrorList";

const string OPTINET_STATUS_ACK = "ack";
const string OPTINET_STATUS_NOTACK = "notAck";

const string OPTINET_FORMAT_DATETIME_INPUT = "%4d%2d%2d%2d%2d%2d";
const string OPTINET_FORMAT_DATETIME_DISPLAY = "%Y-%m-%d %H:%M:%S";
const int OPTINET_DATETIME_NULL_YEAR = 1970;

void initOptiNet() {

  string query = "SELECT '_original.._value' FROM 'OptiNet.{References.*,Components.LinkToNMS.PreStatus}'";
  dpQueryConnectAll("optiNetAllListChange", true, "OptiNet", query, 100);

}

void emptyOptiNetSNMPLists() {
  dpSet(
    OPTINET_DP + REFERENCE_CONNECTIONS_POSTFIX + OPTINET_DP_FRIENDLYNAME_POSTFIX,  makeDynString(),
    OPTINET_DP + REFERENCE_CONNECTIONS_POSTFIX + OPTINET_DP_PROBABLECAUSE_POSTFIX,  makeDynString(),
    OPTINET_DP + REFERENCE_CONNECTIONS_POSTFIX + OPTINET_DP_SEVERITY_POSTFIX,  makeDynString(),
    OPTINET_DP + REFERENCE_CONNECTIONS_POSTFIX + OPTINET_DP_EVENTTYPE_POSTFIX,  makeDynString(),
    OPTINET_DP + REFERENCE_CONNECTIONS_POSTFIX + OPTINET_DP_EVENTTIME_POSTFIX, makeDynString(),
    OPTINET_DP + REFERENCE_CONNECTIONS_POSTFIX + OPTINET_DP_ACKNOWLEDGEMENTSTATUS_POSTFIX, makeDynString());
}

bool areAllAcknowledged(dyn_string acknowledgementStatus) {
  return(dynContains(acknowledgementStatus, OPTINET_STATUS_NOTACK) == 0);
}

void optiNetExtractStatus (dyn_dyn_anytype values, int &linkToNMS, string &linkToNMSStatus, dyn_string &friendlyNames, dyn_string &probableCauses, dyn_string &severities, dyn_string &eventTypes, dyn_string &eventTimes, dyn_string &acknowledgements) {
  for (int i = 1; i <= dynlen(values); i++) {
    if (isInStr(values[i][1], OPTINET_DP + REFERENCE_CONNECTIONS_POSTFIX + OPTINET_DP_LINKTONMS_POSTFIX)) {
      linkToNMS = values[i][2];
    } else if (isInStr(values[i][1], OPTINET_DP + COMPONENTS_POSTFIX + OPTINET_DP_LINKTONMS_POSTFIX)) {
      linkToNMSStatus = values[i][2];
    } else if (isInStr(values[i][1], OPTINET_DP + REFERENCE_CONNECTIONS_POSTFIX + OPTINET_DP_FRIENDLYNAME_POSTFIX)) {
      friendlyNames = values[i][2];
    } else if (isInStr(values[i][1], OPTINET_DP + REFERENCE_CONNECTIONS_POSTFIX + OPTINET_DP_PROBABLECAUSE_POSTFIX)) {
      probableCauses = values[i][2];
    } else if (isInStr(values[i][1], OPTINET_DP + REFERENCE_CONNECTIONS_POSTFIX + OPTINET_DP_SEVERITY_POSTFIX)) {
      severities = values[i][2];
    } else if (isInStr(values[i][1], OPTINET_DP + REFERENCE_CONNECTIONS_POSTFIX + OPTINET_DP_EVENTTYPE_POSTFIX)) {
      eventTypes = values[i][2];
    } else if (isInStr(values[i][1], OPTINET_DP + REFERENCE_CONNECTIONS_POSTFIX + OPTINET_DP_EVENTTIME_POSTFIX)) {
      eventTimes = values[i][2];
    } else if (isInStr(values[i][1], OPTINET_DP + REFERENCE_CONNECTIONS_POSTFIX + OPTINET_DP_ACKNOWLEDGEMENTSTATUS_POSTFIX)) {
      acknowledgements = values[i][2];
    }
  }

}

void optiNetAllListChange (string ident, dyn_dyn_anytype values) {
  int linkToNMS;
  string linkToNMSStatus;
  dyn_string friendlyNames, probableCauses, severities, eventTypes, eventTimes, acknowledgements;

  bool isEmpty = false;
  string status = UKN_STATUS;
  
  if (dynlen(values) > 0) {
    optiNetExtractStatus(values, linkToNMS, linkToNMSStatus, friendlyNames, probableCauses, severities, eventTypes, eventTimes, acknowledgements);

    if (dynlen(friendlyNames) == 0) {
      isEmpty = true;
    }    

    if (dynlen(friendlyNames) == 1 && friendlyNames[1] == "") {
      isEmpty = true;
      emptyOptiNetSNMPLists();
    }

    if (linkToNMSStatus == UKN_STATUS) {
      status = UKN_STATUS;
    } else if (isEmpty || areAllAcknowledged(acknowledgements)) {
      status = OPS_STATUS;
    } else {
      status = U_S_STATUS;
    }
    
  }
  
  dpSet(OPTINET_DP + COMPONENTS_POSTFIX + OPTINET_DP_ERRORLIST_POSTFIX + PRE_STATUS_POSTFIX, status);
  
}
