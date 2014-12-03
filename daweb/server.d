/*
	Provides the base functionality of the asynchronous web server.
	
	Author: Bauss
*/
module daweb.server;

import std.socket : InternetAddress;
import std.stdio : writeln;

import dasocks;

import daweb.mime;

/**
*	Starts and runs the web server.
*/
void run(string ip, ushort port) {
	loadMime();
	
    auto server = new AsyncTcpSocket;
    server.setEvents(new AsyncSocketEvent(&onAccept), new AsyncSocketEvent(&onReceive), new AsyncSocketEvent(&onDisconnect));
    server.beginAccept();
    server.bind(new InternetAddress(ip, port));
    server.listen(500);
}

/**
*	The event called when a connection is accepted.
*/
private void onAccept(AsyncTcpSocket server) {
    auto socket = server.endAccept();
    socket.beginReceive(4096);

    server.beginAccept();
}

/**
*	The event called when a packet is received.
*/
private void onReceive(AsyncTcpSocket client) {
    import std.algorithm : stripRight;

    ubyte[] buffer = client.endReceive();
	buffer = stripRight(buffer, 0);
	
	import daweb.process;
	import daweb.request;
	try {
	processHttp(client, new HttpRequest(client.socket.remoteAddress().toString(), cast(string)buffer));
	} catch (Throwable t) {
		writeln("ERROR");
		writeln(t);
	}
	client.close();
}

/**
*	The event called when a disconnection occures.
*/
private void onDisconnect(AsyncTcpSocket socket) {
    if (socket.listening) {
        writeln("The server was shutdown!");
    }
    else {
    }
}