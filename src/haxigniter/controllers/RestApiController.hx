package haxigniter.controllers;

#if php
import php.Lib;
import php.Web;
#elseif neko
import neko.Lib;
import neko.Web;
#end

import haxigniter.libraries.DebugLevel;

import haxigniter.restapi.RestApiInterface;
import haxigniter.restapi.RestApiParser;
import haxigniter.restapi.RestApiRequest;
import haxigniter.restapi.RestApiResponse;
import haxigniter.restapi.RestApiAuthorization;
import haxigniter.restapi.RestApiOutputHandler;

import haxigniter.exceptions.RestApiException;

class RestApiController extends Controller, implements RestApiOutputHandler
{
	public static var commonMimeTypes = {
		haxigniter: 'application/vnd.haxe.serialized', 
		xml: 'application/xml',
		xhtml: 'application/xhtml+xml',
		html: 'text/html',
		json: 'application/json'
	};
	
	public var apiRequestHandler : RestApiRequestHandler;
	public var apiOutputHandler : RestApiOutputHandler;
	//public var apiAuthorization : RestApiAuthorization;

	public var noOutput : Bool;
	public var debugMode : DebugLevel;
	public var logLevel : DebugLevel;
	
	public function new(?apiRequestHandler : RestApiRequestHandler, ?apiOutputHandler : RestApiOutputHandler)// , ?apiAuthorization : RestApiAuthorization)
	{
		// Default behavior: If no request handler specified, use a RestApiSqlRequestHandler.
		if(apiRequestHandler == null)
			this.apiRequestHandler = new haxigniter.restapi.RestApiSqlRequestHandler(this.db);
		else
			this.apiRequestHandler = apiRequestHandler;

		// Default behavior: If no output handler specified, use itself, which handles haxigniter format (serialized).
		if(apiOutputHandler == null)
		{
			this.apiOutputHandler = this;
			this.outputFormats = ['haxigniter'];
		}
		else
			this.apiOutputHandler = apiOutputHandler;

		//this.apiAuthorization = apiAuthorization;
		
		this.logLevel = DebugLevel.error;
		this.viewTranslations = new Hash<Hash<String>>();
		this.noOutput = false;
	}
	
	///// RestApiOutputHandler implementation ///////////////////////

	// Set in constructor to haxigniter, the only format supported by RestApiController.
	public var outputFormats(default, null) : Array<RestApiFormat>;

	public function outputApiResponse(response : RestApiResponse, outputFormat : RestApiFormat) : RestResponseOutput
	{
		return {
			contentType: commonMimeTypes.haxigniter,
			charSet: null,
			output: haxe.Serializer.run(response)
		};
	}

	private static var apiRequestPattern = ~/^.*?\/[vV](\d+)\/\?(\/[^&]+)&?(.*)/;
	private static var apiFormatPattern = ~/\/\w+\.(\w+)\//;
	
	private function parseUrl(url : String) : { api: Int, query: String, parameters: Hash<String>, format: RestApiFormat }
	{
		if(!apiRequestPattern.match(url))
			return null;
		else
		{
			var query = apiRequestPattern.matched(2);
			var format : RestApiFormat = null;
			
			// Parse format from query, if any.
			// The slash prepending the query is kept so this pattern can detect the format:
			if(apiFormatPattern.match(query))
			{
				format = apiFormatPattern.matched(1);
				//throw new RestApiException('Multiple output formats specified: "' + outputFormat + '" and "' + resourceData[1] + '".', RestErrorType.invalidOutputFormat);
			}
			
			var parameters = haxigniter.libraries.Input.parseQuery(apiRequestPattern.matched(3));
			
			if(StringTools.endsWith(query, '/'))
				query = query.substr(0, query.length - 1);			
			
			return { api: Std.parseInt(apiRequestPattern.matched(1)), query: query.substr(1), parameters: parameters, format: format };
		}
	}
	
	/////////////////////////////////////////////////////////////////

	private function sendRequest(apiVersion : Int, type : RestApiRequestType, query : String, data : Hash<String>, queryParameters : Hash<String>) : RestApiResponse
	{
		// Urldecode the query so it can be parsed.
		query = StringTools.urlDecode(query);

		try
		{
			// Parse the query
			var selectors = RestApiParser.parse(query);

			// Create the RestApiRequest object and pass it along to the handler.
			var request = new RestApiRequest(
				type, 
				Lambda.array(Lambda.map(selectors, this.parsedSegmentToResource)), 
				apiVersion, 
				queryParameters, 
				data
				);
			
			// Debugging
			var oldTraceQueries = this.db.traceQueries;
			
			if(this.debugMode != null)
			{
				this.db.traceQueries = this.debugMode;				
				this.trace(request);
			}
			
			var response = apiRequestHandler.handleApiRequest(request);

			// Debugging
			if(this.debugMode != null)
			{
				this.db.traceQueries = oldTraceQueries;
			}

			return response;
		}
		catch(e : RestApiException)
		{
			return RestApiResponse.failure(e.message, e.error);
		}
		catch(e : Dynamic)
		{
			if(!this.config.development)
			{
				// Log the error if logLevel is high enough for the controller
				haxigniter.libraries.Debug.log(e, this.logLevel);
				return RestApiResponse.failure('An unknown error occured.', RestErrorType.unknown);
			}
			else
				return RestApiResponse.failure(Std.string(e), RestErrorType.unknown);
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
		var urlParts : { api: Int, query: String, parameters: Hash<String>, format: RestApiFormat } = this.parseUrl(uriSegments.join('/') + '/?' + rawQuery);

		// Test if format is supported by the output handler.
		if(urlParts.format != null && !Lambda.has(apiOutputHandler.outputFormats, urlParts.format))
		{
			response = RestApiResponse.failure('Invalid output format: ' + urlParts.format, RestErrorType.invalidOutputFormat);
		}
		else
		{
			if(urlParts.format == null)
				urlParts.format = apiOutputHandler.outputFormats[0];
		
			// Convert the raw request data to hash
			if(rawRequestData == null)
				rawRequestData = Web.getPostData();
			
			var requestData = (rawRequestData != null) ? haxigniter.libraries.Input.parseQuery(rawRequestData) : new Hash<String>();

			// Create the request type depending on method
			var type = switch(method)
			{
				case 'POST': RestApiRequestType.create;
				case 'DELETE': RestApiRequestType.delete;
				case 'GET': RestApiRequestType.read;
				case 'PUT': RestApiRequestType.update;
				default: null;
			}
			
			if(type == null)
				response = RestApiResponse.failure('Invalid request type: ' + method, RestErrorType.invalidRequestType);
			else
			{
				// Make the request.
				response = this.sendRequest(urlParts.api, type, urlParts.query, requestData, urlParts.parameters);
			}
		}
		
		var finalOutput : RestResponseOutput = apiOutputHandler.outputApiResponse(response, urlParts.format);

		// Debugging
		if(this.debugMode != null)
		{
			this.trace(RestApiDebug.responseToString(response));
			this.trace(finalOutput);
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

	///// View translations /////////////////////////////////////////
	
	private var viewTranslations : Hash<Hash<String>>;

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

	/////////////////////////////////////////////////////////////////
	
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
}
