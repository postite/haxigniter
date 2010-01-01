package haxigniter.server;

#if php
import php.Web;
import php.Lib;
#elseif neko
import neko.Web;
import neko.Lib;
#end

import haxigniter.common.exceptions.Exception;
import haxigniter.server.exceptions.NotFoundException;

import haxigniter.server.Controller;
import haxigniter.server.content.ContentHandler;
import haxigniter.server.routing.Router;

import haxigniter.server.libraries.Server;
import haxigniter.server.libraries.Request;
import haxigniter.server.libraries.Url;

import haxigniter.common.libraries.ParsedUrl;

class Application
{
	/**
	 * Run the haXigniter application.
	 * @param	config        Configuration file
	 * @param	?router       For routing the (rewritten) URL to a controller. Default is the DefaultRouter class.
	 * @param	?errorHandler If set, all exceptions will be sent here instead of the default error handler.
	 * @return  The controller created by the router, or null if an error occured before creation.
	 */
	public static function run(config : Config, ?router : Router, ?errorHandler : Dynamic -> Void) : Controller
	{
		var controller : Controller = null;

		// Create a default router if not set.
		if(router == null)
			router = new haxigniter.server.routing.DefaultRouter();

		try
		{
			var url = new Url(config);
			var parsedUrl = new ParsedUrl(requestUrl());

			// Test url for valid characters.
			url.testValidUri(parsedUrl.path);

			controller = router.createController(config, parsedUrl);

			var method = Web.getMethod();
			var getPostData = Web.getParams();
			
			var requestData : Dynamic = null;
			if(method != 'GET')
			{
				// If a content handler exists, transform the raw request data.
				if(controller.contentHandler != null)
					requestData = controller.contentHandler.input(Server.requestContentFromWeb());
				else
					requestData = Web.getPostData();
			}
			
			var output = controller.requestHandler.handleRequest(controller, parsedUrl, method, getPostData, requestData);
			
			// If a content handler exists, output the data based on the content handler modifications.
			if(controller.contentHandler != null)
			{
				var outContent = controller.contentHandler.output(output);
				
				if(outContent != null)
					outputContent(outContent);
			}			
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
	
	private static inline function requestUrl() : String
	{
		var url = Web.getHostName() + Web.getURI();
		var params = Web.getParamsString();
		
		if(params != null && params.length > 0)
			url += '?' + params;
		
		return url;
	}
	
	private static function outputContent(content : ContentData) : Void
	{
		// Format the final output according to response and send it to the client.
		var header = [];

		// Content-Type, including mimetype and charset
		if(content.mimeType != null)
			header.push(content.mimeType);
		if(content.charSet != null)
			header.push('charset=' + content.charSet);
		if(header.length > 0)
			Web.setHeader('Content-Type', header.join('; '));

		// Content-Encoding
		if(content.encoding != null)
			Web.setHeader('Content-Encoding', content.encoding);

		// Content-Length and MD5 should be handled automatically by the server.
		Lib.print(content.data);
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
