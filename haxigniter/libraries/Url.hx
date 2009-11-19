package haxigniter.libraries;

import haxigniter.Config;
import haxigniter.session.SessionObject;
import haxigniter.libraries.ERegTools;

#if php
import php.Sys;
import php.Web;
#elseif neko
import neko.Sys;
import neko.Web;
#end

class Url
{
	private var config : Config;
	private var session : SessionObject;
	private var SSLInDevelopmentMode : Bool;

	public function new(config : Config, ?session : SessionObject, ?SSLInDevelopmentMode = false)
	{
		this.config = config;
		this.session = session;
		this.SSLInDevelopmentMode = SSLInDevelopmentMode;
	}
	
	public function split(uri : String, ?glue = '/') : Array<String>
	{
		if(uri == null)
			uri = Web.getURI();
		
		// Trim the index path and file from the uri to get the segments.
		var indexFile = config.indexPath + config.indexFile;
		
		if(StringTools.startsWith(uri, indexFile))
			uri = uri.substr(indexFile.length);
		
		// Trim segments from slashes
		if(StringTools.startsWith(uri, glue))
			uri = uri.substr(1);

		if(StringTools.endsWith(uri, glue))
			uri = uri.substr(0, uri.length-1);

		return uri.length > 0 ? uri.split(glue) : [];
	}

	/////////////////////////////////////////////////////////////////

	public static function join(segments : Array<String>, ?glue = '/') : String
	{
		if(segments.length == 0) return '';
		if(segments.length == 1) return segments[0];
		
		var last = segments.length - 1;
		var output = new List<String>();
		
		// Strip ending slash from first segment
		output.add(StringTools.endsWith(segments[0], glue) ? segments[0].substr(0, segments[0].length - 1) : segments[0]);
		
		// Strip first and last slash from all segments except first and last
		var reg = ~/^\/?(.*)\/?$/;
		for(i in 1 ... last)
		{
			output.add(reg.replace(segments[i], '$1'));
		}
		
		// Strip start slash from last segment
		output.add(StringTools.startsWith(segments[last], glue) ? segments[last].substr(1) : segments[last]);
		
		return output.join(glue);
	}

	/**
	 * Returns the path to the application directory, without appending slash.
	 * 
	 * A common usage is to prepend all links in a template page with this value so no 
	 * internal links has to be rewritten if the application directory changes.
	 */
	public function linkUrl() : String
	{
		return config.indexPath.substr(0, config.indexPath.length - 1);
	}
	
	public function siteUrl(?segments : String) : String
	{
		return segments == null ? config.siteUrl + '/' : Url.join([config.siteUrl, segments]);
	}
	
	public function uriString() : String
	{
		var output : String = Web.getURI();
		return StringTools.startsWith(output, '/') ? output : '/' + output;
	}

	/**
	 * Redirect to another page. If url is absolute or starting with a slash, a normal redirect is made. Otherwise, siteUrl() is used to create a local redirect.
	 * Note: In order for this function to work it must be used before anything is outputted to the browser, since it utilizes server headers.
	 * @param	?url
	 * @param	?flashMessage
	 * @param	?https
	 * @param	?responseCode
	 */
	public function redirect(?url : String = null, ?flashMessage : String = null, ?https : Bool = null, ?responseCode : Int = null) : Void
	{
		if(flashMessage != null && session != null)
			session.flashVar = flashMessage;

		if(responseCode != null)
			Web.setReturnCode(responseCode);

		if(url == null)
			url = siteUrl(uriString());
		else if(!StringTools.startsWith(url, '/') && url.indexOf('://') == -1)
			url = siteUrl(url);
		
		if(https != null)
			url = (https ? 'https' : 'http') + url.substr(url.indexOf(':'));

        // No SSL redirect in development mode.
        if(config.development && !this.SSLInDevelopmentMode)
            url = StringTools.replace(url, 'https://', 'http://');
		
		Web.redirect(url);
	}
	
	public function forceSsl(ssl = true, ?sslActive : Bool) : Void
	{
		// No SSL redirect in development mode.
		if(config.development && !this.SSLInDevelopmentMode)
			return;

		// Default test
		if(sslActive == null)
			sslActive = Sys.environment().exists('HTTPS') && Sys.environment().get('HTTPS') == 'on';
		
		if((sslActive && ssl) || !(sslActive || ssl))
			return;
		
		this.redirect(null, session != null ? session.flashVar : null, ssl);
	}
	
	/////////////////////////////////////////////////////////////////
	
	public function testValidUri(uri : String) : Void
	{
		if(config.permittedUriChars == null) return;
		
		// Build a regexp from the permitted chars and test it.
		// Adding slash at the beginning since it's a part of any valid URI.
		var regexp = '^[/' + ERegTools.quoteMeta(config.permittedUriChars) + ']*$';
		var validUrl = new EReg(regexp, 'i');
		
		if(!validUrl.match(uri))
		{
			// TODO: Multiple languages
			throw new haxigniter.exceptions.Exception('The URI you submitted has disallowed characters.');
		}
	}
}
