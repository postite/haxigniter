package haxigniter.libraries;

import haxigniter.libraries.Debug;
import haxigniter.libraries.Controller;
import haxigniter.libraries.Database;

import haxigniter.application.config.Config;
import haxigniter.application.config.Session;

class Model
{
	//public var application(getApplication, null) : haxigniter.Application;
	//private function getApplication() : haxigniter.Application { return haxigniter.Application.instance(); }

	//public var controller(getController, null) : Controller;
	//private function getController() : Controller { return haxigniter.Application.instance().controller; }

	public var config(getConfig, null) : Config;
	private function getConfig() : Config { return haxigniter.Application.instance().config; }

	public var db(getDb, null) : DatabaseConnection;
	private function getDb() : DatabaseConnection { return haxigniter.Application.instance().db; }

	public var session(getSession, null) : Session;
	private function getSession() : Session { return haxigniter.Application.instance().session; }
	
	///// Convenience methods for debug and logging /////////////////
	
	private function trace(data : Dynamic, ?debugLevel : DebugLevel, ?pos : haxe.PosInfos) : Void
	{
		Debug.trace(data, debugLevel, pos);
	}
	
	private function log(message : Dynamic, ?debugLevel : DebugLevel) : Void
	{
		Debug.log(message, debugLevel);
	}
}
