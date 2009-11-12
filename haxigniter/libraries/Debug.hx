package haxigniter.libraries;

#if php
import php.Lib;
import php.io.File;
import php.io.FileOutput;
import php.FileSystem;
#elseif neko
import neko.Lib;
import neko.io.File;
import neko.io.FileOutput;
import neko.FileSystem;
#end

class Debug
{
	public static var traceLevel : DebugLevel = DebugLevel.info;
	
	private static var config = haxigniter.application.config.Config.instance();
	
	public static function log(message : Dynamic, ?debugLevel : DebugLevel) : Void
	{
		if(debugLevel == null) debugLevel = DebugLevel.info;

		if(Debug.toInt(debugLevel) > Debug.toInt(config.logLevel))
			return;
		
		var logFile = config.logPath + 'log-' + DateTools.format(Date.now(), "%Y-%m-%d");
		
		#if php
		logFile += '.php';
		#elseif neko
		logFile += '.n';
		#end
		
		var output = '';
		
		#if php
		if(!FileSystem.exists(logFile))
			output += "<?php exit; ?>\n\n";
		#end
		
		output += Std.string(debugLevel).toUpperCase() + ' - ' + DateTools.format(Date.now(), config.logDateFormat) + ' --> ' + message + "\n";
		
		var file : FileOutput = File.append(logFile, false);
		file.writeString(output);
		file.close();
	}
	
	public static function trace(data : Dynamic, ?traceLevel : DebugLevel, ?pos : haxe.PosInfos) : Void
	{
		if(traceLevel == null) traceLevel = DebugLevel.info;
		
		if(Debug.toInt(traceLevel) > Debug.toInt(Debug.traceLevel))
			return;
		
		Lib.print('<pre style="border:1px dashed green; padding:2px; background-color:#F9F8F6;">');
		
		#if php
		Debug.startBuffer();
		haxe.Log.trace(data, pos);
		var output = StringTools.htmlEscape(Debug.endBuffer());
		
		Lib.print(Debug.colorize(output));
		
		#elseif neko
		haxe.Log.trace(data, pos);
		#end
		
		Lib.print('</pre>');
	}
	
	public static function toInt(level : DebugLevel) : Int
	{
		return switch(level)
		{
			case off: 0;
			case error: 1;
			case warning: 2;
			case info: 3;
			case verbose: 4;
		}
	}
	
	#if php
	public static function startBuffer() : Void
	{
		untyped __call__('ob_start');
	}
	
	public static function endBuffer() : String
	{
		return untyped __call__('ob_get_clean');
	}
	#end
	
	/////////////////////////////////////////////////////////////////
	
	private static function colorize(data : String) : String
	{
		var title : EReg = ~/^([^:]+:\d+:)/;
		
		title.match(data);		
		var header : String = title.matched(1);
		
		data = title.replace(data, '');

		var tabs : EReg = ~/\t/g;
		data = tabs.replace(data, '  ');
		
		var strings : EReg = ~/("[^"]*")/g;
		data = strings.replace(data, '<span style="color:#C31515;">$1</span>');

		var num : EReg = ~/\b(\d+\.?\d*)\b/g;
		data = num.replace(data, '<span style="color:#008000;">$1</span>');

		var bools : EReg = ~/\b(true|false)\b/g;
		data = bools.replace(data, '<span style="color:#1518FF;">$1</span>');

		return '<b>' + header + '</b>' + data;
	}
}
