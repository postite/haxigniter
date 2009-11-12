package haxigniter.application.controllers;

import haxigniter.libraries.Server;

/**
 * The Dev controller
 * Contains some useful actions for development. http://yourhostname/ will go here.
 * 
 * This controller is a standard Controller, so it will follow the "className/method" convention.
 * A request like http://yourhostname/dev/integrity/test/123 will map to the integrity() method 
 * with "test" as first argument and "123" as second.
 * 
 * The arguments will be automatically casted to the type you specify in the methods.
 * 
 */
class Dev extends haxigniter.controllers.Controller
{
	// For neko, a constructor is required for controllers. PHP doesn't care. :)
	public function new() {}
	
	/**
	 * Run integrity tests, useful when rolling out application for the first time.
	 * @param	password default password is 'password'. Please change it.
	 */
	public function integrity(password = '')
	{
		if(config.development || password == 'password')
		{
			haxigniter.tests.Integrity.runTests();
		}
		else
		{
			// Act like there is nothing here.
			Server.error404();
		}
	}

	#if php
	public function phpinfo()
	{
		if(config.development)
			untyped __php__("phpinfo();");
		else
			Server.error404();
	}
	#end
}
