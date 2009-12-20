package ;

import config.Database;
import config.Config;
import config.UrlRewriter;

import haxigniter.server.request.RequestHandler;
import haxigniter.server.request.RestHandler;
import haxigniter.server.session.FileSession;
import haxigniter.server.session.SessionObject;

import haxigniter.server.libraries.Debug;
import haxigniter.server.libraries.DebugLevel;

import haxigniter.server.libraries.Database;
import haxigniter.server.views.ViewEngine;

/**
 * This class is the base controller, parent to all controllers in the application.
 * 
 * It implements haxe.rtti.Infos because some request handlers (BasicHandler and RestHandler) 
 * uses that info to typecast the web input from the web to the controller methods.
 */
class MyController implements haxigniter.server.Controller, implements haxe.rtti.Infos
{
	/* --- Starting with the Controller interface implementation --- */
	
	// A request handler, which will determine how the controller will be used in the application.
	public var requestHandler(default, null) : RequestHandler;
	
	/* --- Now for some more application-specific properties --- */

	// A configuration file is required to run the application.
	public var config(default, null) : Config;

	// The controllers will use a template engine to render the output.
	public var view(default, null) : ViewEngine;
	
	// Database connection, if needed.
	public var db(default, null) : DatabaseConnection;
	
	// Session handling, if needed.
	public var session(default, null) : config.Session;

	// Debugging
	public var debug : Debug;
	
	/////////////////////////////////////////////////////////////////
	
	// The application configuration file is static, since it used in main().
	private static var appConfig = new Config();
	
	// The application session is filebased, could be switched to other implementations.
	private static var appSession = new FileSession(appConfig.sessionPath);

	/*
	 * Application entrypoint
	 */
	public static function main()
	{
		// Run the application with the configuration.
		var controller = haxigniter.server.Application.run(appConfig);
		
		// Need to do some cleanup, but test controller type in case some other
		// class was used as a controller.
		if(Std.is(controller, MyController))
			terminateApp(cast controller);
	}

	/**
	 * Cleanup after application is run.
	 * @param	controller Controller that is executed in Application.run().
	 */
	private static function terminateApp(controller : MyController)
	{
		if(controller.db != null)
			controller.db.close();
		
		if(appSession != null)
			appSession.close();
	}

	/**
	 * The controllers are automatically created by haxigniter.server.Application.
	 */
	public function new()
	{
		// Set controller configuration.
		this.config = appConfig;

		// Set the default request handler to a RestHandler.
		// See haxigniter.server.request.RestHandler class for documentation.
		this.requestHandler = new RestHandler(this.config);

		/*
		|--------------------------------------------------------------------------
		| View Engine
		|--------------------------------------------------------------------------
		|
		| The Views are displayed by a ViewEngine, which is any class extending 
		| the haxigniter.views.viewEngine class.
		|
		| The engines currently supplied by haXigniter are:
		|
		|   haxigniter.server.views.Templo() - The Templo 2 engine. (http://haxe.org/com/libs/mtwin/templo)
		|   haxigniter.server.views.HaxeTemplate() - haxe.Template (http://haxe.org/doc/cross/template)
		|   haxigniter.server.views.Smarty() - Smarty, PHP only (http://smarty.net)
		|
		| If you want to use another template system, make a class extending
		| haxigniter.server.views.viewEngine and instantiate it here. Contributions 
		| are always welcome, contact us at haxigniter@gmail.com so we can include
		| your class in the distribution.
		|		
		*/
		this.view = new haxigniter.server.views.HaxeTemplate(this.config);
		
		// Create a debug object for this.trace() and this.log()
		this.debug = new Debug(this.config);

		// Configure database depending on development mode.
		if(this.config.development)
			this.db = new DevelopmentConnection();
		else
			this.db = new OnlineConnection();

		// Set the database debugging so erroneous queries are logged.
		this.db.debug = this.debug;

		// The session is restored from SessionObject, passing in the interface and the output type.
		this.session = SessionObject.restore(appSession, config.Session);
	}
	
	///// Some useful trace/log methods /////////////////////////////
	
	private function trace(data : Dynamic, ?debugLevel : DebugLevel, ?pos : haxe.PosInfos) : Void
	{
		debug.trace(data, debugLevel, pos);
	}
	
	private function log(message : Dynamic, ?debugLevel : DebugLevel) : Void
	{
		debug.log(message, debugLevel);
	}
}
