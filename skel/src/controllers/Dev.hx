package controllers;

import haxigniter.server.libraries.Server;
import haxigniter.server.request.BasicHandler;
import tests.Integrity;

/**
 * The Dev controller
 * Contains some useful actions for development. http://yourhostname/dev/ will go here.
 * 
 * This controller uses a BasicHandler as you'll see in new(), so it will follow the 
 * "className/method" convention. A request like http://yourhostname/dev/integrity/test/123 
 * will map to the integrity() method with "test" as first argument and "123" as second.
 * 
 * The arguments will be automatically casted to the type you specify in the methods.
 * 
 */
class Dev extends MyController
{
	public function new()
	{
		super();
		
		// This controller should use a BasicHandler for requests, so change its requestHandler.
		this.requestHandler = new BasicHandler(this.config);
	}
	
	/**
	 * Run integrity tests, useful when rolling out application for the first time.
	 * @param	password default password is 'password'. Please change it.
	 */
	public function integrity(password = '')
	{
		if(config.development || password == 'password')
		{
			var integrity = new Integrity(config);
			integrity.run();
		}
		else
		{
			// Act like there is nothing here.
			var server = new Server(config);
			server.error404();
		}
	}

	#if php
	public function phpinfo()
	{
		if(config.development)
			untyped __php__("phpinfo();");
		else
		{
			var server = new Server(config);
			server.error404();
		}
	}
	#end
}
