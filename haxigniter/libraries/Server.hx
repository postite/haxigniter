package haxigniter.libraries;

#if php
import php.io.Path;
import php.io.File;
import php.Lib;
import php.Web;
#elseif neko
import neko.io.Path;
import neko.io.File;
import neko.Lib;
import neko.Web;
#end

class Server
{
	private var config : Config;
	
	public function new(config : Config)
	{
		this.config = config;
	}
	
	#if php
	/**
	 * Convenience method for external libraries.
	 * @param	path
	 */
	public function requireExternal(path : String) : Void
	{
		untyped __call__('require_once', config.applicationPath + 'external/' + path);
	}

	/**
	 * Gives access to any php $_SERVER variable.
	 * @param	varName
	 * @return  the variable as a string, or null if variable didn't exist.
	 */
	public static inline function param(parameter : String) : String
	{
		try
		{
			return untyped __var__('_SERVER', parameter);
		}
		catch(e : String)
		{
			return null;
		}
	}
	#end
	
	///// Error handling ////////////////////////////////////////////
	
	public function error404(?title : String, ?header : String, ?message : String) : Void
	{
		// TODO: Multiple languages
		if(title == null)
			title = '404 not found';

		if(header == null) 
			header = title;
		
		if(message == null)
			message = 'The page you requested was not found.';
		
		this.error(title, header, message, 404);
	}
	
	public function error(title : String, header : String, message : String, returnCode : Int = null) : Void
	{
		var errorPage = returnCode == 404 ? config.error404Page : config.errorPage;
		
		if(returnCode != null)
			Web.setReturnCode(returnCode);
		
		if(errorPage == null)
		{
			// Super-simple content-replace of the views/error.html file.
			var content = File.getContent(config.viewPath + 'error.html');
			content = StringTools.replace(content, '::TITLE::', title);
			content = StringTools.replace(content, '::HEADER::', header);
			content = StringTools.replace(content, '::MESSAGE::', message);
			
			Lib.print(content);
		}
		else
		{
			// Error page is specified, so request that controller.
			var request = new Request(config);			
			request.execute(errorPage);			
		}
	}

	
	/**
	 * Implementation of the php function dirname(). Return value is without appending slash.
	 * Note: If there are no slashes in path, a dot ('.') is returned, indicating the current directory.
	 * @param	path
	 * @return  given a string containing a path to a file, this function will return the name of the directory.
	 */
	public static function dirname(path : String) : String
	{
		#if php
		return Path.directory(path);
		#elseif neko
		var output = Path.directory(path);
		return output.length == 0 ? '.' : output;
		#end
	}

	/**
	 * Implementation of the php function basename().
	 * Given a string containing a path to a file, this function will return the base name of the file.
	 * 
	 * @param	path
	 * @param   suffix If the filename ends in suffix this will also be cut off.
	 * @return  given a string containing a path to a file, this function will return the name of the directory.
	 */
	public static function basename(path : String, ?suffix : String) : String
	{
		var output = Path.withoutDirectory(path);
		
		if(suffix == null)
			return output;
		else
			return StringTools.endsWith(output, suffix) ? output.substr(0, output.length - suffix.length) : output;
	}
}
