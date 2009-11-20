package haxigniter.application.controllers;

class Api extends haxigniter.controllers.RestApiController
{
	public function new() 
	{
		this.debugMode = haxigniter.server.libraries.DebugLevel.info;
		
		super();
	}	
}