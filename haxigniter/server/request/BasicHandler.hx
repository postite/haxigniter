package haxigniter.server.request;

import haxigniter.server.Controller;
import haxigniter.server.Config;
import haxigniter.common.types.TypeFactory;
import haxigniter.server.libraries.Url;
import haxigniter.common.libraries.ParsedUrl;

class BasicHandler implements RequestHandler
{
	private var config : Config;

	public function new(config : Config)
	{
		this.config = config;
	}
	
	public function handleRequest(controller : Controller, url : ParsedUrl, method : String, getPostData : Hash<String>, rawRequestData : String) : Dynamic
	{
		var uriSegments = new Url(config).split(url.path);
		
		var controllerType = Type.getClass(controller);
		var controllerMethod : String = (uriSegments[1] == null) ? config.defaultAction : uriSegments[1];
		
		var callMethod : Dynamic = Reflect.field(controller, controllerMethod);
		if(callMethod == null)
			throw new haxigniter.server.exceptions.NotFoundException(Type.getClassName(controllerType) + ' method "' + controllerMethod + '" not found.');

		// Typecast the arguments.
		var arguments : Array<Dynamic> = TypeFactory.typecastArguments(controllerType, controllerMethod, uriSegments.slice(2));
		
		return Reflect.callMethod(controller, callMethod, arguments);
	}
}
