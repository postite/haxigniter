package haxigniter.restapi;

import haxigniter.restapi.RestApiInterface;
import haxigniter.restapi.RestApiResponse;

interface RestApiSecurityHandler
{
	function install(api : RestApiInterface) : Void; 
	
	function create(resourceName : String, data : Dynamic, ?parameters : Hash<String>) : Void;
	function read(resourceName : String, data : RestDataCollection, ?parameters : Hash<String>) : Void;
	function update(resourceName : String, ids : List<Int>, data : Dynamic, ?parameters : Hash<String>) : Void;
	function delete(resourceName : String, ids : List<Int>, ?parameters : Hash<String>) : Void;
}
