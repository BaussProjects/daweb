/*
	Provides a http request wrapper.
	
	Author: Bauss
*/
module daweb.request;

import std.conv : to;
import std.algorithm;
import std.array;
import std.string;

import daweb.mime;

/**
*	The default page.
*/
private const string defaultPage = "index.html";

/**
*	A http request wrapper.
*/
class HttpRequest {
private:
	/**
	*	The post data.
	*/
	string[string] m_postData;
	/**
	*	The query string data.
	*/
	string[string] m_queryString;
	/**
	*	Set to true if the request is a post back.
	*/
	bool m_post;
	
	/**
	*	The http version.
	*/
	string m_httpVersion;
	/**
	*	The host IP.
	*/
	string m_hostIP;
	/**
	*	The host port.
	*/
	ushort m_hostPort;
	/**
	*	The user agent.
	*/
	string m_userAgent;
	/**
	*	The accept type.
	*/
	string m_acceptType;
	/**
	*	The accept language.
	*/
	string m_acceptLanguage;
	/**
	*	The accept encoding.
	*/
	string m_acceptEncoding;
	/**
	*	Whether or not the connection should be kept alive.
	*/
	bool m_keepAlive;
	/**
	*	The request path.
	*/
	string m_requestPath;
	/**
	*	The remote address.
	*/
	string m_remoteAddress;
	/**
	*	The mime type.
	*/
	string m_mime;
	
	/**
	*	Set to true if the request is valid.
	*/
	bool m_valid;
public:
	/**
	* Creates a new instance of HttpRequest.
	*/
	this(string ip, string head) {
		m_remoteAddress = ip;
		
		string httpHead = head.dup;
		httpHead = replace(httpHead, "\r", "");
		
		bool foundMethod = false;
		
		auto lines = split(httpHead, "\n");
		foreach (line; lines) {
			if (!line)
				continue;
			if (!line.length)
				continue;
			if (line == "")
				continue;
			
			if (!foundMethod) {
				auto methodData = split(line, " ");
				if (methodData.length == 3) {
					if (methodData[0] == "POST") {
						m_post = true;
						foundMethod = true;
					}
					else if (methodData[0] == "GET") {
						m_post = false;
						foundMethod = true;
					}
					
					if(methodData[1] == "/") {
						m_requestPath = defaultPage;
					}
					else {
						if (canFind(methodData[1], "?")) {
							auto pageData = split(methodData[1], "?");
							m_requestPath = pageData[0];
							
							auto queries = split(pageData[1], "&");
							foreach (query; queries) {
								auto queryData = split(query, "=");
								m_queryString[queryData[0]] = queryData[1];
							}
						}
						else
							m_requestPath = methodData[1];
					}
					
					auto fileData = split(m_requestPath, ".");
					m_mime = getMime(fileData[$-1]);
				}
			}
			else if (canFind("&", line) && m_post) {
				auto postDatas = split(line, "&");
				foreach (post; postDatas) {
					if (!canFind(post, "="))
						continue;
				
					auto postData = split(post, "=");
					m_postData[postData[0]] = postData[1];
				}
			}
			else {
				auto headData = split(line, ": ");
				if (headData.length == 2)
				{
					switch (toLower(headData[0]))
					{
						case "host":
						{
							auto hostData = split(headData[1], ":");
							m_hostIP = hostData[0];
							m_hostPort = to!ushort(hostData[1]);
							break;
						}
						case "user-agent":
							m_userAgent = headData[1];
							break;
						case "accept":
							m_acceptType = headData[1];
							break;
						case "accept-language":
							m_acceptLanguage = headData[1];
							break;
						case "accept-encoding":
							m_acceptEncoding = headData[1];
							break;
						case "connection":
							m_keepAlive = (headData[1] == "keep-alive");
							break;
						default:
							break;
					}
				}
			}
		}
		m_valid = foundMethod;
	}
	
	@property {
		/**
		*	Gets the post data.
		*/
		string[string] postData() { return m_postData; }
		/**
		*	Gets the query string.
		*/
		string[string] queryString() { return m_queryString; }
		/**
		*	Returns true if it's post back.
		*/
		bool isPost() { return m_post; }
		
		/**
		*	Gets the http version.
		*/
		string httpVersion() { return m_httpVersion; }
		/**
		*	Gets the host IP.
		*/
		string hostIP() { return m_hostIP; }
		/**
		*	Gets the host port.
		*/
		ushort hostPort() { return m_hostPort; }
		/**
		*	Gets the user agent.
		*/
		string userAgent() { return m_userAgent; }
		/**
		*	Gets the accept type.
		*/
		string acceptType() { return m_acceptType; }
		/**
		*	Gets the accept language.
		*/
		string acceptLanguage() { return m_acceptLanguage; }
		/**
		*	Returns true if the connection should be kept alive.
		*/
		bool keepAlive() { return m_keepAlive; }
		/**
		*	Gets the request path.
		*/
		string requestPath() { return m_requestPath; }
		/**
		*	Gets the remote address.
		*/
		string remoteAddress() { return m_remoteAddress; }
		/**
		*	Gets the mime type.
		*/
		string mime() { return m_mime; }
		
		/**
		*	Returns true if the request is valid.
		*/
		bool valid() { return m_valid; }
	}
}