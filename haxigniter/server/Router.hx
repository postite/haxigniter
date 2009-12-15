package haxigniter.server;

import haxigniter.server.libraries.Url;
import haxigniter.server.libraries.Request;

interface Router
{
	/**
	 * Creates a controller from a uri. The haxigniter.server.libraries.Request library is useful here.
	 * @param	config
	 * @param	uri
	 * @return
	 */
	function createController(config : Config, requestUri : String, queryParams : Hash<String>) : Controller;
}

class DefaultRouter implements Router
{
	public function new() {}
	
	/**
	 * A quite simple router, creates a controller with the same name as the first segment in the url.
	 */ 
	public function createController(config : Config, requestUri : String, queryParams : Hash<String>) : Controller
	{
		var url : Url = new Url(config);
		var request : Request = new Request(config);
		
		var segments = url.split(requestUri);
		
		// Handle the current web request.
		return request.createController(segments[0]);
	}	
}