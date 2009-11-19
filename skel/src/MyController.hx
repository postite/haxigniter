package ;

import config.Database;
import haxigniter.server.request.RequestHandler;
import haxigniter.server.request.RestHandler;
import haxigniter.session.FileSession;

import haxigniter.libraries.Debug;
import haxigniter.libraries.DebugLevel;

import haxigniter.libraries.Database;
import haxigniter.session.SessionObject;
import haxigniter.views.ViewEngine;

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

	/*
	 * Application entrypoint
	 */
	static function main()
	{
		haxigniter.Application.run(configuration);
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
		| 	haxigniter.views.Templo() - The Templo 2 engine. (http://haxe.org/com/libs/mtwin/templo)
		|   haxigniter.views.HaxeTemplate() - haxe.Template (http://haxe.org/doc/cross/template)
		|   haxigniter.views.Smarty() - Smarty, PHP only (http://smarty.net)
		|
		| If you want to use another template system, make a class extending
		| haxigniter.views.viewEngine and instantiate it here. Contributions are
		| always welcome, contact us at haxigniter@gmail.com so we can include
		| your class in the distribution.
		|		
		*/
		this.view = new haxigniter.views.HaxeTemplate(this.config.viewPath);
		
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
			
		this.session = SessionObject.restore(new FileSession(config.sessionPath), config.Session);
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
