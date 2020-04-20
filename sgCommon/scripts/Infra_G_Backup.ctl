private const string FILE_LOGIC_FORMAT = "Backup-%s-LogicInputs.dpl";
private const string FILE_ANALOGIC_FORMAT = "Backup-%s-AnalogicInputs.dpl";
private const string FILE_DATE_DORMAT = "%Y-%m-%d_%H-%M-%S";

main()
{
  string t = formatTime(FILE_DATE_DORMAT, getCurrentTime());

  string logicName;
  string analogicName;

  sprintf(logicName, getPath(DPLIST_REL_PATH) + FILE_LOGIC_FORMAT, t);  
  sprintf(analogicName, getPath(DPLIST_REL_PATH) + FILE_ANALOGIC_FORMAT, t);  
  
  system ("PVSS00ascii -filter P -filterDp Station*.Components.*.Inputs.* -out " + logicName);
  system ("PVSS00ascii -filter OP -filterDp Station*.Components.*.AnalogInputs.*.{Value,Offset,Gain,Y1,Y2} -out " + analogicName);
}
