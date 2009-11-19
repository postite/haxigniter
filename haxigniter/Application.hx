package haxigniter;

import haxigniter.server.Controller;

#if php
import php.Web;
#elseif neko
import neko.Web;
#end

import haxigniter.libraries.Debug;
import haxigniter.libraries.Server;
import haxigniter.libraries.Url;
import haxigniter.libraries.Request;

class Application
{
	/**
	 * Run the application, based on a configuration file and a web request.
	 * @param	config Configuration file
	 * @param	?errorHandler If it exists, any exception is sent here.
	 */
	public static function run(config : Config, ?errorHandler : Dynamic -> Void) : Void
	{
		try
		{
			var url : Url = new Url(config);
			var requestUri = Web.getURI();

			// Test url for valid characters.
			url.testValidUri(requestUri);

			// Handle the current web request.
			var request : Request = new Request(config);
			request.execute(requestUri, Web.getMethod(), Web.getParams(), Web.getParamsString(), Web.getPostData());
		}
		catch(e : haxigniter.exceptions.NotFoundException)
		{
			if(errorHandler != null)
			{
				errorHandler(e);
			}
			else if(!config.development)
			{
				var server = new Server(config);
				server.error404();
			}
			else
				Application.rethrow(e);
		}
		catch(e : Dynamic)
		{
			if(errorHandler != null)
			{
				errorHandler(e);
			}
			else if(!config.development)
			{
				var server = new Server(config);
				var debug = new haxigniter.libraries.Debug(config);
				var error = genericError(e);
				
				debug.log(e, haxigniter.libraries.DebugLevel.error);
				server.error(error.title, error.header, error.message);
			}
			else
				Application.rethrow(e);
		}
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
