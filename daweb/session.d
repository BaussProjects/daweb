/*
	Provides a wrapper for a http session / response.
*/
module daweb.session;

/**
*	A http session.
*/
class HttpSession {
private:
	/**
	*	The response header.
	*/
	ubyte[] m_head;
	/**
	*	The response content.
	*/
	ubyte[] m_content;
	/**
	*	Set to true if the data is blocked.
	*/
	bool m_blocked;
public:
	/**
	*	Creates a new instance of HttpSession.
	*/
	this() {
		m_blocked = false;
	}
	
	/**
	*	Redirects the connection.
	*/
	void redirect(string url) {
		m_blocked = true;
		clearHeader();
		clearContent();
		m_head ~= cast(ubyte[])("HTTP/1.0 302 Found\r\nLocation: " ~ url ~ "\r\n");
	}
	
	/**
	*	Adds string data to the header.
	*/
	void addHeader(string data) {
		if (m_blocked)
			return;
		m_head ~= cast(ubyte[])data;
	}
	
	/**
	*	Adds byte data to the header.
	*/
	void addHeader(ubyte[] data) {
		if (m_blocked)
			return;
		m_head ~= data;
	}
	
	/**
	*	Adds string data to the content.
	*/
	void addContent(string data) {
		if (m_blocked)
			return;
		m_content ~= cast(ubyte[])data;
	}
	
	/**
	*	Adds byte data to the content.
	*/
	void addContent(ubyte[] data) {
		if (m_blocked)
			return;
		m_content ~= data;
	}
	
	/**
	*	Clears the header data.
	*/
	void clearHeader() {
		m_head = null;
	}
	
	/**
	*	Clears the content data.
	*/
	void clearContent() {
		m_content = null;
	}
	
	/**
	*	 Finalizes the http packet.
	*/
	ubyte[] finish() {
		ubyte[] finalBuffer;
		if (m_head)
			finalBuffer ~= m_head;
		if (m_content)
			finalBuffer ~= m_content;
		return finalBuffer;
	}
}