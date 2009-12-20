package config;

/**
 * This object rewrites the incoming url before sending it to a controller.
 * This example rewrites "special/id". Try and browse to it!
 */
class UrlRewriter extends haxigniter.server.routing.ModRewriter
{
	public function new()
	{
		super();

		// Each array item has a corresponding string that will be replaced if the regexp matches.
		this.add(~/^special\/id$/, 'start/4711');
		this.add(~/^goto\/(\d+)$/, 'start/$1');
	}	
}