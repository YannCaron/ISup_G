//** const
const string FILE_READ = "r";
const string FILE_CREATE = "w";
const string FILE_APPEND = "a";
const string FILE_READ_WRITE = "r+";
const string FILE_READ_CREATE = "w+";
const string FILE_READ_APPEND = "a+";

const int FILE_READ_MAXLENGTH = 200000;

const char FILE_EXTENTION_SEPARATOR = '.';

//** property
bool fexist(string filename)
{

	// variable
	bool value;

	if (access (filename, F_OK) == 0)
	{
		value = true;
	}
	else
	{
		value = false;
	}

	return value;

}

//** methode
string getName(string f) {

	string filename = f;
	
	if (substr(filename, strlen(filename) - 4, 1) == FILE_EXTENTION_SEPARATOR) {
		filename = substr (filename, 0, strlen(filename) - 4);
	}
	
	return filename;

}

string getExtention (string f) {

	dyn_string split = strsplit(f, FILE_EXTENTION_SEPARATOR);
	return split[dynlen(split)];

}

string addExtention(string f, string extention)
{

	// variable
	string filename = getName(f);
	string fileExtention = getExtention(f);
	string newExtention = getExtention(extention);
	string value = filename;

	value += FILE_EXTENTION_SEPARATOR + newExtention;
	
	return value;

}

string extractPath(string filename)
{

	// variable
	dyn_string splitFilename;
	string value;
	
	splitFilename = strsplit(filename, getPathSeparator());
	
	// remove last
	splitFilename[dynlen(splitFilename)] = "";
	
	value = strconcat(splitFilename, getPathSeparator());
	return value;

}
