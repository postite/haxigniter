package haxigniter.application.config;

/**
 * This class is automatically retained by PHP or neko session.
 * Just add and set the variables you like. Very useful for shopping carts,
 * user data, etc.
 * 
 * It also implements Dynamic so it can be done on-the-fly if you like.
 */
class Session extends haxigniter.libraries.Session 
{
	//public var name : String;

	// For initializing the instance variables, if needed.
	public function new()
	{	
		super(); // This is required, do not remove.
	}
}
