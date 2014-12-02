/*
	Provides mime type management.
	
	Author: Bauss
*/
module daweb.mime;

/**
*	The mime type collection.
*/
private shared string[string] mimeCollection;

/**
*	Loads the mime types from conf\\mime.dat
*/
void loadMime() {
	import std.file;
	import std.algorithm : startsWith;
	import std.array : replace, split;
	auto text = readText("conf\\mime.dat");
	text = replace(text, "\r", "");
	auto lines = split(text, "\n");
	foreach (line; lines) {
		if (line && line.length) {
			if (line != "" && !startsWith(line, ";;")) {
				auto data = split(line, "=");
				if (data.length == 2) {
					addMime(data[0], data[1]);
				}
			}
		}
	}
}

/**
*	Adds a mime type to the collection.
*/
void addMime(string extension, string mimeType, bool isDefault = false) {
	synchronized {
		auto mimes = cast(string[string])mimeCollection;
		
		mimes[extension] = mimeType;
		if (isDefault)
			mimes["default"] = mimeType;
			
		mimeCollection = cast(shared(string[string]))mimes;
	}
}

/**
*	Gets a mime type from the collection.
*/
string getMime(string extension) {
	synchronized {
		auto mimes = cast(string[string])mimeCollection;
	
		string mimeType = mimes.get(extension, null);
		if (!mimeType || !mimeType.length)
			mimeType = mimes.get("default", null);
		if (!mimeType || !mimeType.length)
			mimeType = "text/html";
		return mimeType;
	}
}