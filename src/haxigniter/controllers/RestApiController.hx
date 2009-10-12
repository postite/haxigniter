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

class RestApiController extends Controller
{
	public static var commonMimeTypes = {
		haxigniter: 'application/vnd.haxe.serialized', 
		xml: 'application/xml',
		xhtml: 'application/xhtml+xml',
		html: 'text/html',
		json: 'application/json'
	};
	
	public var apiRequestHandler : RestApiRequestHandler;

	public function new(?apiRequestHandler : RestApiRequestHandler)
	{
		// Default behavior: If no handler specified and this class is a RestApiRequestHandler, use it.
		if(apiRequestHandler == null)
			this.apiRequestHandler = new haxigniter.restapi.RestApiSqlFactory();
		else
			this.apiRequestHandler = apiRequestHandler;
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
		var response : RestApiResponse;
		var outputFormat : String = null;
		
		// First, urldecode the raw Query.
		rawQuery = StringTools.urlDecode(rawQuery);
		
		try
		{
			// Parse the query string to get the output format early, so it can be used in error handling.
			var output = { format: null };			
			var selectors = RestApiParser.parse(rawQuery, output);
			
			if(output.format != null)
			{
				// Test if format is supported by the request handler.
				if(!Lambda.has(apiRequestHandler.supportedOutputFormats, outputFormat))
					throw new RestApiException('Invalid output format: ' + outputFormat, RestErrorType.invalidOutputFormat);
				
				outputFormat = output.format;
			}
			else
				outputFormat = apiRequestHandler.supportedOutputFormats[0];

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
			
			// Get the raw posted data.
			var data : String = Web.getPostData();

			// Create the RestApiRequest object and pass it along to the handler.
			var request = new RestApiRequest(type, selectors, outputFormat, apiVersion, data);
			
			response = apiRequestHandler.handleApiRequest(request);
		}
		catch(e : RestApiException)
		{
			response = RestApiResponse.failure(e.message, e.error);
		}
		catch(e : Dynamic)
		{
			response = RestApiResponse.failure(Std.string(e), RestErrorType.internal);
		}
		
		var finalOuput : RestResponseOutput = apiRequestHandler.outputApiResponse(response, outputFormat);

		// Format the final output according to response and send it to the client.
		var header = [];
		
		if(finalOuput.contentType != null)
			header.push(finalOuput.contentType);
		if(finalOuput.charSet != null)
			header.push('charset=' + finalOuput.charSet);
		
		//if(header.length > 0)
			//Web.setHeader('Content-Type', header.join('; '));

		Lib.print(finalOuput.output);
	}
}
