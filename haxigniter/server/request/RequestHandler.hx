package haxigniter.server.request;

import haxigniter.server.Controller;
import haxigniter.common.libraries.ParsedUrl;

interface RequestHandler
{
	/**
	 * Handle a page request.
	 * @param   controller The object that is delegated to handle the request.
	 * @param	url A parsed url of the request.
	 * @param	method Request method, "GET" or "POST" most likely.
	 * @param	getPostData A combination of GET and POST vars.
	 * @param	rawRequestData Raw data sent with the request.
	 * @return
	 */
	public function handleRequest(controller : Controller, url : ParsedUrl, method : String, getPostData : Hash<String>, rawRequestData : String) : Dynamic;
}
