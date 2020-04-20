const int delayToSendSMS = 5000; // delay in [ms] for SMS

dyn_string SMSSystems;

bool SMSAlarmsconnected;
bool emailAlarmsconnected;

void getGlobalAlarmInputsToSetSMSAndEmail()
{
  dyn_string alarmInputs;
  dyn_string allISupGlobalInputs;
  dpGet(SYSTEM_GLOBAL + LOGIC_INPUTS_POSTFIX, alarmInputs);
  string systemName = getSystemName();  

  for(int i = 1;i <= dynlen(alarmInputs); i++) {
    dynAppend(allISupGlobalInputs, systemName + alarmInputs[i] + ALARM_ACTIVE_POSTFIX); 
  }
  
//  DebugTN("getGlobalAlarmInputsToSetSMSAndEmail; allISupGlobalInputs:" + allISupGlobalInputs);
  dpSet("SMS.SMSConfig.LocalSMSSystems", allISupGlobalInputs); 
}    

void connectAllSMSSystems()
{
  dyn_string localSMSSystems;
  dyn_string remoteSMSSystems;
  int res;

  dpGet("SMS.SMSConfig.LocalSMSSystems", localSMSSystems, "SMS.SMSConfig.RemoteSMSSystems", remoteSMSSystems);
  
  
  dynAppend(SMSSystems, localSMSSystems);
  dynAppend(SMSSystems, remoteSMSSystems);

  dpConnect("connectDisconnectSMSAlarms", true, "SMS.SMSMode", ACTIVE_CHAIN);
  dpConnect("connectDisconnectEmailAlarms", true, "SMS.EmailMode", ACTIVE_CHAIN);
  
}//connectAllSMSSystems

void connectDisconnectEmailAlarms (string EmailModeDp, bool isEmailMode, string isActiveChainDpName, string activeChain)
{
  if (isEmailMode && isActiveChain() && !emailAlarmsconnected )
  {
    dpQueryConnectSingle("connectAlarmsSMSEmail", TRUE, "EmailAlarms",
           "SELECT ALERT ':_alert_hdl.._ackable',':_alert_hdl.._obsolete' FROM '" + "*' REMOTE ALL",
           delayToSendSMS);

    emailAlarmsconnected = true;
    }
  else
  if( (!isEmailMode || !isActiveChain() )&& emailAlarmsconnected ) //-> disconnect
  {
    dpQueryDisconnect("connectAlarmsSMSEmail", "EmailAlarms");
    emailAlarmsconnected = false;
  }

}

void connectDisconnectSMSAlarms (string SMSModeDp, bool isSMSMode, string isActiveChainDpName, string activeChain)
{
  if (isSMSMode && isActiveChain() && !SMSAlarmsconnected )
  {
    dpQueryConnectSingle("connectAlarmsSMSEmail", TRUE, "SMSAlarms",
           "SELECT ALERT ':_alert_hdl.._ackable',':_alert_hdl.._obsolete' FROM '" + "*' REMOTE ALL",
           delayToSendSMS);

    SMSAlarmsconnected = true;
    }
  else
  if( (!isSMSMode || !isActiveChain() )&& SMSAlarmsconnected ) //-> disconnect
  {
    dpQueryDisconnect("connectAlarmsSMSEmail", "SMSAlarms");
    SMSAlarmsconnected = false;
  }

}// connectDisconnectSMSAlarms


void connectAlarmsSMSEmail(string ident, dyn_dyn_anytype values)
{
  mapping smsTable;
  string smsText;
  string systemName = getSystemName();  
  
  dyn_string allSMSSystems = SMSSystems;
  if (ident == "SMSAlarms"){
    dynAppend(allSMSSystems, systemName + "SMS.SMSTest.Alarms.AlarmActive");
  }
  if (ident == "EmailAlarms"){
    dynAppend(allSMSSystems, systemName + "SMS.EmailTest.Alarms.AlarmActive");
  }

  //DebugTN("allSMSSystems: ", allSMSSystems);  
  
  //DebugTN("val:" + values);

  // check if value exists in SMS Alarm Dp table
  for (int i = 2; i <= dynlen(values);i++)
  {
    if ( (dynContains(allSMSSystems, (string)values[i][1]) > 0) && (values[i][4] == FALSE) ) // only if last info is not for an obsolete alarm (otherweise problems with navir due to alarm and re-alarming)
      smsTable[values[i][1]] = values[i][3];
  }

  //DebugTN(smsTable,SMSSystems);

  // if value (ackable) = TRUE -> get description to compose SMS text
  for (int i = 1; i <= mappinglen(smsTable); i++)
  {
    if (mappingGetValue(smsTable, i) == TRUE)  // if true -> sms
    {
      string description;
      string descriptionDpName;
      string key;
      key = mappingGetKey(smsTable, i);
      descriptionDpName = substr(key, 0, strpos(key, ALARM_ACTIVE_POSTFIX));
      description = "<" + dpGetDescription(descriptionDpName) + ">";

      if (smsText == "")
        smsText = description;
      else
        smsText = smsText + ", " + description;
    }
    
    if(ident == "SMSAlarms")
    {      
    
      // splitting in several SMS if too long
      if (strlen(smsText) >= 90 ) // if longer, the SMS will be truncated -> split in several SMS
      {
        composeMessage("SMS", smsText);
        smsText = "";
      }
    
      if (smsText != "" ) // if not empty compose SMS with current time
      {
        composeMessage("SMS", smsText);
      }
    }
    else if(ident == "EmailAlarms")
    {      
      if (smsText != "" ) // if not empty compose SMS with current time
      {
        composeMessage("Email", smsText);    
      }  
   }
  }
}

void composeMessage(string type, string smsText)
{  
    time currentTime;
    string sCurrentTime;

    currentTime = getCurrentTime();
    sCurrentTime = formatTime("%d/%m/%Y %H:%M:%S UTC", currentTime);
    //DebugTN("send SMS", "Alert on: " + smsText + " at " + sCurrentTime);
    string systemName;    
    string alertText;
    alertText = "Alert on: " + smsText + " at " + sCurrentTime;
    systemName = getSystemName();  

    sgSendSMTP(type, systemName + " " + type, alertText);
}

void sgSendSMTP(string type, string subject, string alertText)
{
  int ret;
  dyn_string email_cont;
  
  string SMTPServerName;

  dpGet("SMS.SMSConfig.SMTPServerName", SMTPServerName);
    
  if (type == "SMS")
  {
    string recipientsNumbers;
    dyn_string GSMNumbers = strsplit(getConfigValue("GSMNumbers"), CONFIG_DELIM);

    for (int i = 1; i <= dynlen(GSMNumbers); i++)
    {
      if (i == 1) // compose recipients int the message
        recipientsNumbers = GSMNumbers[i] + "@sms.ecall.ch";
		// PW JANUARY 2019 Before new Address: recipientsNumbers = GSMNumbers[i] + "@sms.skyguide.corp";

      else
        recipientsNumbers = recipientsNumbers + ";" + GSMNumbers[i] + "@sms.ecall.ch";
		// PW JANUARY 2019 Before new Address: recipientsNumbers = recipientsNumbers + ";" + GSMNumbers[i] + "@sms.skyguide.corp";
    }

    email_cont[1] = recipientsNumbers;
    email_cont[2] = "ISup@skyguide.ch"; // unfortunately case is not used when sending sms
    email_cont[3] = subject;
    email_cont[4] = alertText;
 
    emSendMail(getHostByName(SMTPServerName), getHostname(), email_cont, ret);  // skyguide SMTP server for email
  
    if (ret == 0)
      sgHistoryAddEvent(SYSTEM_HISTORY, SEVERITY_SYSTEM, "SMS:<"+alertText+"> was successfully sent");
    else
    {
      sgHistoryAddEvent(SYSTEM_HISTORY, SEVERITY_SYSTEM, "SMS:<"+alertText+"> was NOT successfully sent");
      DebugTN("sgSendSMSSMTP; The SMS message: "+alertText+" was NOT successfully sent to recipientsNumbers: "+recipientsNumbers);
    }
  }
  else if (type == "Email")
  {    
    string recipientsAddresses = getConfigValue("EmailRecipients");
//    DebugTN("sgSendSMTP; recipientsAddresses: " + recipientsAddresses);
    
    email_cont[1] = recipientsAddresses;
    email_cont[2] = "ISup@skyguide.ch"; // unfortunately case is not used when sending sms
    email_cont[3] = subject;
    email_cont[4] = alertText;
 
    emSendMail(getHostByName(SMTPServerName), getHostname(), email_cont, ret);  // skyguide SMTP server for email

    DebugTN("sgSendEmail; Email message: " + email_cont + " to " + recipientsAddresses);  
   
    if (ret == 0)
      sgHistoryAddEvent(SYSTEM_HISTORY, SEVERITY_SYSTEM, "Email:<"+alertText+"> was successfully sent");
    else
    {
      sgHistoryAddEvent(SYSTEM_HISTORY, SEVERITY_SYSTEM, "Email:<"+alertText+"> was NOT successfully sent");
      DebugTN("sgSendEmai; The Email message: "+alertText+" was NOT successfully sent to recipientsNumbers: "+emailAdress);
    }
  }
}

void writeSMSHeartBeat()
{
  // write OPS or SBY to have a status in ISup. If not, WatchDog set it to U/S
  do
  {
    if (isChainA() )
      if (isActiveChain())
        dpSet("ISup.ServerA.Components.SMSProcessor.PreStatus", OPS_STATUS);

      else
        dpSet("ISup.ServerA.Components.SMSProcessor.PreStatus", SBY_STATUS);

    if (isChainB())
      if (isActiveChain())
        dpSet("ISup.ServerB.Components.SMSProcessor.PreStatus", OPS_STATUS);
      else
        dpSet("ISup.ServerB.Components.SMSProcessor.PreStatus", SBY_STATUS);

    delay(5);
  }
  while (TRUE);
}// writeSMSHeartBeat
