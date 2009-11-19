import neko.Lib;
import neko.Sys;
import neko.io.File;
import neko.FileSystem;

import mirror.Mirror;
import getpot.GetPot;

using StringTools;
class Main 
{
	static var options : GetPot;
	static var commands : Array<String>;
	static var libPath : String;
	
	static var validCommands = [
		'build',
		'help', 
		'init',
		'unittest'
		];
		
	static var validCommandsHelp = [
		'[buildfile.hxml] Build the project, if no buildfile is specified the first found in the directory will be used.',
		'Display this help text.',
		'Create a project structure in a specified directory.',
		'Run the haXigniter unit test suite.'
		];
	
	static function main() 
	{
		var args = Sys.args();
		
		// haxelib appends cwd automatically, so if running from command line,
		// next-last argument should be set to "--" for detecting.
		if(args.length >= 1)
		{
			if(args[args.length-1] != '--')
				Sys.setCwd(args.pop());
			else
				args.pop();
		}

		var command = args[0];
		if(command == null || Lambda.has(['--help', '-help', '-?', '/?'], command))
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
			commands = args.slice(1);
			options = new GetPot(commands);
			
			// Get path to the haxigniter library.
			var process = new neko.io.Process('haxelib', ['path', 'haxigniter']);
			libPath = process.stdout.readUntil(10).trim();
			process.close();
			
			if(new EReg('not installed', '').match(libPath))
			{
				Lib.println('Error: haxigniter is not installed. Use "haxelib install haxigniter" to install it.');
				Sys.exit(1);
			}
			
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

	static function error(message : String) : Int
	{
		Lib.println('Error: ' + message);
		return 1;		
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
	
	static function build() : Int
	{
		var buildFile = options.unknown();
		if(buildFile == null)
		{
			for(file in FileSystem.readDirectory('.'))
			{
				if(file.endsWith('.hxml'))
				{
					buildFile = file;
					break;
				}
			}
			
			if(buildFile == null)
				return error('No .hxml file found in current directory!');
		}
		else if(!FileSystem.exists(buildFile))
		{
			return error(buildFile + ' not found!');
		}
		
		var outputPath : String;
		var content = File.getContent(buildFile);
		
		var phpTest = ~/-php\s+(.+)\b/;
		var nekoTest = ~/-neko\s+(.+)[\/]\b/;
		
		if(phpTest.match(content))
			outputPath = parseArgument(phpTest.matched(1));
		else if(nekoTest.match(content))
			outputPath = parseArgument(nekoTest.matched(1));
		else
			return error('No output directory found in .hxml file!');
		
		buildStructure(outputPath);
		
		// Build the project. Use the original commands as extra arguments.
		commands.unshift(buildFile);
		
		return Sys.command('haxe', commands);
	}

	static function buildStructure(path : String) : Int
	{
		// Create dir structure
		createIfNotExists(path + '/lib');
		createIfNotExists(path + '/lib/runtime');
		createIfNotExists(path + '/lib/runtime/logs');
		createIfNotExists(path + '/lib/runtime/cache');
		createIfNotExists(path + '/lib/runtime/session');
		
		// Create .htaccess
		var htaccess = path + '/lib/.htaccess';
		
		if(!FileSystem.exists(htaccess))
		{
			var file = File.write(htaccess, false);
			file.writeString("order deny,allow\ndeny from all\nallow from none\n");
			file.close();
		}
		
		return 0;		
	}
	
	static function createIfNotExists(path : String) : Void
	{
		if(!FileSystem.exists(path))
			FileSystem.createDirectory(path);
	}
	
	/**
	 * Parses the first argument in a long string. 
	 * "quoted argument with spaces" or noSpaces/atAll for example.
	 * @param	input
	 * @return
	 */
	static function parseArgument(input : String) : String
	{
		if(!input.startsWith('"') && !input.startsWith("'"))
		{
			var string = ~/^\S+/;
			string.match(input);
			
			return string.matched(0);
		}

		var output = '';
		for(i in 1 ... input.length)
		{
			var char = input.charAt(i);
			
			if(char == '"' || char == "'")
				return output;
			else
				output += char;
		}
		
		return output;
	}
	
	static function init() : Int
	{
		var path = options.unknown();
		if(path == null)
		{
			Lib.print('Select directory to create haXigniter project in (blank = current dir, Ctrl+C to exit): ');
			path = File.stdin().readUntil(10);
		}
		
		path = FileSystem.fullPath(path.length == 0 ? '.' : path);
		
		if(!FileSystem.exists(path))
		{
			FileSystem.createDirectory(path);
		}
		else if(!FileSystem.isDirectory(path))
		{
			return error(path + '" is not a directory.');
		}
		
		Lib.println('Copying project structure to ' + path);

		var mirror = new Mirror(libPath + 'skel', path);
		mirror.mirror();

		Lib.println('Finished. To build the project, goto ' + path + ' and enter "ignite build".');
		return 0;
	}

	static function unittest() : Int
	{
		var path = libPath + 'tools/runsrc';			
		Sys.setCwd(path);
				
		var status = Sys.command('haxe', ['-lib', 'haxigniter', '-main', 'RunUnitTests', '-x', 'rununittests']);
		
		if(FileSystem.exists('rununittests.n'))
			FileSystem.deleteFile('rununittests.n');
		
		return status;
	}
}