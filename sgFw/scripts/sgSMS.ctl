main()
{
  getGlobalAlarmInputsToSetSMSAndEmail();
  connectAllSMSSystems();
  writeSMSHeartBeat(); 
}
