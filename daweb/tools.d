/*
	Type tool module for manipulating types.
*/
module daweb.tools;

/**
*	Selects a specific string until another string is found.
*/
string selectUntil(string selectIn, size_t selectIndexFrom, string selectTo, out size_t endIndex) {
	foreach (i; selectIndexFrom .. selectIn.length) {
		if (selectIn[i] == selectTo[0]) {
			if (selectTo.length == 1) {
				endIndex = (selectIndexFrom + i);
				return selectIn[selectIndexFrom .. i];
			}
			
			if (i < (selectIn.length - selectTo.length)) {
				if (selectIn[i .. i + selectTo.length] == selectTo) {
					endIndex = (selectIndexFrom + i);
					return selectIn[selectIndexFrom .. i];
				}
			}
		}
	}
	return null;
}

/**
*	Blank characters.
*/
private string blanks = " \t\r\n\0";

/**
*	Checks whether a string is blank or not.
*/
bool isBlank(string str) {
	import std.algorithm : canFind;
	
	foreach (c; str) {
		if (!canFind(blanks, c))
			return false;
	}
	return true;
}