package haxigniter.restapi;

interface RestApiAuthorization
{
	function authorizeRequest(request : RestApiRequest) : Bool;
}
