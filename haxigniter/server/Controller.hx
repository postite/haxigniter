package haxigniter.server;

import haxigniter.libraries.Config;
import haxigniter.server.request.RequestHandler;

interface Controller
{
	/**
	 * Contains the request handler that specifies how the controller will be used in the Application.
	 */
	var requestHandler(default, null) : RequestHandler;
}
