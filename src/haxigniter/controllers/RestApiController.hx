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
	function handleApiError(message : String, error : RestErrorType, outputFormat : String) : RestResponseOutput;
}

class RestApiController extends Controller, implements RestApiRequestHandler
{
	public var apiRequestHandler : RestApiRequestHandler;

	public var defaultContentType : String;
	public var defaultOutputFormat : String;
	
	public function new(?apiRequestHandler : RestApiRequestHandler)
	{
		defaultContentType = 'application/vnd.haxe.serialized';
		defaultOutputFormat = 'haxigniter';
		
		// Default behavior: If no handler specified and this class is a RestApiRequestHandler, use it.
		if(apiRequestHandler == null && Std.is(this, RestApiRequestHandler))
			this.apiRequestHandler = this;
		else
			this.apiRequestHandler = apiRequestHandler;
	}

	public function handleApiError(message : String, error : RestErrorType, outputFormat : String) : RestResponseOutput
	{
		var outputString = haxe.Serializer.run(RestApiResponse.error(message, error));
		return {contentType: this.defaultContentType, charSet: null, output: outputString};
	}
	
	public function handleApiRequest(request : RestApiRequest) : RestResponseOutput
	{
		return handleApiError('Not implemented yet.', RestErrorType.invalidRequestType, defaultOutputFormat);
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
		var outputFormat : String = null;
		
		// First, urldecode the raw Query.
		rawQuery = StringTools.urlDecode(rawQuery);
		
		try
		{
			// Parse the query string to get the output format early, so it can be used in error handling.
			var output = { format: null };
			
			var selectors = RestApiParser.parse(rawQuery, output);
			outputFormat = output.format == null ? this.defaultOutputFormat : output.format;

			// Extract api version from second segment
			var versionTest = ~/^[vV](\d+)$/;
			if(uriSegments[1] == null || !versionTest.match(uriSegments[1]))
				throw new RestApiException('Invalid API version: ' + uriSegments[1], RestErrorType.invalidApiVersion);

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
			
			
			// Data is the POSTed query, but since it's concatenated with GET, the raw query must be removed...
			// TODO: Is PUT supported for query?
			for(key in query.keys())
			{
				if(rawQuery.indexOf(key) == 0)
					query.remove(key);
			}
			var data = query;

			// Create the RestApiRequest object and pass it along to the handler.
			var request = new RestApiRequest(type, selectors, outputFormat, apiVersion, data);
			
			response = apiRequestHandler.handleApiRequest(request);
		}
		catch(e : RestApiException)
		{
			response = apiRequestHandler.handleApiError(e.message, e.error, outputFormat);
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
