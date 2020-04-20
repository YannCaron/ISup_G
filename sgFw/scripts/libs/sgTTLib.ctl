// File: sgFw2TTLib.ctl
// 
// Version 1.0
//
// Date 21-JUN-04
//
// This library contains the truth table functions
//
// History
// =======
// 21-JUN-03 : First version (VL, TV, PW)
// 22-JUN-04 : added the function sgFwInputMatchStatus (PW)



bool sgTTIsValidStatusCombination(string combination)
{ 
	dyn_string ds;
	ds = strsplit(combination, "+");
	
	if (dynlen(ds) == 0)
		return false;
		
	if (dynlen(ds) == 1) // only one cell
	{
		if (sgFwIsValidStatus(ds[1]) || sgFwIsValidInvertedStatus(ds[1]))
			return true;
			
		if (ds[1] == "ANY")
			return true;
			
		return false;
	} 
	else // more than 1 cell
	{
		if (!sgFwIsValidStatus(ds[1]) && !sgFwIsValidInvertedStatus(ds[1]))
			return false;
			
		bool isInverted;
		isInverted = sgFwIsValidInvertedStatus(ds[1]);
		
		for (int i = 2; i <= dynlen(ds); i++)
		{
			if (!sgFwIsValidStatus(ds[i]) && !sgFwIsValidInvertedStatus(ds[i]))
				return false;
			
			if (sgFwIsValidInvertedStatus(ds[i]) != isInverted)
				return false;
		} // loop
		return true;	
	}	
} // sgFwIsTTValidStatusCombination(string combination)
dyn_string sgTTGetLineHeader(string line)
{
	dyn_string ds, empty;
	ds = strsplit(line, "_");
	
	if (dynlen(ds) < 4)
		return empty;
					
	return makeDynString(ds[1], ds[2], ds[3], ds[4]);
} // sgFwGetTTLineHeader(string line)

dyn_string sgTTGetInputs(string line)
{
	dyn_string header, empty;
	header = sgTTGetLineHeader(line);
	
	if (dynlen(header) == 0)
		return empty;
		
	dyn_string ds;
	ds = strsplit(line, "_");
	
	dyn_string inputs;
	
	for (int i = 5; i <= dynlen(ds); i++)
		dynAppend(inputs, ds[i]);
		
	return inputs;
}

bool sgTTCheckLine(string line)
{
	dyn_string header;
	header = sgTTGetLineHeader(line);
	if (dynlen(header) == 0)
		return false;
		
	if (!sgFwIsValidStatus(header[3]))
		return false;
		
	int N;
	N = header[4];
	
	if (N > 0)
	{
		if (header[1] != "---")
			return false; // ALL !
			
		if (header[2] != "---")
			return false; // ANY !
			
			
		dyn_string inputs;
		inputs = sgTTGetInputs(line);
		
		if (N != dynlen(inputs))
			return false;
			
		for (int i = 1; i <= dynlen(inputs); i ++)
		{
			if (!sgTTIsValidStatusCombination(inputs[i]))
				return false;
		}		// loop
		
		return true;
	} // N > 0
	else // N = 0
	{
		dyn_string inputs;
		inputs = sgTTGetInputs(line);
		if (dynlen(inputs) > 0)
			return false;
		
		if (header[1] != "---")
		{
			// ALL
			if (!sgTTIsValidStatusCombination(header[1]))
				return false;
			
			if (header[2] != "---")
				return false;
				
			return true;
		} // ALL
		
		if (header[2] != "---")
		{
			// ANY
			if (!sgTTIsValidStatusCombination(header[2]))
				return false;
				
			return true;
		}
	} // N = 0
	
	return false; // N = 0 && ALL = "---" && ANY = "---"	
} // sgFwTTCheckLine

// Check if the given input matches the status passed as reference. Status "ANY" treated too
bool sgTTInputMatchStatus(string input, string status)
{
	if(status == "ANY")
		return true;
	
	if(sgFwIsValidStatus(status))  // input doesn't contain "!" (status not inverted)
	{
		if(input == status)				// input match status 
			return true;						// -> true

		return false;							// otherwise -> false
	}
	
	if(sgFwIsValidInvertedStatus(status))  // if status is inverted ("!xxx")
	{
		if(input != strltrim(status, "!"))	
			return true;						// input is different of status -> true (ok for inverted status)
	
		return false;
	}
	
	return false;
} //sgFwTTInputMatchStatus
bool sgTTStatusMatchCombination(string input, string combination)
{
	dyn_string ds;
	ds = strsplit(combination, "+");
	
	if (dynlen(ds) == 1)
		return sgTTInputMatchStatus(input, ds[1]);
		
	// more than one status in the combination
	if (sgFwIsValidInvertedStatus(ds[1]))
	{
		for (int i = 1; i <= dynlen(ds); i++)
		{
			if (!sgTTInputMatchStatus(input, ds[i]))
				return false;
		}
		return true;
	}
		
	if (sgFwIsValidStatus(ds[1]))
	{
		for (int i = 1; i <= dynlen(ds); i++)
		{
				if (sgTTInputMatchStatus(input, ds[i]))
					return true;
		}
		return false;
	}
	return false;
} // sgTTStatusMatchCombination(string input, string combination)

bool sgTTMatchLine(string line, dyn_string inputs, dyn_bool disableds)
{
	dyn_string header;
	header = sgTTGetLineHeader(line);
	
	// case ALL
	if (header[1] != "---")
	{
		for (int i = 1; i <= dynlen(inputs); i++)
		{
			if (!disableds[i])
			{
				if (!sgTTStatusMatchCombination(inputs[i], header[1]))
					return false;
			}
		} // loop
		return true;
	} // ALL

	// Case ANY
	if (header[2] != "---")
	{
		for (int i = 1; i <= dynlen(inputs); i++)
		{
			if (!disableds[i])
			{
				if (sgTTStatusMatchCombination(inputs[i], header[2]))
					return true;
			}
		} // loop
		return false;
	} // ANY
	
	// case N
	if (header[4] != "")
	{
		dyn_string combinations;
		combinations = sgTTGetInputs(line);
		
		for (int i = 1; i <= dynlen(inputs); i++)
		{
			if (!disableds[i])
			{
				if (!sgTTStatusMatchCombination(inputs[i], combinations[i]))
					return false;
			}
		} // loop
		return true;
	} // case N
	return false;
} // sgTTMatchLine(string line, dyn_string inputs, dyn_bool disableds)

int sgTTGetN(dyn_string table)
{
	for (int i = 1; i <= dynlen(table); i++)
	{
	 	dyn_string header;
	 	header = sgTTGetLineHeader(table[i]);
	 	
	 	if (header[4] != 0)
	 		return header[4]; 	
	}
	
	return 0; 
} // int sgTTGetN(dyn_string table)


global int gTTCounter = 0;
string sgTTComputeOutput(dyn_string inputs, dyn_string table, dyn_bool disableds)
{
	gTTCounter++;
//	DebugTN("sgTTComputeOutput " + gTTCounter);

	int N;
	N = sgTTGetN(table);
	
	if ((N > 0) && (dynlen(inputs) != N))
		return "UKN";
		
	// dynInsertAt(table, "UKN_---_UKN_0", 1); // unknown in case of all inputs disabled
	
	bool allDisabled = true;
	for (int cpt = 1; cpt <= dynlen(disableds); cpt++)
	{
		if (!disableds[cpt])
		{
			allDisabled = false;
			break;
		}		
	}
	
	if (allDisabled == true)
	{
		// DebugTN("sgTTComputeOutput >> all entries are disabled");
		return "UKN";
	}
		
	dynAppend(table, "---_ANY_UKN_0"); // if nothing line of table match
	
	
	for (int i = 1; i <= dynlen(table); i++)
	{
	
		if (sgTTMatchLine(table[i], inputs, disableds))
		{ 
			dyn_string header;
			header = sgTTGetLineHeader(table[i]);
			return header[3];
		}	
	}
	return "UKN";
	
} // string sgTTComputeOutput(dyn_string inputs, dyn_string table, dyn_bool disableds)

bool sgTTCheckTable(dyn_string table)
{
	int N = 0;
	
	for (int i = 1; i <= dynlen(table); i++)
	{
		if (!sgTTCheckLine(table[i]))
			return false;
			
		int currentN;
		dyn_string header;
		header = sgTTGetLineHeader(table[i]);
		currentN = header[4];
		
		if (currentN > 0)
		{
			if (N == 0)
				N = currentN;
			else if (N != currentN)
				return false;		
		}			
	} // loop
	return true;
} // sgTTCheckTable(dyn_string table)
