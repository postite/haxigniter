package ;

import config.Database;

import haxigniter.server.request.RequestHandler;
import haxigniter.server.request.RestHandler;
import haxigniter.server.session.FileSession;
import haxigniter.server.session.SessionObject;

import haxigniter.server.libraries.Debug;
import haxigniter.server.libraries.DebugLevel;

import haxigniter.server.libraries.Database;
import haxigniter.server.views.ViewEngine;

/**
 * Base controller, parent to all controllers in the application.
 */
class MyController implements haxigniter.server.Controller
{
	///// Starting with the Controller interface implementation /////
	
	// A request handler, which will determine how the controller will be used in the application.
	public var requestHandler(default, null) : RequestHandler;
	
	///// Now for some more application-specific properties /////////

	// A configuration file is useful.
	public var config(default, null) : haxigniter.Config;

	// This application will use a template engine to render the output.
	public var view(default, null) : ViewEngine;
	
	// Database connection, if needed.
	public var db(default, null) : DatabaseConnection;
	
	// Session handling, if needed.
	public var session(default, null) : config.Session;

	// Debugging
	public var debug : Debug;
	
	/////////////////////////////////////////////////////////////////
	
	// The configuration file is static, since it used in main()
	private static var configuration = new config.Config();
	
	// The application session is filebased, could be switched to other implementations.
	private static var appSession = new FileSession(configuration.sessionPath);

	/*
	 * Application entrypoint
	 */
	public static function main()
	{
		var controller = haxigniter.Application.run(configuration);
		
		// Need to do some cleanup, but test controller type since others may have been called. 
		// This test can be removed if all controllers are inherited from MyController.
		if(Std.is(controller, MyController))
			applicationEnd(cast controller);
	}

	/**
	 * Cleanup after application is run.
	 * @param	controller
	 */
	private static function applicationEnd(controller : MyController)
	{
		if(controller.db != null)
			controller.db.close();
		
		if(appSession != null)
			appSession.close();
	}

	/**
	 * The controllers are automatically created by haxigniter.Application.
	 */
	public function new()
	{
		this.config = configuration;

		// Set the default request handler to a RestHandler.
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
		this.view = new haxigniter.server.views.HaxeTemplate(this.config.viewPath);
		
		// Create a debug object for this.trace() and this.log()
		this.debug = new Debug(this.config);

		// Configure database depending on development mode.
		if(this.config.development)
		{
			// If development, also set a debug
			this.db = new DevelopmentConnection();
			this.db.debug = this.debug;
		}
		else
			this.db = new OnlineConnection();
		
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
