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
import haxigniter.restapi.RestApiSecurityHandler;
import haxigniter.restapi.RestApiFormatHandler;

import haxigniter.exceptions.RestApiException;

class RestApiController extends Controller, implements RestApiFormatHandler, implements RestApiInterface
{
	public static var commonMimeTypes = {
		haxigniter: 'application/vnd.haxe.serialized', 
		xml: 'application/xml',
		xhtml: 'application/xhtml+xml',
		html: 'text/html',
		json: 'application/json'
	};
	
	public var apiRequestHandler : RestApiRequestHandler;
	public var apiFormatHandler : RestApiFormatHandler;
	public var apiSecurityHandler : RestApiSecurityHandler;

	public var noOutput : Bool;
	public var debugMode : DebugLevel;
	public var logLevel : DebugLevel;
	
	public function new(apiSecurityHandler : RestApiSecurityHandler, ?apiRequestHandler : RestApiRequestHandler, ?apiFormatHandler : RestApiFormatHandler)
	{
		// If no request handler specified, use a RestApiSqlRequestHandler.
		if(apiRequestHandler == null)
			this.apiRequestHandler = new haxigniter.restapi.RestApiSqlRequestHandler(this.db);
		else
			this.apiRequestHandler = apiRequestHandler;

		// If no format handler specified, use itself, which handles haxigniter format (serialized).
		if(apiFormatHandler == null)
		{
			this.apiFormatHandler = this;
			this.restApiFormats = ['haxigniter'];
		}
		else
			this.apiFormatHandler = apiFormatHandler;

		// A SecurityHandler must be specified.
		this.apiSecurityHandler = apiSecurityHandler;
		this.apiSecurityHandler.install(this);
		
		this.logLevel = DebugLevel.error;
		this.viewTranslations = new Hash<Hash<String>>();
		this.noOutput = false;
	}
	
	///// RestApiInterface implementation ///////////////////////////
	
	public function create(url : String, data : Dynamic, callBack : RestApiResponse -> Void) : Void
	{
		restApiRequest(url, data, callBack, RestApiRequestType.create);
	}
	
	public function read(url : String, callBack : RestApiResponse -> Void) : Void
	{
		restApiRequest(url, null, callBack, RestApiRequestType.read);
	}
	
	public function update(url : String, data : Dynamic, callBack : RestApiResponse -> Void) : Void
	{
		restApiRequest(url, data, callBack, RestApiRequestType.update);
	}
	
	public function delete(url : String, callBack : RestApiResponse -> Void) : Void
	{
		restApiRequest(url, null, callBack, RestApiRequestType.delete);
	}
	
	private function restApiRequest(url : String, data : Dynamic, callBack : RestApiResponse -> Void, requestType : RestApiRequestType) : Void
	{
		var urlData = parseUrl(url);
		callBack(sendRequest(urlData.api, requestType, urlData.query, data, urlData.parameters));		
	}

	///// RestApiFormatHandler implementation ///////////////////////

	// Set in constructor to haxigniter, the only format supported by RestApiController.
	public var restApiFormats(default, null) : Array<RestApiFormat>;

	public function restApiInput(data : String, inputFormat : RestApiFormat) : Dynamic
	{
		if(data == '') 
			return null;
		else 
			return haxe.Unserializer.run(data);
	}
	
	public function restApiOutput(response : RestApiResponse, outputFormat : RestApiFormat) : RestResponseOutput
	{
		return {
			contentType: commonMimeTypes.haxigniter,
			charSet: null,
			output: haxe.Serializer.run(response)
		};
	}
	
	/////////////////////////////////////////////////////////////////

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

	private function sendRequest(apiVersion : Int, type : RestApiRequestType, query : String, data : Dynamic, queryParameters : Hash<String>) : RestApiResponse
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
			
			var response = apiRequestHandler.handleApiRequest(request, this.apiSecurityHandler);

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
		if(urlParts.format != null && !Lambda.has(apiFormatHandler.restApiFormats, urlParts.format))
		{
			response = RestApiResponse.failure('Non-supported format: ' + urlParts.format, RestErrorType.invalidOutputFormat);
		}
		else
		{
			if(urlParts.format == null)
				urlParts.format = apiFormatHandler.restApiFormats[0];
		
			// If no raw request exists, take it from the web request.
			if(rawRequestData == null)
				rawRequestData = Web.getPostData();

			// Convert the raw request data using the RestApiFormatHandler.
			var requestData = (rawRequestData != null) ? apiFormatHandler.restApiInput(rawRequestData, urlParts.format) : null;

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
		
		var finalOutput : RestResponseOutput = apiFormatHandler.restApiOutput(response, urlParts.format);

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
