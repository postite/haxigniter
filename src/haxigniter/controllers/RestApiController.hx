package haxigniter.controllers;

import haxigniter.libraries.Config;
import haxigniter.libraries.Database;
import haxigniter.libraries.Debug;

import haxigniter.restapi.RestApiRequest;
import haxigniter.restapi.RestApiResponse;

import haxigniter.exceptions.RestApiException;

interface QueryExecutor
{
	function execute(request : RestApiRequest) : RestApiResponse;
}

class RestApiController extends Controller
{
	/**
	 * Handle a page request.
	 * @param	uriSegments Array of request segments (URL splitted with "/")
	 * @param	method Request method, "GET" or "POST" most likely.
	 * @param	params Query parameters
	 * @return  Any value that the controller returns.
	 */
	public override function handleRequest(uriSegments : Array<String>, method : String, query : Hash<String>, rawQuery : String) : Dynamic
	{
		// Extract api version from second segment
		var versionTest = ~/^[vV](\d+)$/;
		if(uriSegments[1] == null || !versionTest.match(uriSegments[1]))
			throw new RestApiException('Invalid API version.');

		var apiVersion : Int = Std.parseInt(versionTest.matched(1));
		
		// Create the request type depending on method
		var requestType : RestRequestType = switch(method)
		{
			case 'POST': RestRequestType.create;
			case 'DELETE': RestRequestType.delete;
			case 'GET': RestRequestType.get;
			case 'PUT': RestRequestType.update;
			default: throw new RestApiException('Invalid request type: ' + method);
		}
		
		// Only one format supported right now
		var format = RestApiFormat.haXigniter;
		
		// Finally, parse the query string.
		var selectors = 
		
		this.trace(uriSegments);
		this.trace(method);
		this.trace(query);
		this.trace(StringTools.urlDecode(rawQuery));
	}
}
