
// File: sgFwConstants.ctl
//
// Version 1.1
//
// Date 24-JUL-03
//
// This file contains the definition of all the litteral contants needed by the Framework
//
// History
// =======
// 24-JUL-03 : First version (VL)
// FEB-04 : PW, Added Hidden postfix, and Inputs, Outputs Postfix
// MARS-09: Th.V AlarmRule, AlarmPanel,
//               EventGenerateEvents,
//		 InputXMLMatchingTable, OutputXMLMatchingTable
//		 InputConnections, OutputConnections, RulesConnections, ParamsConnections, ReferenceConnections, DefaultValuesConnections
// 14-Sept-05 : Andrew Burkimsher : Added SGFWSYTEM_PARAMS_POSTFIX, SGFWSYSTEM_ALARM_CLASS
// JAN-06: PW Added several constants for sgFw 1.18

// sgFwSystem Postfix
const string GENERATE_ALARMS_POSTFIX = ".Alarms.GenerateAlarms";
const string ALARM_RULE_POSTFIX = ".Alarms.AlarmRule";
const string ALARM_ACTIVE_POSTFIX = ".Alarms.AlarmActive";
const string ALARM_CONFIG_ACTIVE_POSTFIX = ".Alarms.AlarmActive:_alert_hdl.._active";
const string ALARM_HANDLING = ".Alarms.AlarmActive:_alert_hdl.._type";
const string ALARM_RULE = ".Alarms.AlarmRule";
const string ALARM_PANEL = ".Alarms.AlarmActive:_alert_hdl.._panel";
const string ALARM_PANEL_PARAM = ".Alarms.AlarmActive:_alert_hdl.._panel_param";
const string ALARM_TEXT = ".Alarms.AlarmActive:_alert_hdl.._text1";
const string GENERATE_EVENTS_POSTFIX = ".Events.GenerateEvents";
const string EVENT_TEXT_POSTFIX = ".Events.EventText";
const string EVENT_HISTORIES_POSTFIX = ".Events.Histories";
const string EVENT_GENERATE_EVENT_POSTFIX = ".Events.GenerateEvents";
// DESCRIPTION_DUMMY is used for changing the description with connections
// must not be used otherwise!!!
const string DESCRIPTION_DUMMY = ".Events.EventText";
const string STATUS_POSTFIX = ".Status";
const string PRE_STATUS_POSTFIX = ".PreStatus";
const string MESSAGE_POSTFIX = ".Message";
const string LABEL1_POSTFIX = ".Label1";
const string LABEL2_POSTFIX = ".Label2";
const string LABEL3_POSTFIX = ".Label3";
const string LABEL4_POSTFIX = ".Label4";
const string OLD_MESSAGE_POSTFIX = ".Events.LastMessage";
const string OLD_STATUS_POSTFIX = ".Events.LastStatus";
const string LOGIC_ENABLED_POSTFIX = ".LogicConfig.LogicEnabled";
const string LOGIC_RULE_POSTFIX = ".LogicConfig.Rule";
const string LOGIC_INPUTS_POSTFIX = ".LogicConfig.Inputs";
const string NOTLOGIC_INPUTS_POSTFIX = ".LogicConfig.NotLogicInputs";
const string DISABLED_POSTFIX = ".Disabled";
const string SUB_DISABLED_POSTFIX = ".SubDisabled";
const string STATUS_DELAY_POSTFIX = ".StatusDelay";
const string HIDDEN_POSTFIX = ".Hidden";
const string COMMENT_POSTFIX = ".Comment";
const string AETABLE_POSTFIX = ".AETable";
const string SGFWSYTEM_PARAMS_POSTFIX = ".Params";
const string SGFWSYSTEM_ALARM_CLASS = ".Alarms.AlarmActive:_alert_hdl.._class";

const string ORIGINAL_STIME  = ":_original.._stime";

// XML
const string XML_HB_SYSTEM_POSTFIX = ".Address.System";
const string XML_HEARTBEAT_POSTFIX = ".Heartbeat";


// 24.06.2005 aj added constants for NAVIR
// for Bit State
const string STATE_POSTFIX = ".State";
const string IS_STATE_POSTFIX = ".IsState";
const string LAST_STATE_POSTFIX = ".Events.LastState";

// Rules Postfix
const string ALL_LOGIC_RULES = "LogicRules.Names";
const string ALL_ALARMS_RULES = "AlarmRules.Names";

// DP Postfix
const string INPUTS_POSTFIX = ".Inputs";
const string OUTPUTS_POSTFIX = ".Outputs";
const string TEMPLATE_POSTFIX = ".Template";
const string RULES_POSTFIX = ".Rules";
const string PARAMS_POSTFIX = ".Params";
const string REFERENCES_POSTFIX = ".References";
const string COMPONENTS_POSTFIX = ".Components";
const string TIME_OUTS_POSTFIX = ".Timeouts";
const string DEFAULT_VALUES_POSTFIX = ".DefaultValues";

// XML Matching table
const string XML_MATCHING_TABLE = ".XMLMatchingTable";
const string INPUT_XML_MATCHING_TABLE_POSTFIX = ".Input";
const string OUTPUT_XML_MATCHING_TABLE_POSTFIX = ".Output";

// Connections
const string INPUT_CONNECTIONS_POSTFIX = ".Input";
const string OUTPUT_CONNECTIONS_POSTFIX = ".Output";
const string RULE_CONNECTIONS_POSTFIX = ".Rules";
const string PARAMS_CONNECTION_POSTFIX = ".Params";
const string REFERENCE_CONNECTIONS_POSTFIX = ".References";
const string DEFAULT_VALUES_CONNECTIONS = ".DefaultValues";

// Conversions table
const string INPUT_POSTFIX = ".Input";
const string OUTPUT_POSTFIX = ".Output";

// Framework Postfix

const string ACTIVE_CHAIN = "FwUtils.Framework.ActiveChain";
const string FRAMEWORK_STATUS_A = "FwUtils.Framework.FwStatusA";
const string FRAMEWORK_STATUS_B = "FwUtils.Framework.FwStatusB";
const string FRAMEWORK_STATUS_A_CHECKER = "FwUtils.Framework.FwStatusAChecker";
const string FRAMEWORK_STATUS_B_CHECKER = "FwUtils.Framework.FwStatusBChecker";
const string ACTIVE_FW_OK = "FwUtils.Framework.ActiveFwOk";

const string CTRL_CLOCK_A = "FwUtils.Framework.FwCtrlClockA";
const string CTRL_CLOCK_B = "FwUtils.Framework.FwCtrlClockB";
const string ACTIVE_CTRL_CLOCK = "FwUtils.Framework.ActiveCtrlClock";

const string FRAMEWORK_CHECKER_STATUS_A = "FwUtils.Framework.FwCheckerStatusA";
const string FRAMEWORK_CHECKER_STATUS_B = "FwUtils.Framework.FwCheckerStatusB";

const string AUTOSWITCH_STATUS_A = "FwUtils.Framework.AutoswitchStatuses.StatusA";
const string AUTOSWITCH_STATUS_B = "FwUtils.Framework.AutoswitchStatuses.StatusB";
const string ACTIVE_CHAIN_SELECT = "FwUtils.Framework.ActiveChainSelect";

// standard histories Postfixes
const string SYSTEM_HISTORY = 	"FwUtils.SystemHistory";
const string SYSTEM_HISTORY_POSTFIX = ".SystemHistory";
const string EVENTTEXT_DELIMITER = "\t";

// Events severity postfixes
const string SEVERITY_CRITICAL = "CRITICAL:";
const string SEVERITY_WARNING  = "WARNING: ";
const string SEVERITY_SOLVED   = "SOLVED:  ";
const string SEVERITY_INFO     = "INFO:    ";
const string SEVERITY_COMMAND  = "COMMAND: ";
const string SEVERITY_SYSTEM   = "SYSTEM:  ";
const string SEVERITY_DISABLED = "DISABLED:"; // severity for a disabled block change
const string SEVERITY_ENABLE	 = "ENABLE:"; //severity for block enable user command
const string SEVERITY_DISABLE	 = "DISABLE:"; //severity for block disable user command

const string SEVERITY_NOT_DEFINED   = "SEVERITY?";


// Alarms systems postfix
const string SUPERVISED_SYSTEMS = "FwUtils.SupervisedSystems";
const string ALARMS_DPS = "FwUtils.SupervisedSystems.AlarmsDpNames";

// constants for dpConnectQuery to status and alarm of distributed systems
const string SYSTEMS_GLOBAL_STATUS = "SystemStatus.GlobalStatus.Status";
const string SYSTEMS_GLOBAL_PRESTATUS = "SystemStatus.GlobalStatus.PreStatus";
const string SYSTEMS_GLOBAL_DISABLED = "SystemStatus.GlobalStatus.Disabled";
const string EXCLUDED_SYSTEMS = "SystemStatus.ExcludedSystems";
const string ALL_SYSTEMS_OK = "SystemStatus.AllSystemsOk";
const string DISTRIBUTED_SYSTEM_TYPE = "sgFwDistributedSystems";
const string DISTRIBUTED_STATUS ="Distributed_Status";
const string DISTRIBUTED_ALARM ="Distributed_Alarm";

// system global
const string SYSTEM_GLOBAL="SystemStatus.GlobalStatus";

// WAGO
const string WAGO_CLEARCACHE_POSTFIX = ".ClearCache";

// RESTART
const string RESTART_ADDRESS_POSTFIX = ".Address";
const string RESTART_LOGIN_POSTFIX = ".Login";
const string RESTART_PASSWORD_POSTFIX = ".Password";
const string RESTART_RUN_POSTFIX = ".Run";
const string RESTART_HISTORY_POSTFIX = ".History";

// Force Refresh
const string MSG_FORCE_REFRESH = "<Force Refresh> sent";
const string MSG_FORCE_TO_UKN = "<Force to UKN> sent";
const string LBL_FORCE_REFRESH = "Force Refresh";
const string LBL_FORCE_TO_UKN = "Force to UKN";


// Config
const string CONFIG_DELIM = ";";

// Convert table
const string ELSE_CONVERT_VALUE = "ELSE";

// Style
public const string STYLE_REL_PATH = "style/";

