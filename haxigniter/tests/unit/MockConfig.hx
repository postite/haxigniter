package haxigniter.tests.unit;

import haxigniter.libraries.Debug; 
import haxigniter.libraries.DebugLevel;

#if php
import php.Sys; import php.Web;
#elseif neko
import neko.Sys; import neko.Web;
#end

class MockConfig extends haxigniter.libraries.Config
{
	public function new(?dumpEnv : Dynamic)
	{
		development = Web.getHostName() == 'localhost';
		
		controllerPackage = 'haxigniter.tests.unit';
		defaultController = 'start';
		defaultAction = 'index';

		#if php
		indexFile = null;
		#elseif neko
		indexFile = 'index.n';
		#end
		
		#if php
		indexPath = null;
		#elseif neko
		indexPath = '/';
		#end

		siteUrl = null;
		applicationPath = null;		
		viewPath = null;
		
		logPath = null;
		cachePath = null;
		sessionPath = null;

		permittedUriChars = 'a-z 0-9~%.:_-';

		logLevel = this.development ? DebugLevel.info : DebugLevel.warning;
		logDateFormat = '%Y-%m-%d %H:%M:%S';

		errorPage = null;
		error404Page = null;

		language = 'english';

		encryptionKey = null;
		
		// Set default variables in super class.
		super(dumpEnv);
	}
}
