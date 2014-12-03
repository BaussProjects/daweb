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
	import std.stdio;
	
	if (request.contentLength > 0) {
		ubyte[] buf = httpClient.waitReceive(request.contentLength);
		if (buf) {
			if (buf.length > 0) {
				string content = cast(string)buf;
			}
		}
	}
	
	if (!exists("www\\" ~ request.requestPath) || endsWith(request.requestPath, ".d")) {
		string html = "<html><head><title>404</title></head><body><p>File Not Found!</p></body></html>";
		
		auto session = new HttpSession;
		session.addHeader("HTTP/1.0 200 OK\r\n");
		session.addHeader("Content-Type: " ~ request.mime ~ "\r\n");
			
		if (exists("www\\error.dml")) {
			request.addQueries(["type=404","page=" ~ request.requestPath]);
			
			html = readText("www\\error.dml");
			html = processScript(httpClient, request, session, "www\\error.dml.d", html);
		}
		
		session.addHeader("Content-Length: " ~ to!string(html.length) ~ "\r\n\r\n");
		session.addContent(html);
		httpClient.send(session.finish());
		httpClient.close();
		return;
	}
	
	if (request.mime == "text/html" || request.mime == "text/css" || request.mime == "text/xml") {
		auto session = new HttpSession;
		session.addHeader("HTTP/1.0 200 OK\r\n");
		session.addHeader("Content-Type: " ~ request.mime ~ "\r\n");
		
		string html = readText("www\\" ~ request.requestPath);
		if (endsWith(request.requestPath, ".dml"))
			html = processScript(httpClient, request, session, "www\\" ~ request.requestPath ~ ".d", html);
			
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
		
		ubyte[] img = cast(ubyte[])read("www\\" ~ request.requestPath);
		session.addHeader("Content-Length: " ~ to!string(img.length) ~ "\r\n\r\n");
		httpClient.send(session.finish());
		httpClient.send(img);
	}
	
	httpClient.close();
}

/**
*	Processes the script in the html blocks.
*/
string processScript(AsyncTcpSocket httpClient, HttpRequest request, HttpSession session, string dmlFile, string html) {
	import std.process;
	import std.file;
	import std.array;
	import std.stdio : writeln;

	if (!exists(dmlFile))
		return html;

	string id = to!string(httpClient.socketId);
	write(id ~ ".dml", html);
	string dCode = readText(dmlFile);
	
	string[] templates = [
		"module main;",
		"import std.file;",
		"void main(string[] args) {",
		"string id = args[$-1];",
		"string path = args[$-2];",
		"string htmlFile = path ~ id ~ \".dml\";",
		"@VARS",
		"if (exists(htmlFile)) {",
		"@FUNCS",
		"string html = readText(htmlFile);",
		"@CODE",
		"write(htmlFile, html);",
		"}",
		"}"
	];
	string templateCode = join(templates, "\r\n");
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
	if (wait(pid) != 0)
		writeln("Compilation failed for ", dmlFile);
	
	if (exists(id ~ ".d"))
		remove(id ~ ".d");
	if (exists(id ~ ".obj"))
		remove(id ~ ".obj");
	if (exists(id ~ ".exe"))
		remove(id ~ ".exe");
	if (exists(id ~ ".dml")) {
		html = readText(id ~ ".dml");
		remove(id ~ ".dml");
	}
	if (exists(id ~ ".red")) {
		string r = "{R}" ~ readText(id ~ ".red");
		remove(id ~ ".red");
		html = r;
	}
		
	return html;
}