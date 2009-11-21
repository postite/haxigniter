package haxigniter.client.restapi;

import haxe.Serializer;
import haxe.Unserializer;
import haxigniter.common.restapi.RestApiInterface;
import haxigniter.common.restapi.RestApiResponse;

import haxigniter.client.libraries.Ajax;
import js.XMLHttpRequest;

class RestApiClient implements RestApiInterface
{
	private var serverUrl : String;

	// There is a problem with javascript StringTools.urlDecode and special 
	// characters in haXe <= 2.04, so this is the fix until it's included.
	#if js
	private static function __init__() untyped
	{
		StringTools.urlDecode = function( s : String ) : String untyped {
			return decodeURIComponent(unescape(s.split("+").join(" ")));
		}
	}
	#end
	
	public function new(serverUrl : String)
	{
		if(serverUrl.charAt(serverUrl.length - 1) == '/')
			serverUrl = serverUrl.substr(0, serverUrl.length - 1);
			
		this.serverUrl = serverUrl;
	}
	
	///// RestApiInterface implementation ///////////////////////////
	
	public function create(query : String, data : Dynamic, callBack : RestApiResponse -> Void) : Void
	{
		sendRequest(query, 'POST', data, callBack);
	}
	
	public function read(query : String, callBack : RestApiResponse -> Void) : Void
	{
		sendRequest(query, 'GET', null, callBack);
	}
	
	public function update(query : String, data : Dynamic, callBack : RestApiResponse -> Void) : Void
	{
		sendRequest(query, 'PUT', data, callBack);
	}
	
	public function delete(query : String, callBack : RestApiResponse -> Void) : Void
	{
		sendRequest(query, 'DELETE', null, callBack);
	}
	
	/////////////////////////////////////////////////////////////////
	
	private function sendRequest(query : String, method : String, data : Dynamic, callBack : RestApiResponse -> Void) : Void
	{
		var request = Ajax.xmlHttpRequest();
		request.onreadystatechange = function()
		{
			if(request.readyState == 4)
			{
				try
				{
					var response = Unserializer.run(request.responseText);
					
					if(!Std.is(response, RestApiResponse))
						throw 'Bad response type.';
						
					callBack(cast response);
				}
				catch(e : Dynamic)
				{
					callBack(RestApiResponse.failure('Invalid Response: ' + e, RestErrorType.invalidResponse));
				}
			}
		}
		
		request.open(method, buildQuery(query), true);
		request.send(data != null ? Serializer.run(data) : null);
	}
	
	private function buildQuery(query : String) : String
	{
		if(query.charAt(0) == '/')
			query = query.substr(1);
		
		return serverUrl + '/?/' + query;
	}
}