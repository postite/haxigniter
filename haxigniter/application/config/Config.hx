package haxigniter.application.config;

import haxigniter.libraries.Debug;
import haxigniter.libraries.DebugLevel;

#if php
import php.Sys;
import php.Web;
#elseif neko
import neko.Sys;
import neko.Web;
#end

class Config extends haxigniter.libraries.Config
{
	/* ================================================================= */
	/* ===== Start of configuration settings =========================== */
	/* ===== Do not edit anything above here =========================== */
	/* ================================================================= */

	private function new()
	{
		/*
		|--------------------------------------------------------------------------
		| Development mode
		|--------------------------------------------------------------------------
		|
		| Development mode is used to choose automatically between different 
		| database connections, paths, etc. You should make this setting 
		| auto-detecting, so you can upload the application to a live server 
		| and it should work without changing anything.
		|
		| Here are a few examples how to auto-detect development mode:
		|
		| If you're on a Windows machine when developing and Linux when live:
		|    development = Sys.getEnv('OS') == 'Windows_NT';
		|
		| To test depending on host name: 
		|    development = Web.getHostName() == 'localhost';
		|
		| Or IP address (PHP only):
		|    development = Server.Param('SERVER_ADDR') == '127.0.0.1';
		|
		*/
		development = Web.getHostName() == 'localhost';

		/* ===================================================================== */
		/* === Paths ============================================================*/
		/* ===================================================================== */

		/*
		|--------------------------------------------------------------------------
		| Index file
		|--------------------------------------------------------------------------
		|
		| Filename of the index file. It can be autodetected for PHP, so leave it
		| as null unless you're using mod_rewrite (see below). 
		|
		| If you're using Neko or autodetection doesn't work, the most common value
		| is "index.php" for PHP and "index.n" for Neko.
		|
		| NOTE: If you are using mod_rewrite to remove the index page, set this 
		| value to "" (empty string).
		|
		*/
		#if php
		indexFile = null;
		#elseif neko
		indexFile = 'index.n';
		#end
		
		/*
		|--------------------------------------------------------------------------
		| Index path
		|--------------------------------------------------------------------------
		|
		| This is the absolute web path to your index file. Usually for PHP it can 
		| be autodetected, so you can set leave it as null.
		|
		| If you're using Neko or autodetection doesn't work, you must specify it
		| manually. For example, if the index file is located in the folder 
		| "haxigniter" on the web server, indexPath should be set to 
		| "/haxigniter/". If your application is in the root of the web 
		| server, it will be just "/". Remember to include a trailing slash.
		|
		*/
		#if php
		indexPath = null;
		#elseif neko
		indexPath = '/';
		#end

		/*
		|--------------------------------------------------------------------------
		| Site URL
		|--------------------------------------------------------------------------
		|
		| URL to your haXigniter root. If null it will be autodetected. If you need
		| to specify it, it's a normal URL:
		|
		|	http://www.your-site.com/path/to/index.php
		|
		*/
		siteUrl = null;
		
		/*
		|--------------------------------------------------------------------------
		| Application Path
		|--------------------------------------------------------------------------
		|
		| Full server path to the application. Set automatically.
		|
		*/
		applicationPath = null;
		
		/*
		|--------------------------------------------------------------------------
		| Views Directory Path
		|--------------------------------------------------------------------------
		|
		| Set to null unless you would like to set something other than the default
		| application/views/ folder. Use a full server path with trailing slash.
		|
		*/
		viewPath = null;
		
		/*
		|--------------------------------------------------------------------------
		| Error Logging Directory Path
		|--------------------------------------------------------------------------
		|
		| Set to null unless you would like to set something other than the default
		| application/runtime/logs/ folder. Use a full server path with trailing slash.
		|
		*/
		logPath = null;

		/*
		|--------------------------------------------------------------------------
		| Cache Directory Path
		|--------------------------------------------------------------------------
		|
		| Set to null unless you would like to set something other than the default
		| application/runtime/cache/ folder. Use a full server path with trailing slash.
		|
		*/
		cachePath = null;

		/*
		|--------------------------------------------------------------------------
		| Session Path
		|--------------------------------------------------------------------------
		|
		| Set to null unless you would like to set something other than the default
		| application/runtime/session/ folder. Use a full server path with trailing slash.
		|
		| If you want to disable session, set this value to an empty string.
		|
		*/
		sessionPath = null;

		/* ===================================================================== */
		/* === Other =========================================================== */
		/* ===================================================================== */

		/*
		|--------------------------------------------------------------------------
		| Allowed URL Characters
		|--------------------------------------------------------------------------
		|
		| This lets you specify which characters are permitted within your URLs.
		| When someone tries to submit a URL with disallowed characters they will
		| get a warning message.
		|
		| As a security measure you are STRONGLY encouraged to restrict URLs to
		| as few characters as possible.  By default only these are allowed: 
		|
		| a-z 0-9~%.:_-
		|
		| Set to null to allow all characters -- but only if you are insane.
		|
		| DO NOT CHANGE THIS UNLESS YOU FULLY UNDERSTAND THE REPERCUSSIONS!!
		|
		*/
		permittedUriChars = 'a-z 0-9~%.:_-';

		/*
		|--------------------------------------------------------------------------
		| Error Logging Threshold
		|--------------------------------------------------------------------------
		|
		| You can enable error logging by setting a threshold over Off. The
		| threshold determines what gets logged. Threshold options are:
		|
		|	DebugLevel.off = Disables logging, Error logging TURNED OFF
		|	DebugLevel.error = Error Messages (including PHP errors)
		|	DebugLevel.warning = Warning Messages
		|	DebugLevel.info = Info Messages
		|	DebugLevel.verbose = All Messages
		|
		| For a live site you'll usually only enable Error or Warning otherwise
		| your log files will fill up very fast.
		|
		*/
		logLevel = this.development ? DebugLevel.info : DebugLevel.warning;

		/*
		|--------------------------------------------------------------------------
		| Date Format for Logs
		|--------------------------------------------------------------------------
		|
		| Each item that is logged has an associated date. You can use strftime
		| codes to set your own date formatting.
		|
		*/
		logDateFormat = '%Y-%m-%d %H:%M:%S';

		/*
		|--------------------------------------------------------------------------
		| Error page
		|--------------------------------------------------------------------------
		|
		| haxigniter.libraries.Server.error() can be used to display an error page
		| when things go wrong.
		|
		| If you want to call a controller as an error page, set it here. For 
		| example "site/error".
		|
		| If it's set to null, the template in application/views/error.html will
		| be used for display, with a generic error message.
		|
		*/
		errorPage = null;

		/*
		|--------------------------------------------------------------------------
		| Error 404 page
		|--------------------------------------------------------------------------
		|
		| haxigniter.libraries.Server.error404() can be used to display the 404
		| error page (not found error). Correct headers are sent automatically.
		|
		| If you want to call a controller as an error page, set it here. For 
		| example "site/error404".
		|
		| If it's set to null, the template in application/views/error.html will
		| be used for display, with a generic error 404 message.
		|
		*/
		error404Page = null;

		/*
		|--------------------------------------------------------------------------
		| Default Language
		|--------------------------------------------------------------------------
		|
		| This determines which set of language files should be used. Make sure
		| there is an available translation if you intend to use something other
		| than english.
		|
		*/
		language = 'english';

		/*
		|--------------------------------------------------------------------------
		| Encryption Key
		|--------------------------------------------------------------------------
		|
		| If you use the Encryption class you MUST set an encryption key.
		|
		*/
		encryptionKey = null;
		
		/*
		|--------------------------------------------------------------------------
		| Default controller
		|--------------------------------------------------------------------------
		|
		| If you want another controller than the default 'start' to be used
		| when the URL is empty, specify it here. Null sets the default.
		|
		*/
		defaultController = null;

		/*
		|--------------------------------------------------------------------------
		| Default controller action
		|--------------------------------------------------------------------------
		|
		| If you want another controller action than the default 'index' to be used
		| when the URL is empty, specify it here. Null sets the default.
		|
		*/
		defaultAction = null;

		/*
		|--------------------------------------------------------------------------
		| Superclass and debugging
		|--------------------------------------------------------------------------
		|
		| super() must be called at the end to populate default values.
		|
		| If you call this with true as argument, the environment will be
		| dumped to screen. Useful for debugging.
		|
		| If you specify a filename instead, the dump will be written to
		| that file IF that file doesn't exist! (A safety since it's called
		| on every page request.)
		|
		*/
		super();
	}

	/*
	 * Instantiate objects here that depends on the configuration settings above.
	 * (To avoid circular dependencies in the constructor.)
	 */
	private function newObjects()
	{
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
		view = new haxigniter.views.HaxeTemplate();
	}
	
	/* ================================================================= */
	/* ===== End of configuration settings   =========================== */
	/* ===== Do not edit anything below here =========================== */
	/* ================================================================= */

	private static var my_instance : Config;
	public static function instance() : Config
	{
		if(my_instance == null)
		{
			my_instance = new Config();
			my_instance.newObjects();
		}
		
		return my_instance;
	}
}
