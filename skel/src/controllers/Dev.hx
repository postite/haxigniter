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
	/**
	 * If not in development mode, the development functions needs a password.
	 * The default password is 'password'. Please change it.
	 */
	private static var devPassword = 'password';

	public function new()
	{
		super();
		
		// This controller should use a BasicHandler for requests, so change its requestHandler.
		this.requestHandler = new BasicHandler(this.config);
	}
	
	/**
	 * Run integrity tests, useful when rolling out application for the first time.
	 */
	public function integrity(password = '')
	{
		var self = this;
		
		runIfDevOrPassword(password, function() {
			var integrity = new Integrity(self.config);
			integrity.run();
		});
	}
	
	public function unittests(password = '')
	{
		var testRunner = new haxigniter.common.unit.TestRunner();

		// Add all your test classes here
		testRunner.add(new tests.unit.When_doing_math());
		
		runIfDevOrPassword(password, function() {
			testRunner.runAndDisplay();
		});
	}

	#if php
	public function phpinfo(password = '')
	{
		runIfDevOrPassword(password, function() {
			untyped __php__("phpinfo();");
		});
	}
	#end

	private function runIfDevOrPassword(password : String, callBack : Void -> Void)
	{
		if(config.development || password == devPassword)
		{
			callBack();
		}
		else
		{
			// Act like there is nothing here.
			var server = new Server(config);
			server.error404();
		}		
	}
}
