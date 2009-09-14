package haxigniter.libraries;

import haxigniter.Application;

import haxigniter.EReg2;
import php.Web;

class Url
{
	// Must be above other vars using this variable.
	private static var config = Application.Instance.Config;

	public static var PermittedUriChars : String = config.PermittedUriChars;
	
	public static var Segments(getSegments, null) : Array<String>;
	private static var segments : Array<String>;
	private static function getSegments()
	{
		if(Url.segments == null)
		{
			var currentUri : String = Web.getURI();
			
			// Segments will be accessed in the controller, so it's safe to do the URI test here.
			if(Url.PermittedUriChars.length > 0)
				Url.testValidUri(currentUri);
			
			// TODO: SCRIPT_NAME may cause problems on other systems, watch for it.
			var scriptName : String = haxigniter.libraries.Server.Param('SCRIPT_NAME');
			var segmentString : String = currentUri.substr(scriptName.length + 1); // +1 for the ending slash

			// Strip empty segment at the end of the string.
			if(segmentString.charAt(segmentString.length-1) == '/')
				segmentString = segmentString.substr(0, segmentString.length-1);

			Url.segments = segmentString.length > 0 ? segmentString.split('/') : [];
		}
		
		return Url.segments;
	}

	/////////////////////////////////////////////////////////////////

	public static function JoinUrl(segments : Array<String>) : String
	{
		if(segments.length == 0) return '';
		if(segments.length == 1) return segments[0];
		
		var last = segments.length - 1;
		var output = new List<String>();
		
		// Strip ending slash from first segment
		output.add(StringTools.endsWith(segments[0], '/') ? segments[0].substr(0, segments[0].length - 1) : segments[0]);
		
		// Strip first and last slash from all segments except first and last
		var reg = ~/^\/?(.*)\/?$/;
		for(i in 1 ... last)
		{
			output.add(reg.replace(segments[i], '$1'));
		}
		
		// Strip start slash from last segment
		output.add(StringTools.startsWith(segments[last], '/') ? segments[last].substr(1) : segments[last]);
		
		return output.join('/');
	}
	
	public static function SiteUrl(segments : String) : String
	{
		return JoinUrl([config.BaseUrl, config.IndexPage, segments]);
	}
	
	public static function UriString() : String
	{
		var output : String = Url.Segments.join('/');
		return output.length > 0 ? '/' + output : '';
	}

	/**
	 * Redirect to another page. If url isn't absolute, SiteUrl() is used to create a local redirect.
	 * Note: In order for this function to work it must be used before anything is outputted to the browser since it utilizes server headers.
	 * @param	?url
	 * @param	?flashMessage
	 * @param	?https
	 * @param	?responseCode
	 */
	public static function Redirect(?url : String = null, ?flashMessage : String = null, ?https : Bool = null, ?responseCode : Int = null)
	{
		if(flashMessage != null)
			Application.Instance.Session.FlashVar = flashMessage;

		if(responseCode != null)
			php.Web.setReturnCode(responseCode);

		if(url == null)
			url = Url.SiteUrl(Url.UriString());
		else if(url.indexOf('://') == -1)
			url = Url.SiteUrl(url);
				
		if(https != null)
			url = (https ? 'https' : 'http') + url.substr(url.indexOf(':'));

        // No SSL redirect in development mode.
        if(config.Development)
            url = StringTools.replace(url, 'https://', 'http://');
		
		php.Web.redirect(url);
	}
	
	public static function ForceSsl(ssl = true)
	{
		// No SSL redirect in development mode.
		if(config.Development) return;
		
		var sslActive : Bool = haxigniter.libraries.Server.Param('HTTPS') == 'on';
		
		if((sslActive && ssl) || !(sslActive || ssl))
			return;
		
		Url.Redirect(null, Application.Instance.Session.FlashVar, ssl);
	}
	
	/////////////////////////////////////////////////////////////////
	
	private static function testValidUri(uri : String) : Void
	{
		// Build a regexp from the permitted chars and test it.
		// Adding slash at the beginning since it's a part of any valid URI.
		var regexp = '^[/' + EReg2.QuoteMeta(Url.PermittedUriChars) + ']*$';
		var validUrl = new EReg(regexp, 'i');
		
		if(!validUrl.match(uri))
		{
			// TODO: Localize?
			throw new haxigniter.exceptions.Exception('The URI you submitted has disallowed characters.');
		}
	}
}