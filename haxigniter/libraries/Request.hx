package haxigniter.libraries;

import Type;
import haxigniter.types.TypeFactory;
import haxigniter.controllers.Controller;

class Request
{
	private static var config = haxigniter.application.config.Config.instance();	
	public static var defaultPackage : String = 'haxigniter.application.controllers';

	public static function fromString(request : String, ?method : String, ?query : Hash<String>, ?rawQuery : String) : Dynamic
	{
		if(StringTools.startsWith(request, '/'))
			request = request.substr(1);

		if(StringTools.endsWith(request, '/'))
			request = request.substr(0, request.length - 1);
		
		return fromArray(request.split('/'), method, query, rawQuery);
	}
	
	public static function fromArray(uriSegments : Array<String>, ?method : String, ?query : Hash<String>, ?rawQuery : String) : Dynamic
	{
		var controller : Controller = createController(uriSegments[0]);
		return controller.handleRequest(uriSegments, method, query, rawQuery);
	}
		
	public static function createController(controllerName : String) : Controller
	{
		var controllerClass : String = (controllerName == null || controllerName == '') ? config.defaultController : controllerName;
		controllerClass = defaultPackage + '.' + controllerClass.substr(0, 1).toUpperCase() + controllerClass.substr(1);
		
		// Instantiate a controller with this class name.
		var classType : Class<Dynamic> = Type.resolveClass(controllerClass);
		if(classType == null)
			throw new haxigniter.exceptions.NotFoundException(controllerClass + ' not found. (Is it defined in application/config/Controllers.hx?)');

		// TODO: Controller arguments?
		return cast Type.createInstance(classType, []);
	}
}
