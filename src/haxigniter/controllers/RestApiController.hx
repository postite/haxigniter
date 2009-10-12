package haxigniter.controllers;

#if php
import php.Lib;
import php.Web;
#elseif neko
import neko.Lib;
import neko.Web;
#end

import haxigniter.restapi.RestApiParser;
import haxigniter.restapi.RestApiRequest;
import haxigniter.restapi.RestApiResponse;

import haxigniter.exceptions.RestApiException;

interface RestApiRequestHandler
{
	function handleApiRequest(request : RestApiRequest) : RestResponseOutput;
	function handleApiError(message : String, error : RestErrorType) : RestResponseOutput;
}

class RestApiController extends Controller, implements RestApiRequestHandler
{
	public var apiRequestHandler : RestApiRequestHandler;
	public var defaultContentType : String;
	
	public function new(?apiRequestHandler : RestApiRequestHandler)
	{
		defaultContentType = 'application/vnd.haxe.serialized';
		
		// Default behavior: If no handler specified and this class is a RestApiRequestHandler, use it.
		if(apiRequestHandler == null && Std.is(this, RestApiRequestHandler))
			this.apiRequestHandler = this;
		else
			this.apiRequestHandler = apiRequestHandler;
	}

	public function handleApiError(message : String, error : RestErrorType) : RestResponseOutput
	{
		var outputString = haxe.Serializer.run(RestApiResponse.error(message, error));
		return {contentType: defaultContentType, charSet: null, output: outputString};
	}
	
	public function handleApiRequest(request : RestApiRequest) : RestResponseOutput
	{
		return handleApiError('Not implemented yet.', RestErrorType.invalidRequestType);
	}
	
	/**
	 * Handle a page request.
	 * @param	uriSegments Array of request segments (URL splitted with "/")
	 * @param	method Request method, "GET" or "POST" most likely.
	 * @param	params Query parameters
	 * @return  Any value that the controller returns.
	 */
	public override function handleRequest(uriSegments : Array<String>, method : String, query : Hash<String>, rawQuery : String) : Dynamic
	{
		var response : RestResponseOutput;
		
		// First, urldecode the raw Query according to specs.
		rawQuery = StringTools.urlDecode(rawQuery);
		
		try
		{
			// Extract api version from second segment
			var versionTest = ~/^[vV](\d+)$/;
			if(uriSegments[1] == null || !versionTest.match(uriSegments[1]))
				throw new RestApiException('Invalid API version.', RestErrorType.invalidApiVersion);

			var apiVersion : Int = Std.parseInt(versionTest.matched(1));
			
			// Create the request type depending on method
			var type : RestRequestType = switch(method)
			{
				case 'POST': RestRequestType.create;
				case 'DELETE': RestRequestType.delete;
				case 'GET': RestRequestType.get;
				case 'PUT': RestRequestType.update;
				default: throw new RestApiException('Invalid request type: ' + method, RestErrorType.invalidRequestType);
			}
			
			// Only one format supported right now
			var format = RestApiFormat.haXigniter;
			
			// Data is the POSTed query, but since it's concatenated with GET, the raw query must be removed...
			// TODO: Is PUT supported for query?
			for(key in query.keys())
			{
				if(rawQuery.indexOf(key) == 0)
					query.remove(key);
			}
			var data = query;

			// Finally, parse the query string.
			var selectors = RestApiParser.parse(rawQuery);
			
			// Create the RestApiRequest object and pass it along to the handler.
			var request = new RestApiRequest(type, selectors, format, apiVersion, data);
			
			response = apiRequestHandler.handleApiRequest(request);
		}
		catch(e : RestApiException)
		{
			response = apiRequestHandler.handleApiError(e.message, e.error);
		}

		// Format the final output according to response and send it to the client.
		var header = [];
		
		if(response.contentType != null)
			header.push(response.contentType);
		if(response.charSet != null)
			header.push('charset=' + response.charSet);
		
		if(header.length > 0)
			Web.setHeader('Content-Type', header.join('; '));

		Lib.print(response.output);
	}
}
