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
import daweb.tools : selectUntil, isBlank;
import daweb.settings;

/**
*	Processes a http request.
*/
void processHttp(AsyncTcpSocket httpClient, HttpRequest request) {
	import std.stdio : writeln;
	auto settings = getSettings();
	string webFolder = settings.read!string("WebFolder") ~ "\\";
	
	if (request.contentLength > 0) {
		import std.stdio;
		writeln(request.contentLength);
		//ubyte[] buf = httpClient.waitReceive(request.contentLength);
		//if (buf) {
		//	if (buf.length > 0) {
		//		string content = cast(string)buf;
		//		TODO: handle content
		//		FIX: handle encoding types for forms
		//	}
		//}
	}
	
	if (!exists(webFolder ~ request.requestPath)) {
		string html = "<html><head><title>404</title></head><body><p>File Not Found!</p></body></html>";
		
		auto session = new HttpSession;
		session.addHeader("HTTP/1.0 200 OK\r\n");
		session.addHeader("Content-Type: " ~ request.mime ~ "\r\n");
			
		if (exists(webFolder ~ "\\error.d")) {
			request.addQueries(["type=404","page=" ~ request.requestPath]);
			
			html = readText(webFolder ~ "\\error.d");
			
			if (!startsWith(html, "<html>")) {
				size_t nextIndex;
				string dCode = selectUntil(html, 0, "<html>", nextIndex);
				html = html[nextIndex .. $];
	
				html = processScript(httpClient, request, session, dCode, html, webFolder ~ "\\error.d");
			}
		}
		
		session.addHeader("Content-Length: " ~ to!string(html.length) ~ "\r\n\r\n");
		session.addContent(html);
		httpClient.send(session.finish());
		return;
	}
	
	if (request.mime == "text/html" || request.mime == "text/css" || request.mime == "text/xml") {
		auto session = new HttpSession;
		session.addHeader("HTTP/1.0 200 OK\r\n");
		session.addHeader("Content-Type: " ~ request.mime ~ "\r\n");
		
		string html = readText(webFolder ~ "\\" ~ request.requestPath);
		if (endsWith(request.requestPath, ".d")) {
			if (!startsWith(html, "<html>")) {
				size_t nextIndex;
				string dCode = selectUntil(html, 0, "<html>", nextIndex);
				html = html[nextIndex .. $];
	
				html = processScript(httpClient, request, session, dCode, html, request.requestPath);
			}
		}
		
		if (startsWith(html, "{R}") && html.length > 3) {
			string redirect = html[3 .. $];
			session.redirect(redirect);
		}
		
		session.addHeader("Content-Length: " ~ to!string(html.length) ~ "\r\n\r\n");
		session.addContent(html);
		httpClient.send(session.finish());
	}
	else if (startsWith(request.mime, "image/")) {
		auto session = new HttpSession;
		session.addHeader("HTTP/1.0 200 OK\r\n");
		session.addHeader("Content-Type: " ~ request.mime ~ "\r\n");
		
		ubyte[] img = cast(ubyte[])read(webFolder ~ "\\" ~ request.requestPath);
		session.addHeader("Content-Length: " ~ to!string(img.length) ~ "\r\n\r\n");
		httpClient.send(session.finish());
		httpClient.send(img);
	}
}

/**
*	Processes the script in the html blocks.
*/
string processScript(AsyncTcpSocket httpClient, HttpRequest request, HttpSession session, string dCode, string html, string dFile) {
	auto settings = getSettings();
	if (!settings.read!bool("UseDScripts"))
		return html;

	import std.process;
	import std.file;
	import std.array;
	import std.stdio : writeln;

	if (isBlank(dCode))
		return html;

	string id = to!string(httpClient.socketId);
	write(id ~ ".dml", html);
	
	string templateCode = readText("conf\\template.d");
	
	bool RootFileModificationOnly = settings.read!bool("RootFileModificationOnly");
	templateCode = replace(templateCode, "@RootFileModificationOnly", to!string(RootFileModificationOnly));	
	templateCode = replace(templateCode, "@WebFolder", settings.read!string("WebFolder"));
	
	templateCode = replace(templateCode, "@VARS", request.toDVariables());
	string funcs;
	foreach (string name; dirEntries("funcs", SpanMode.depth))
	{
		if (endsWith(name, ".d"))
			funcs ~= readText(name) ~ "\r\n";
	}
	templateCode = replace(templateCode, "@FUNCS", funcs);
	templateCode = replace(templateCode, "@CODE", dCode);
	write(id ~ ".d", templateCode);
	
	string exePath = thisExePath;
	auto pathSplit = split(exePath, "\\");
	exePath = "";
	foreach (i; 0 .. pathSplit.length) {
		if (i == (pathSplit.length - 1))
			break;
		exePath ~= pathSplit[i] ~ "\\";
	}
	
	auto pid = spawnProcess(["dmd", "-run", exePath ~ id ~ ".d", exePath, id],
                        std.stdio.stdin,
                        std.stdio.stdout,
                        std.stdio.stderr);
	bool valid = (wait(pid) == 0);
	if (!valid) {
		writeln("Compilation failed for ", dFile);
	}
	
	if (exists(id ~ ".d"))
		remove(id ~ ".d");
	if (exists(id ~ ".obj"))
		remove(id ~ ".obj");
	if (exists(id ~ ".exe"))
		remove(id ~ ".exe");
	if (exists(id ~ ".dml")) {
		if (valid)
			html = readText(id ~ ".dml");
		remove(id ~ ".dml");
	}
	if (exists(id ~ ".red")) {
		string r = "{R}" ~ readText(id ~ ".red");
		remove(id ~ ".red");
		if (valid)
			html = r;
	}
		
	return html;
}