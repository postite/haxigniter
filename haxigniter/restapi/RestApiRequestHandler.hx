package haxigniter.restapi;

interface RestApiRequestHandler
{
	/**
	 * Handle an incoming request.
	 * @param	request
	 * @return
	 */
	function handleApiRequest(request : RestApiRequest, security : RestApiSecurityHandler) : RestApiResponse;
}
