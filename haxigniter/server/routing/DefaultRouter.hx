package haxigniter.server.routing;

import haxigniter.server.Controller;
import haxigniter.server.Config;

import haxigniter.server.libraries.Request;

class DefaultRouter implements Router
{
	public function new() {}
	
	/**
	 * A quite simple router, creates a controller with the same name as the first segment in the url.
	 */ 
	public function createController(config : Config, requestUri : String, queryParams : Hash<String>) : Controller
	{
		var request : Request = new Request(config);		
		var segments = requestUri.split('/');
		
		// Handle the current web request.
		return request.createController(segments[0]);
	}	
}