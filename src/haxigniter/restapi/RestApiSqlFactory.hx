package haxigniter.restapi;

#if php
import php.Lib;
import php.Web;
#elseif neko
import neko.Lib;
import neko.Web;
#end

import haxigniter.controllers.RestApiController;
import haxigniter.restapi.RestApiRequest;
import haxigniter.restapi.RestApiResponse;

import haxigniter.exceptions.RestApiException;

class RestApiSqlFactory implements RestApiRequestHandler
{
	public var supportedContentTypes(default, null) : Hash<String>;
	public var supportedOutputFormats(default, null) : Array<String>;
	
	public function new()
	{
		supportedContentTypes = new Hash<String>();
		supportedContentTypes.set('haxigniter', RestApiController.commonMimeTypes.haxigniter);
		
		supportedOutputFormats = ['haxigniter'];
	}

	///// RestApiRequestHandler implementation //////////////////////
	
	public function handleApiRequest(request : RestApiRequest) : RestApiResponse
	{
		throw 'Not implemented.';
		return null;
	}
	
	public function outputApiResponse(request : RestApiResponse, outputFormat : String) : RestResponseOutput
	{
		return { 
			contentType: supportedContentTypes.get(supportedOutputFormats[0]), 
			charSet: null, 
			output: haxe.Serializer.run(request)
		};
	}

	/////////////////////////////////////////////////////////////////
	
	private function contentType(outputFormat : String)
	{
		return supportedContentTypes.exists(outputFormat) ? supportedContentTypes.get(outputFormat) : supportedContentTypes.get(supportedOutputFormats[0]);
	}

}
