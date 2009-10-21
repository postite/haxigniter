package haxigniter.controllers;

import haxigniter.libraries.Config;
import haxigniter.libraries.Database;
import haxigniter.libraries.Debug;
import haxigniter.libraries.DebugLevel;

import haxigniter.views.ViewEngine;
import haxigniter.application.config.Session;

class Controller implements haxe.rtti.Infos
{
	public var application(getApplication, null) : haxigniter.Application;
	private function getApplication() : haxigniter.Application { return haxigniter.Application.instance(); }

	public var config(getConfig, null) : Config;
	private function getConfig() : Config { return application.config; }

	public var view(getView, null) : ViewEngine;
	private function getView() : ViewEngine { return application.view; }

	public var db(getDb, null) : DatabaseConnection;
	private function getDb() : DatabaseConnection { return application.db; }

	public var session(getSession, null) : Session;
	private function getSession() : Session { return application.session; }	
	
	/**
	 * Handle a page request.
	 * @param	uriSegments Array of request segments (URL splitted with "/")
	 * @param	method Request method, "GET" or "POST" most likely.
	 * @param	params Query parameters
	 * @return  Any value that the controller returns.
	 */
	public function handleRequest(uriSegments : Array<String>, method : String, query : Hash<String>, rawQuery : String, ?rawRequestData : String) : Dynamic
	{
		var controllerType = Type.getClass(this);
		var controllerMethod : String = (uriSegments[1] == null) ? config.defaultAction : uriSegments[1];

		var callMethod : Dynamic = Reflect.field(this, controllerMethod);
		if(callMethod == null)
			throw new haxigniter.exceptions.NotFoundException(controllerType + ' method "' + controllerMethod + '" not found.');

		// Typecast the arguments.
		var arguments : Array<Dynamic> = haxigniter.types.TypeFactory.typecastArguments(controllerType, controllerMethod, uriSegments.slice(2));
		
		return Reflect.callMethod(this, callMethod, arguments);		
	}
	
	private function trace(data : Dynamic, ?debugLevel : DebugLevel, ?pos : haxe.PosInfos) : Void
	{
		Debug.trace(data, debugLevel, pos);
	}
	
	private function log(message : Dynamic, ?debugLevel : DebugLevel) : Void
	{
		Debug.log(message, debugLevel);
	}
}
