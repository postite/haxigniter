package haxigniter.server;

#if php
import php.Web;
#elseif neko
import neko.Web;
#end

import haxigniter.common.exceptions.Exception;
import haxigniter.server.exceptions.NotFoundException;
import haxigniter.server.Controller;
import haxigniter.server.Router;

import haxigniter.server.libraries.Debug;
import haxigniter.server.libraries.Server;
import haxigniter.server.libraries.Url;
import haxigniter.server.libraries.Request;

class Application
{
	/**
	 * Run the application, based on a configuration file and a web request.
	 * @param	config Configuration file
	 * @param	?errorHandler If it exists, any exception is sent here.
	 */
	public static function run(config : Config, ?router : Router, ?errorHandler : Dynamic -> Void) : Controller
	{
		var controller : Controller = null;
		
		var requestUri = Web.getURI();
		var queryParams = Web.getParams();
		var method = Web.getMethod();
		var queryString = Web.getParamsString();
		
		if(router == null)
			router = new DefaultRouter();

		try
		{
			// Test url for valid characters.
			new Url(config).testValidUri(requestUri);

			controller = router.createController(config, requestUri, queryParams);
			controller.requestHandler.handleRequest(controller, requestUri, method, queryParams, queryString, method == 'GET' ? null : Web.getPostData());
		}
		catch(e : Dynamic)
		{
			if(errorHandler != null)
			{
				errorHandler(e);
			}
			else if(config.development)
			{
				Application.rethrow(e);
			}
			else if(Std.is(e, NotFoundException))
			{
				var server = new Server(config);
				server.error404();
			}
			else if(Std.is(e, Exception))
			{
				var fullClass = Type.getClassName(Type.getClass(e));				
				logError(config, '[' + fullClass.substr(fullClass.lastIndexOf('.') + 1) + '] ' + e.message, e);				
			}
			else
				logError(config, Std.string(e), e);
		}
		
		return controller;
	}
	
	private static function logError(config : Config, message : String, e : Dynamic)
	{
		var server = new Server(config);
		var debug = new haxigniter.server.libraries.Debug(config);
		var error = genericError(e);
		
		debug.log(message, haxigniter.server.libraries.DebugLevel.error);
		server.error(error.title, error.header, error.message);
	}
	
	public static dynamic function genericError(e : Dynamic) : {title: String, header: String, message: String}
	{
		return { title: 'Page error', header: 'Page error', message: 'Something went wrong during server processing.' };
	}
	
	/**
	 * php.Lib.rethrow() is broken in haXe <= 2.04, so here's a fix until next release.
	 */
	public inline static function rethrow( e : Dynamic )
	{
		#if php
		untyped __php__("if(isset($»e)) throw $»e");
		if(Std.is(e, php.Exception)) {
			var __rtex__ = e;
			untyped __php__("throw $__rtex__");
		}
		else throw e;
		#elseif neko
		neko.Lib.rethrow(e);
		#end
	}
}
