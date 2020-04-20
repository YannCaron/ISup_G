const char DYN_SEPARATOR = '|';

dyn_string toDynString(string str)
{
	return strsplit(str, DYN_SEPARATOR);
}

string dynToString(dyn_string ds) {
  return dynConcat(ds, DYN_SEPARATOR);
}

string dynConcat(dyn_string ds, string separator) {

  string ret;
  for (int i = 1; i <= dynlen (ds); i++) {
    if (i > 1) ret += separator;
    ret += ds[i];
  }
  return ret;
  
}

dyn_anytype mappingValues(mapping ms) {
  dyn_anytype keys = mappingKeys(ms);
  dyn_anytype ret;
  for (int i = 1; i <= dynlen(keys); i++) {
    anytype key = keys[i];
    dynAppend(ret, ms[key]);
  }
  return ret;
}

int dynContainsIgnoreCase (dyn_string ds, string search) {
  for (int i = 1; i < dynlen (ds); i++) {
    if (strtoupper(ds[i]) == strtoupper(search)) {
        return i;
    }
  }
  return -1;
}

// append postfix on each items of the dynString Array
dyn_string dynAppendEachString (dyn_string dyn, string postFix) {
  
  dyn_string ret = makeDynString();
  for (int i = 1; i<=dynlen(dyn); i++) {
    string concat = dyn[i] + postFix;
    dynAppend(ret, concat);
  }
  return ret;
}

dyn_string dynInsertEachString (dyn_string dyn, string preFix) {
  
  dyn_string ret = makeDynString();
  for (int i = 1; i<=dynlen(dyn); i++) {
    string concat = preFix + dyn[i];
    dynAppend(ret, concat);
  }
  return ret;
}

dyn_bool dynFillBool(int length, bool value) {
  dyn_bool values;
  for (int i = 1; i<=length; i++) {
    values[i] = value;
  }
  return values;
}

dyn_int dynFillInt(int length, int value) {
  dyn_int values;
  for (int i = 1; i<=length; i++) {
    values[i] = value;
  }
  return values;
}


dyn_float dynFillFloat(int length, float value) {
  dyn_float values;
  for (int i = 1; i<=length; i++) {
    values[i] = value;
  }
  return values;
}

dyn_string dynFillString(int length, string value) {
  dyn_string values;
  for (int i = 1; i<=length; i++) {
    values[i] = value;
  }
  return values;
}

dyn_string dynFillStringFormat(int length, string format) {
  dyn_string values;
  for (int i = 1; i<=length; i++) {
    string value;
    sprintf(value, format, i);
    values[i] = value;
  }
  return values;
}
