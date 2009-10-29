package haxigniter.restapi;

import haxigniter.restapi.RestApiResponse;

interface RestApiInterface 
{
	function create(url : String, data : Hash<String>, callBack : RestApiResponse -> Void) : Void;
	function read(url : String, callBack : RestApiResponse -> Void) : Void;
	function update(url : String, data : Hash<String>, callBack : RestApiResponse -> Void) : Void;
	function delete(url : String, callBack : RestApiResponse -> Void) : Void;
}