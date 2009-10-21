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
import haxigniter.restapi.RestApiAuthorization;

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
	public var apiAuthorization : RestApiAuthorization;

	public var noOutput : Bool;
	public var debugMode : haxigniter.libraries.DebugLevel;
	
	private var viewTranslations : Hash<Hash<String>>;

	public function new(?apiRequestHandler : RestApiRequestHandler, ?apiAuthorization : RestApiAuthorization)
	{
		// Default behavior: If no handler specified, use a RestApiSqlRequestHandler.
		if(apiRequestHandler == null)
			this.apiRequestHandler = new haxigniter.restapi.RestApiSqlRequestHandler(this.db);
		else
			this.apiRequestHandler = apiRequestHandler;
		
		this.apiAuthorization = apiAuthorization;
		
		this.viewTranslations = new Hash<Hash<String>>();
		this.noOutput = false;
	}

	private function translateView(resourceName : String, viewName : String) : String
	{
		if(!this.viewTranslations.exists(resourceName))
			throw new RestApiException('Resource "' + resourceName + '" not found for view "' + viewName + '"', RestErrorType.invalidQuery);
		
		var views = this.viewTranslations.get(resourceName);
		
		if(!views.exists(viewName))
			throw new RestApiException('View "' + viewName + '" not found in resource "' + resourceName + '"', RestErrorType.invalidQuery);
		
		return views.get(viewName);
	}
	
	public function addView(resourceName : String, viewName : String, viewTranslation : String) : Void
	{
		var views : Hash<String>;
		if(!this.viewTranslations.exists(resourceName))
		{
			views = new Hash<String>();
			this.viewTranslations.set(resourceName, views);
		}
		else
			views = this.viewTranslations.get(resourceName);
		
		views.set(viewName, viewTranslation);
	}
	
	private function parsedSegmentToResource(segment : RestApiParsedSegment) : RestApiResource
	{
		switch(segment)
		{
			case one(name, id):
				// Create a selector where id=X
				return { name: name, selectors: [RestApiSelector.attribute('id', RestApiSelectorOperator.equals, Std.string(id))] };
			
			case all(name):
				// Create an resource with only name, no selectors.
				return { name: name, selectors: [] };
			
			case view(name, viewName):
				// Translate the view to a selector string and parse it.
				return this.parsedSegmentToResource(RestApiParser.parseSelector(name, this.translateView(name, viewName)));
				
			case some(name, selectors):
				// Selectors are parsed already, just pass them on.
				return {name: name, selectors: selectors};
		}
	}
	
	/**
	 * Handle a page request.
	 * @param	uriSegments Array of request segments (URL splitted with "/")
	 * @param	method Request method, "GET" or "POST" most likely.
	 * @param	params Query parameters
	 * @return  Any value that the controller returns.
	 */
	public override function handleRequest(uriSegments : Array<String>, method : String, query : Hash<String>, rawQuery : String, ?rawRequestData : String) : Dynamic
	{
		var response : RestApiResponse;
		var outputFormat : RestApiFormat = null;

		// Prepare for eventual debugging
		var oldTraceQueries = this.db.traceQueries;
		
		// Strip the api query from the query hash before urldecoding the raw query.
		for(getParam in query.keys())
		{
			if(getParam.indexOf('/') > = 0)
			{
				query.remove(getParam);
				break;
			}
		}
		
		// Then strip everything after (and including) the first &.
		if(rawQuery.indexOf('&') >= 0)
			rawQuery = rawQuery.substr(0, rawQuery.indexOf('&'));

		// Finally, urldecode the query so it can be parsed.
		rawQuery = StringTools.urlDecode(rawQuery);

		try
		{
			// Parse the query string to get the output format early, so it can be used in error handling.
			var output = { format: null };
			
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
			var type : RestApiRequestType = switch(method)
			{
				case 'POST': RestApiRequestType.create;
				case 'DELETE': RestApiRequestType.delete;
				case 'GET': RestApiRequestType.read;
				case 'PUT': RestApiRequestType.update;
				default: throw new RestApiException('Invalid request type: ' + method, RestErrorType.invalidRequestType);
			}
			
			// TODO: User authorization, with the help of query.
			
			// Parse the raw query
			var selectors = RestApiParser.parse(rawQuery, output);
			
			// Create the RestApiRequest object and pass it along to the handler.
			var request = new RestApiRequest(
				type, 
				Lambda.array(Lambda.map(selectors, this.parsedSegmentToResource)), 
				outputFormat, 
				apiVersion, 
				query, 
				(rawRequestData == null) ? Web.getPostData() : rawRequestData
				);
			
			// Debugging
			if(this.debugMode != null)
			{
				this.db.traceQueries = this.debugMode;		
				this.trace(request);
			}
			
			// If authorization exists, it must go through.
			if(apiAuthorization != null && !apiAuthorization.authorizeRequest(request))
				throw new RestApiException('Unauthorized request.', RestErrorType.unauthorizedRequest);
			
			response = apiRequestHandler.handleApiRequest(request);
		}
		catch(e : RestApiException)
		{
			response = RestApiResponse.failure(e.message, e.error);
		}
		catch(e : Dynamic)
		{
			response = RestApiResponse.failure(Std.string(e), RestErrorType.unknown);
		}
		
		var finalOutput : RestResponseOutput = apiRequestHandler.outputApiResponse(response, outputFormat);

		// Debugging
		if(this.debugMode != null)
		{
			this.trace(RestApiDebug.responseToString(response));
			this.trace(finalOutput);
			this.db.traceQueries = oldTraceQueries;
		}
		
		if(!this.noOutput)
		{
			// Format the final output according to response and send it to the client.
			var header = [];
			
			if(finalOutput.contentType != null)
				header.push(finalOutput.contentType);
			if(finalOutput.charSet != null)
				header.push('charset=' + finalOutput.charSet);
			
			if(header.length > 0 && this.debugMode == null)
				Web.setHeader('Content-Type', header.join('; '));

			if(this.debugMode == null)
				Lib.print(finalOutput.output);
		}
		
		return finalOutput;
	}
}
