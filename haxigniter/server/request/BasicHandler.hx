package haxigniter.server.request;

import haxigniter.server.Controller;
import haxigniter.server.Config;
import haxigniter.common.types.TypeFactory;
import haxigniter.server.libraries.Url;
import haxigniter.common.libraries.ParsedUrl;

class BasicHandler implements RequestHandler
{
	private var config : Config;
	
	private var getPostDataStack : List<Hash<String>>;
	public function getPostData() : Hash<String>
	{
		return getPostDataStack.first();
	}

	private var requestDataStack : List<Dynamic>;
	public function requestData() : Dynamic
	{
		return requestDataStack.first();
	}
	
	public function new(config : Config)
	{
		this.config = config;
		this.getPostDataStack = new List<Hash<String>>();
		this.requestDataStack = new List<Dynamic>();
	}
	
	public function handleRequest(controller : Controller, url : ParsedUrl, method : String, getPostData : Hash<String>, requestData : Dynamic) : Dynamic
	{
		var uriSegments = new Url(config).split(url.path);
		
		var controllerType = Type.getClass(controller);
		var controllerMethod : String = (uriSegments[1] == null) ? config.defaultAction : uriSegments[1];
		
		var callMethod : Dynamic = Reflect.field(controller, controllerMethod);
		if(callMethod == null)
			throw new haxigniter.server.exceptions.NotFoundException(Type.getClassName(controllerType) + ' method "' + controllerMethod + '" not found.');

		// Typecast the arguments.
		var arguments : Array<Dynamic> = TypeFactory.typecastArguments(controllerType, controllerMethod, uriSegments.slice(2));
		
		getPostDataStack.push(getPostData);
		requestDataStack.push(requestData);
		
		var output = Reflect.callMethod(controller, callMethod, arguments);
		
		getPostDataStack.pop();
		requestDataStack.pop();
		
		return output;
	}
}
