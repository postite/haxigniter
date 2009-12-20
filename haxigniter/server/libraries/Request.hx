package haxigniter.server.libraries;

import Type;
import haxigniter.common.types.TypeFactory;

import haxigniter.server.Controller;
import haxigniter.server.Config;

import haxigniter.server.routing.Router;

class Request
{
	private var config : Config;
	private var url : Url;
	
	public function new(config : Config)
	{
		this.config = config;
		this.url = new Url(config);
	}
	
	public function createController(controllerName : String, ?controllerArgs : Array<Dynamic>) : Controller
	{
		var controllerClass : String = (controllerName == null || controllerName == '') ? config.defaultController : controllerName;
		controllerClass = config.controllerPackage + '.' + controllerClass.substr(0, 1).toUpperCase() + controllerClass.substr(1);
		
		// Instantiate a controller with the above class name.
		var classType : Class<Dynamic> = Type.resolveClass(controllerClass);
		if(classType == null)
			throw new haxigniter.server.exceptions.NotFoundException(controllerClass + ' not found. (Is it defined in Config.hx?)');

		return cast(Type.createInstance(classType, controllerArgs == null ? [] : controllerArgs), Controller);
	}

	public function requestController(uri : String, ?query : Hash<String>, ?router : Router) : Controller
	{
		// Test url for valid characters.
		url.testValidUri(uri);

		// Create a default router if not set.
		if(router == null)
			router = new haxigniter.server.routing.DefaultRouter();

		return router.createController(config, uri, query);
	}
	
	public function execute(uri : String, ?method = 'GET', ?query : Hash<String>, ?rawQuery : String, ?rawRequestData : String, ?router : Router) : Dynamic
	{
		uri = url.segmentString(uri);
		
		var controller = requestController(uri, query, router);
		return controller.requestHandler.handleRequest(controller, uri, method, query, rawQuery, rawRequestData);
	}
}
