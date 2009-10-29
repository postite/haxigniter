package haxigniter.restapi;

interface RestApiAuthorization
{
	function create(resourceName : String, fields : Hash<String>, userVars : Hash<String>) : Bool;
	function read(resourceName : String, userVars : Hash<String>) : Bool;
	function update(resourceName : String, id : Int, fields : Hash<String>, userVars : Hash<String>) : Bool;
	function delete(resourceName : String, id : Int, fields : Hash<String>, userVars : Hash<String>) : Bool;
}
