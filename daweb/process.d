/*
	Provides processing for the http request and response.
	
	Author: Bauss
*/
module daweb.process;

import std.conv : to;
import std.file;
import std.algorithm;

import dasocks;

import daweb.session;
import daweb.request;

/**
*	Processes a http request.
*/
void processHttp(AsyncTcpSocket httpClient, HttpRequest request) {
	if (!exists("www\\" ~ request.requestPath)) {
		// 404
		return;
	}
	
	if (request.mime == "text/html" || request.mime == "text/css" || request.mime == "text/xml") {
		auto session = new HttpSession;
		session.addHeader("HTTP/1.0 200 OK\r\n");
		session.addHeader("Content-Type: " ~ request.mime ~ "\r\n");
		
		string html = readText("www\\" ~ request.requestPath);
		session.addHeader("Content-Length: " ~ to!string(html.length) ~ "\r\n\r\n");
		session.addContent(html);
		httpClient.send(session.finish());
	}
	else if (startsWith(request.mime, "image/")) {
		auto session = new HttpSession;
		session.addHeader("HTTP/1.0 200 OK\r\n");
		session.addHeader("Content-Type: " ~ request.mime ~ "\r\n");
		
		ubyte[] img = cast(ubyte[])read("www\\" ~ request.requestPath);
		session.addHeader("Content-Length: " ~ to!string(img.length) ~ "\r\n\r\n");
		//session.addContent(html);
		httpClient.send(session.finish());
		httpClient.send(img);
	}
	
	httpClient.close();
}