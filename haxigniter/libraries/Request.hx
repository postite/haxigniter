package haxigniter.libraries;

import Type;
import haxigniter.common.types.TypeFactory;
import haxigniter.server.Controller;
import haxigniter.Config;

class Request
{
	private var config : Config;
	
	public function new(config : Config)
	{
		this.config = config;
	}
	
	public function createController(controllerName : String, ?controllerArgs : Array<Dynamic>) : Controller
	{
		var controllerClass : String = (controllerName == null || controllerName == '') ? config.defaultController : controllerName;
		controllerClass = config.controllerPackage + '.' + controllerClass.substr(0, 1).toUpperCase() + controllerClass.substr(1);
		
		// Instantiate a controller with the above class name.
		var classType : Class<Dynamic> = Type.resolveClass(controllerClass);
		if(classType == null)
			throw new haxigniter.exceptions.NotFoundException(controllerClass + ' not found. (Is it defined in Config.hx?)');

		return cast(Type.createInstance(classType, controllerArgs == null ? [] : controllerArgs), Controller);
	}
	
	public function execute(uri : String, ?method = 'GET', ?query : Hash<String>, ?rawQuery : String, ?rawRequestData : String) : Dynamic
	{
		var url = new Url(config);
		var segments = url.split(uri);
		
		var controller = createController(segments[0]);
		
		return controller.requestHandler.handleRequest(controller, uri, method, query, rawQuery, rawRequestData);
	}
}
