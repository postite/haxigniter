package controllers;

import haxe.Serializer;
import haxe.Unserializer;
import haxigniter.server.request.RestApiHandler;
import haxigniter.server.restapi.RestApiConfigSecurityHandler;
import haxigniter.server.restapi.RestApiSqlRequestHandler;

class Api extends MyController
{
	public function new() 
	{
		super();
		
		var rights = new SecurityRights();
		var allAccess : UserRights = { guest: { read: 'ALL' }, owner: null, admin: null };
		
		rights.set('items', allAccess);
		rights.set('itemsdone', allAccess);
		
		var security = new RestApiConfigSecurityHandler(rights);
		var apiRequestHandler = new RestApiSqlRequestHandler(this.db);
		
		this.requestHandler = new RestApiHandler(security, apiRequestHandler);
		
		// Set development mode of the ApiHandler.
		apiHandler.development = config.development;
		
		// Turn off database debugging, it messes up the request response on errors.
		this.db.debug = null;
	}	
}