/*
	io.inifile provides a thread-safe (by choice) wrapper for inifile handling.
	It provides thread-safety for both reading and writing.
	
	Author: Bauss
*/
module daweb.settings;

import std.array : replace, split;
import std.string : format;
import std.algorithm : canFind, startsWith;
import std.conv : to;
import std.file;
alias fexists = std.file.exists;
alias fwrite = std.file.write;

/**
*	A simple setting file.
*/
class SettingsFile(bool safe) {
private:
	/**
	*	The file name.
	*/
	string m_fileName;
	/**
	*	The values.
	*/
	string[string] m_values;
	/**
	*	Set to true if there has been written any values to the file.
	*/
	bool newData = false;
	
	/**
	*	Parses the settings file from a string.
	*/
	void parseFrom(string text) {
		foreach (line; split(text, "\n")) {
			if (canFind(line, "=") && !startsWith(line, ";;")) {
				auto data = split(line, "=");
				if (data.length == 2) {
					if (data[1]) {
						if (data[1].length) {
							string key = data[0];
							string value = data[1];
							
							m_values[key] = value;
						}
					}
				}
			}
		}
	}
	
	/**
	*	Creates a new instance of SettingsFile.
	*/
	this(string fileName) {
		m_fileName = fileName;
	}
public:
	/**
	*	Returns true if the file exists.
	*/
	bool exists() {
		static if (safe) {
			synchronized {
				return fexists(m_fileName);
			}
		}
		else {
			return fexists(m_fileName);
		}
	}
	
	/**
	*	Opens the settings file and parses the content.
	*/
	void open() {
		static if (safe) {
			synchronized {
				string text = readText(m_fileName);
				text = replace(text, "\r", "");
				parseFrom(text);
			}
		}
		else {
			string text = readText(m_fileName);
			text = replace(text, "\r", "");
			parseFrom(text);
		}
	}
	
	/**
	*	Closes the settings file and writes updated values to it.
	*/
	void close() {
		static if (safe) {
			synchronized {
				m_values = null;
			}
		}
		else {
			m_values = null;
		}
	}
	
	/**
	*	Reads a value from the settings file.
	*/
	auto read(T)(string key) {
		static if (safe) {
			synchronized {
				string value = m_values[key];
				return to!T(value);
			}
		}
		else {
			string value = m_values[key];
			return to!T(value);
		}
	}
	
	/**
	*	Deletes a value from the settings file.
	*/
	void remove(string key) {
		m_values.remove(key);
	}
	
	@property {
		/**
		*	Gets the keys.
		*/
		string[] keys() { return m_values.keys; }
	}
}

/**
*	Gets a setting file.
*/
auto getFile(string file) {
	string exePath = thisExePath;
	auto pathSplit = split(exePath, "\\");
	exePath = "";
	foreach (i; 0 .. pathSplit.length) {
		if (i == (pathSplit.length - 1))
			break;
		exePath ~= pathSplit[i] ~ "\\";
	}
	
	return new SettingsFile!(true)(exePath ~ "conf\\" ~ file);
}

/**
*	The conf\\settings.ini file
*/
private shared SettingsFile!(true) settingsFile;

/**
*	Gets the settings file.
*/
auto getSettings() {
	synchronized {
		return cast(SettingsFile!(true))settingsFile;
	}
}

/**
*	Loads the conf\\settings.ini
*/
void loadSettings() {
	auto settingsIni = getFile("settings.ini");
	settingsIni.open();
	settingsFile = cast(shared(SettingsFile!(true)))settingsIni;
}