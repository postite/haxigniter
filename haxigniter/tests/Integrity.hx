package haxigniter.tests;

#if php
import php.FileSystem;
import php.io.File;
import php.Lib;
import php.Web;
#elseif neko
import neko.FileSystem;
import neko.io.File;
import neko.Lib;
import neko.Web;
#end

class Integrity
{
	public var testMethodPrefix : String;
	private var config : haxigniter.libraries.Config;
	
	public static function runTests() : Void
	{
		new haxigniter.application.tests.Integrity().run();
	}
	
	public function new()
	{
		this.config = haxigniter.Application.instance().config;
		this.testMethodPrefix = 'test';
	}
	
	public function run() : Void
	{
		this.printHeader('Development mode: ' + (this.config.development ? 'True' : 'False') + '<br><br>');
		
		for(field in Type.getInstanceFields(Type.getClass(this)))
		{
			if(StringTools.startsWith(field, this.testMethodPrefix) && Reflect.isFunction(Reflect.field(this, field)))
				runTest(field);
		}
	}
	
	private function runTest(methodName : String) : Void
	{
		var title = {value: methodName};
		var result : Bool = Reflect.callMethod(this, Reflect.field(this, methodName), [title]);
		
		if(result != null)
		{
			Lib.print('<div style="font-family: Verdana; font-size:12px; float:left; display:inline; padding:4px; margin:1px; border:1px solid gray; width:99%;">');
			Lib.print('<div style="float:left; padding:0 3px 0 3px;">' + title.value + '</div>');

			if(result == true)
				Lib.print('<div style="width:70px; float:right; background-color:#2D1; padding:1px 3px 1px 3px; text-align:center;">OK</div>');
			else
				Lib.print('<div style="width:70px; float:right; background-color:#C12; padding:1px 3px 1px 3px; text-align:center;">FAILED</div>');

			//else if(result == null)
				//Lib.print('<div style="width:70px; float:right; padding:1px 3px 1px 3px; text-align:center;"><strong>?</strong></div>');
		
			Lib.print('</div>');
			Web.flush();
		}
	}
	
	private function printHeader(text : String) : Void
    {
        Lib.print('<div style="font-family: Verdana; font-size:13px; font-weight:bold; float:left; display:inline; padding:8px 4px 0 4px; margin:1px; border:0; width:99%;">');
        Lib.print('<div style="float:left; padding:0;">' + text + '</div></div>');
		Web.flush();
    }

	private function isWritable(path : String) : Bool
	{
		#if php
		return untyped __call__('is_writable', path);
		#elseif neko
		if(StringTools.endsWith(path, '/'))
			path = path.substr(0, path.length-1);

		if(!FileSystem.exists(path)) return false;
		
		switch(FileSystem.kind(path))
		{
			case FileKind.kfile:
				try
				{
					File.append(path, true).close();
					return true;
				}
				catch(e : Dynamic)
				{
					return false;
				}
			
			case FileKind.kdir:	
				try
				{
					var test = File.write(path + '/__isWritableNekoTest.tmp', true);
					test.writeString('');
					test.close();
					
					FileSystem.deleteFile(path + '/__isWritableNekoTest.tmp');
					return true;
				}
				catch(e : Dynamic)
				{
					return false;
				}
			
			default:
				throw 'isWritable(): Only files and directories are supported.';
		}
		#end
	}
	
	/////////////////////////////////////////////////////////////////
	
	public function test1(title : { value : String }) : Bool
	{
		printHeader('[haXigniter] Directory access');
		
		title.value = 'Cache path <b>"' + config.cachePath + '"</b> exists and is writable';
		return this.isWritable(config.cachePath);
	}

	public function test2(title : { value : String }) : Bool
	{
		title.value = 'Log path <b>"' + config.logPath + '"</b> exists and is writable';
		return this.isWritable(config.logPath);
	}

	public function test3(title : { value : String }) : Bool
	{
		title.value = 'Session path <b>"' + config.sessionPath + '"</b> exists and is writable';
		return this.isWritable(config.sessionPath);
	}

	public function test4(title : { value : String }) : Bool
	{
		printHeader('[haXigniter] File integrity');

		var htaccess = FileSystem.fullPath(config.applicationPath + '../../.htaccess');

		title.value = '<b>"' + htaccess + '"</b> exists to prevent access to haXigniter files';
		
		return FileSystem.exists(htaccess);
	}

	#if php
	public function test5(title : { value : String }) : Bool
	{
		var smarty = FileSystem.fullPath(config.applicationPath + 'external/smarty/libs/internals/core.write_file.php');

		if(!FileSystem.exists(smarty))
			return null;

		title.value = 'Smarty file <b>"' + smarty + '"</b> is patched according to haxigniter/views/Smarty.hx';
		
		var patch : EReg = ~/file_exists\s*\([^\)]*\$params\[['"]filename['"]\]/;
		
		return patch.match(File.getContent(smarty));
	}
	#end
}
