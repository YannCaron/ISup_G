
const string OPS_STATUS = "OPS";
const string SBY_STATUS = "SBY";
const string SSB_STATUS = "SSB";
const string INI_STATUS = "INI";
const string DEG_STATUS = "DEG";
const string U_S_STATUS = "U/S";
const string TEC_STATUS = "TEC";
const string WIP_STATUS = "WIP";
const string ABS_STATUS = "ABS";
const string STP_STATUS = "STP";
const string UKN_STATUS = "UKN";

const string NOT_OPS_STATUS = "!OPS";
const string NOT_SBY_STATUS = "!SBY";
const string NOT_SSB_STATUS = "!SSB";
const string NOT_INI_STATUS = "!INI";
const string NOT_DEG_STATUS = "!DEG";
const string NOT_U_S_STATUS = "!U/S";
const string NOT_TEC_STATUS = "!TEC";
const string NOT_WIP_STATUS = "!WIP";
const string NOT_ABS_STATUS = "!ABS";
const string NOT_STP_STATUS = "!STP";
const string NOT_UKN_STATUS = "!UKN";


dyn_string sgFwGetStatuses()
{
	return makeDynString(OPS_STATUS, SBY_STATUS, SSB_STATUS, INI_STATUS, DEG_STATUS, U_S_STATUS, TEC_STATUS, WIP_STATUS, ABS_STATUS, STP_STATUS,
									  UKN_STATUS);	
} // sgFwGetStatuses

dyn_string sgFwGetInvertedStatuses()
{
	return makeDynString(NOT_OPS_STATUS, NOT_SBY_STATUS, NOT_SSB_STATUS, NOT_INI_STATUS, NOT_DEG_STATUS, NOT_U_S_STATUS, NOT_TEC_STATUS, NOT_WIP_STATUS,
	                  NOT_ABS_STATUS, NOT_STP_STATUS, NOT_UKN_STATUS);
} // sgFwGetInvertedStatuses

bool sgFwIsValidStatus(string status)
{
 return (dynContains(sgFwGetStatuses(), status) != 0);

} // sgFwIsValidStatus

bool sgFwIsValidInvertedStatus(string status)
{
	return (dynContains(sgFwGetInvertedStatuses(), status) != 0);

} // sgFwIsValidInvertedStatus


