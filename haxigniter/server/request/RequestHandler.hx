package haxigniter.server.request;

import haxigniter.server.Controller;

interface RequestHandler
{
	/**
	 * Handle a page request.
	 * @param   controller The object that is delegated to handle the request.
	 * @param	urlPath The path part of the url (after host and script name, before query).
	 * @param	method Request method, "GET" or "POST" most likely.
	 * @param	query Usually a combination of GET and POST vars.
	 * @param	rawQuery Url query string.
	 * @param	rawRequestData Raw data sent with the request.
	 * @return
	 */
	public function handleRequest(controller : Controller, uriPath : String, method : String, query : Hash<String>, rawQuery : String, rawRequestData : String) : Dynamic;
}
