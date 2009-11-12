import neko.FileSystem;
import neko.Lib;
import neko.Sys;
import neko.io.File;
import neko.FileSystem;

import mirror.Mirror;
import getpot.GetPot;

class Main 
{
	static var options : GetPot;
	static var libPath : String;
	
	static var validCommands = [
		'help', 
		'init',
		'unittest'
		];
		
	static var validCommandsHelp = [
		'Display this help text.',
		'Create a project structure in a specified directory.',
		'Run the unit tests. Run with "-all" to run the haXigniter test suite too.'
		];
	
	static function main() 
	{
		var command = Sys.args()[0];
		
		if(command == null || Lambda.has(['--help', '-help', '-?'], command))
		{
			help();
			Sys.exit(1);
		}
		else if(!Lambda.has(validCommands, command))
		{
			Lib.println('Command not found: ' + command);
			Lib.println('');
			
			help();
			Sys.exit(1);
		}
		else
		{
			options = new GetPot(Sys.args().slice(1));
			
			// Get path to the haxigniter library.
			var process = new neko.io.Process('haxelib', ['path', 'haxigniter']);
			libPath = process.stdout.readAll().toString();
			
			if(new EReg('not installed', '').match(libPath))
				libPath = '.\\';

			process.close();
			
			Sys.exit(Reflect.field(Main, command)());
		}
	}
	
	static function stringRepeat(input : String, count : Int) : String
	{
		var buffer = new StringBuf();
		while(count-- > 0)
			buffer.add(input);
		
		return buffer.toString();
	}

	///// Commands //////////////////////////////////////////////////

	static function help() : Int
	{
		var tabLength = Lambda.fold(validCommands, function(command : String, length : Int) {
			return cast(Math.max(length, command.length), Int);
		}, 0);
		
		Lib.println('Valid commands are:');
		
		for(i in 0 ... validCommands.length)
		{
			Lib.println('  ' + validCommands[i] + stringRepeat(' ', tabLength - validCommands[i].length + 5) + validCommandsHelp[i]);
		}
		
		//Lib.println('');
		//Lib.println('Use "help COMMAND" for help about a specific command.');		
		return 1;
	}
	
	static function init() : Int
	{
		var path = options.unknown();
		if(path == null)
		{
			Lib.print('Select directory to create haXigniter project in (blank = exit): ');
			path = File.stdin().readUntil(10);
		}
		
		path = FileSystem.fullPath(path.length == 0 ? '.' : path);
		
		if(FileSystem.exists(path))
		{
			Lib.println('Error: "' + path + '" already exists.');
			return 1;
		}
		else
			FileSystem.createDirectory(path);

		var mirror = new Mirror(libPath + 'skel', path);
		mirror.mirror();
		
		return 0;
	}

	static function unittest() : Int
	{
		var path = libPath + 'tools\\runsrc';
		
		var status = Sys.command('haxe', ['-cp', path, '-main', 'RunUnitTests', '-x', path + '\\unittest.hx']);
		FileSystem.deleteFile(path + '\\unittest.hx.n');
		
		return status;
	}
}