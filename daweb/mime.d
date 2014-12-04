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
*	Loads the mime types from conf\\mime.ini
*/
void loadMime() {
	import daweb.settings;
	auto mimeDat = getFile("mime.ini");
	if (!mimeDat.exists()) {
		addMime(".dml", "text/html", true);
	}
	else {
		mimeDat.open();
		foreach (key; mimeDat.keys)
			addMime(key, mimeDat.read!string(key));
	}
	mimeDat.close();
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