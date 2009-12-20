package haxigniter.server.routing;

interface UrlRewriter
{
	/**
	 * Rewrites a url.
	 * @param	url
	 * @return
	 */
	function rewriteUrl(url : String) : String;
}
