global dyn_string _MOXA_Admin_descriptions;
global dyn_string _MOXA_Admin_inverts;
global dyn_string _MOXA_Admin_delays;

void loadDataToGlobal(string id) {
  dyn_string dps = dpNames(id + ".Inputs.*");

  _MOXA_Admin_descriptions = getDpValues(dps, ".Description");
  _MOXA_Admin_inverts = getDpValues(dps, ".Invert");
  _MOXA_Admin_delays = getDpValues(dps, ".Delay");

}

void saveDataFromGlobal(string id) {
  dyn_string dps = dpNames(id + ".Inputs.*");

  dpSet(dpAppend(dps, ".Description"), _MOXA_Admin_descriptions);
  dpSet(dpAppend(dps, ".Invert"), _MOXA_Admin_inverts);
  dpSet(dpAppend(dps, ".Delay"), _MOXA_Admin_delays);
}
