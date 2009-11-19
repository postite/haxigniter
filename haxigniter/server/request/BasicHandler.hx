package haxigniter.server.request;

import haxigniter.server.Controller;
import haxigniter.libraries.Url;
import haxigniter.Config;

class BasicHandler implements RequestHandler
{
	private var config : Config;

	public function new(config : Config)
	{
		this.config = config;
	}
	
	/**
	 * Handle a page request.
	 * @param	uriSegments Array of request segments (URL splitted with "/")
	 * @param	method Request method, "GET" or "POST" most likely.
	 * @param	params Query parameters
	 * @return  Any value that the controller returns.
	 */
	public function handleRequest(controller : Controller, uriPath : String, method : String, query : Hash<String>, rawQuery : String, rawRequestData : String) : Dynamic
	{
		var url : Url = new Url(this.config);
		var uriSegments = url.split(uriPath);
		
		var controllerType = Type.getClass(controller);
		var controllerMethod : String = (uriSegments[1] == null) ? config.defaultAction : uriSegments[1];

		var callMethod : Dynamic = Reflect.field(controller, controllerMethod);
		if(callMethod == null)
			throw new haxigniter.exceptions.NotFoundException(controllerType + ' method "' + controllerMethod + '" not found.');

		// Typecast the arguments.
		var arguments : Array<Dynamic> = haxigniter.types.TypeFactory.typecastArguments(controllerType, controllerMethod, uriSegments.slice(2));
		
		return Reflect.callMethod(controller, callMethod, arguments);
	}
}
