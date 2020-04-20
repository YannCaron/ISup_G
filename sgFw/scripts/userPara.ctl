//////////////////////////////////////////////////////////////////////////////
// If you want to include a new driver:
//
// 1. In scripts/userDrivers.ctl
//    add new item to dds[i] for names, types and drivers respectively below
//
// 2. In panels/para
//    copy and change address_skeleton.pnl to create a new para-panel for
//    a new driver
//    panel name must be: address_newdrivertype.pnl
//    (in our example below: address_tstdrv1.pnl)
//
//    IMPORTANT: don't change the script in the panel-attributes and the buttons!
//
// 3. In this script below
//    add new case selection ( in our example case "tstdrv1":)
//     into the next four functions
//      upDpGetAddress
//      upDpSetAddress
//      upWritePanelAllAddressAttributes
//      upReadPanelAllAddressAttributes
//    and write the appropriate commands
//
//    global variable used for the _address.. -attributes is
//      anytype dpc;
//        dpc[1]=reference;
//        dpc[2]=subindex;
//        dpc[3]=mode;
//        dpc[4]=start;
//        dpc[5]=interval;
//        dpc[6]=reply;
//        dpc[7]=datatype;
//        dpc[8]=drv_ident;
//        dpc[9]=driver;
//    you don't have to set all of them, use only the necessary elements!
//////////////////////////////////////////////////////////////////////////////
//
// be careful: always use the same number of driver elements
// (e.g. dyn_strings, cases, etc.)
//
//////////////////////////////////////////////////////////////////////////////
// The examples in this script use a copy of panels/para/address_sim.pnl
//////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////
// main calls the needed function
// fct = 1: upDpGetAddress
// fct = 2: upDpSetAddress
// fct = 3: upWritePanelAllAddressAttributes
// fct = 4: upReadPanelAllAddressAttributes
//////////////////////////////////////////////////////////////////////////////
int USER_TYPE_INDEX = 1500;
int SERIAL_MODBUS_SHIFT = 200;
int MQ_DRIVER_SHIFT = 400;

int DEFAULT_TYPE = 9; // String

anytype main(string dpe, int Id, anytype dpc, int fct)
{
  bool ok, all_right;

  switch (fct)
  {
    case 1: upDpGetAddress(dpe, Id, dpc);
      break;
    case 2: upDpSetAddress(dpe, Id, dpc, all_right); dpc[99]=all_right;
      break;
    case 3: upWritePanelAllAddressAttributes(dpe, Id, dpc);
      break;
    case 4: upReadPanelAllAddressAttributes(dpe, Id, dpc, all_right); dpc[99]=all_right;
      break;
  }
  return (dpc);
}

//////////////////////////////////////////////////////////////////////////////
// this function reads the datapoint values
//////////////////////////////////////////////////////////////////////////////
upDpGetAddress(string dpe, int Id, anytype &dpc)
{
  bool active;
  unsigned subindex;
  char mode;
  int driver, datatype;
  anytype reference;
  string config, drv_ident;
  int typeShift = 0;
  
  config=paGetDpConfig(globalOpenConfig[Id]);

  if (globalAddressOld[Id] == "serialMod") typeShift = SERIAL_MODBUS_SHIFT;
  else if (globalAddressOld[Id] == "mqDriver") typeShift = MQ_DRIVER_SHIFT;
  
  switch (globalAddressOld[Id])
  {
    case "tcpComm":
    case "serialMod":
    case "mqDriver":
        dpGet(dpe+":"+config+".._active",active,
              dpe+":"+config+".._reference",reference,
              dpe+":"+config+".._subindex",subindex,
              dpe+":"+config+".._mode",mode,
              dpe+":"+config+".._datatype",datatype,
              dpe+":"+config+".._drv_ident",drv_ident,
              dpe+":_distrib.._driver",driver);

        // set default values
        if (reference == 0) {
          reference = "";
          subindex = 0;
          mode = 0;
          datatype = DEFAULT_TYPE;
          active = 1;        
        }
        
        dpc[1]=reference;
        dpc[2]=subindex;
        dpc[3]=mode;
        dpc[7]=datatype;
        dpc[8]=drv_ident;
        dpc[9]=driver;
        dpc[12]=active;
      break;
    default: break;
  }
}

//////////////////////////////////////////////////////////////////////////////
upDpSetAddress(string dpe, int Id, dyn_anytype dpc, bool &all_right)
{
  bool       ok;
  string     config,dpn;
  dyn_int    drivers;
  dyn_string sPara;

  config = paGetDpConfig(globalOpenConfig[Id]);  
  dpn = dpSubStr(dpe,DPSUB_DP)+".";
  
  switch (globalAddressOld[Id])
  {
    case "tcpComm":
    case "serialMod":
    case "mqDriver":
        paErrorHandlingDpSet(
          dpSetWait(dpe+":_distrib.._driver",dpc[9]),all_right);
        paErrorHandlingDpSet(
          dpSetWait(dpe+":_address.._type", DPCONFIG_PERIPH_ADDR_MAIN,
                dpe+":"+config+".._reference",dpc[1],
                dpe+":"+config+".._subindex",dpc[2],
                dpe+":"+config+".._mode",dpc[3],
                dpe+":"+config+".._datatype",dpc[7],
                dpe+":"+config+".._drv_ident",dpc[8]),all_right);
        paErrorHandlingDpSet(
          dpSetWait(dpe+":_address.._active",dpc[12]),all_right);
      break;
    default: break;
  }
}

//////////////////////////////////////////////////////////////////////////////
upWritePanelAllAddressAttributes(string dpe, int Id, anytype dpc)
{
  dyn_string addr;

  // extract address
  addr = strsplit (dpc[1], "_");
  string addr_point = "";
	int flicker = 0;
    
  if (dynlen (addr) <= 1) {
    addr[1] = "1"; 
  } 

  // convert types
  dpc[7] -= USER_TYPE_INDEX;
  
  if (globalAddressOld[Id] == "tcpComm") {
    addr_point = substr(dpc[1], strlen(addr[1]) + 1);
  } else if (globalAddressOld[Id] == "serialMod") {
    dpc[7] -= SERIAL_MODBUS_SHIFT;
    
    dyn_string rawAddress = strsplit(addr[dynlen (addr)], "$");
        
    addr_point = rawAddress[1];
    
    flicker = 0;
    if (dynlen(rawAddress) > 1) {
    	flicker = (int)rawAddress[dynlen (rawAddress)];
  	}

    setValue("flicker","text",flicker);
  } else if (globalAddressOld[Id] == "mqDriver") {
    addr_point = dpc[1];
    dpc[7] -= MQ_DRIVER_SHIFT;
  }

  // convert in / out
  if (dpc[3]<=1) dpc[3] = 0; else dpc[3] = 1;
  
	if (globalAddressOld[Id] != "mqDriver")
      setMultiValue("Agent","text",addr[1]);
  
  setMultiValue(
      "reference","text",addr_point,
      "subindex","text",dpc[2],
      "mode","number",dpc[3],
      "datatype","selectedPos",dpc[7],
      "driver","text",dpc[9],
      "cboAddressActive","state",0,dpc[12]);
}

//////////////////////////////////////////////////////////////////////////////
upReadPanelAllAddressAttributes(string dpe, int Id, dyn_anytype &dpc, bool &readOK)
{
  string reference;
  int subindex, mode, driver, datatype;
  bool active;
  dyn_string addr;
  
	if (globalAddressOld[Id] != "mqDriver")
	  getMultiValue("Agent","text",addr[1]);
  
  
  readOK=true;
  getMultiValue(
  "reference","text",addr[2],
  "subindex","text",subindex,
  "mode","number",mode,
  "driver","text",driver,
  "datatype","selectedPos",datatype,
  "cboAddressActive","state",0,active);

  // convert types
  datatype += USER_TYPE_INDEX;

  // reference
  if(globalAddressOld[Id] == "tcpComm") {
    reference = addr[1] + "_" + addr[2];
  } else if (globalAddressOld[Id] == "serialMod") {
    int flicker;
    getValue("flicker", "text", flicker);

    datatype += SERIAL_MODBUS_SHIFT;
    
    if (flicker == 0) {
	    reference = addr[1]+ "_" + datatype + "_" + addr[2];
    } else {
	    reference = addr[1]+ "_" + datatype + "_" + addr[2] + "$" + flicker;
    }
  } else if (globalAddressOld[Id] == "mqDriver") {
    reference = addr[2];
    datatype += MQ_DRIVER_SHIFT;
  }
      
  // convert in/out
  if (mode==0) mode=1; else mode = 4;

  dpc[1]=reference; 		// reference
  dpc[2]=subindex; 			// subindex
  dpc[3]=mode; 			   // mode
  dpc[7]=datatype;			// datatype
  dpc[8]=globalAddressDrivers[dynContains(globalAddressTypes,globalAddressNew[paMyModuleId()])]; // drv_ident
  dpc[9]=driver;			   // driver
  dpc[12]=active;			 // active
}
