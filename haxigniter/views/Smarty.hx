#if php
package haxigniter.views;

/**
 * IMPORTANT NOTE: For smarty to work in haXe, you need to make a small adjustment to the file "internals/core.write_file.php".
 * You need to change this line:
 * 
 *      @unlink($params['filename']);
 * 
 * Into the following:
 * 
 *      if(file_exists($params['filename'])) 
 *            @unlink($params['filename']);
 * 
 * For more information: http://tylermac.wordpress.com/2009/09/06/haxe-php-smarty-flashdevelop/
 * 
 */
class Smarty extends haxigniter.views.ViewEngine
{
	private var smartyEngine : haxigniter.application.external.Smarty;
	
	private var cacheId : String;
	private var cachePath : String;
	
	public function new(?cachePath : String, ?cacheId : String, templatePath : String = null, compiledPath : String = null)
	{
		this.templateExtension = 'tpl';
		
		this.smartyEngine = new haxigniter.application.external.Smarty();

		// super() will set correct variables for templatePath and compiledPath
		super(templatePath, compiledPath);

		this.cachePath = cachePath;
		this.cacheId = cacheId;
	}

	private inline function toPhpValue(value : Dynamic) : Dynamic
	{
		// TODO: This is only compatible with 2.05 or better.
		/*
		if(Std.is(value, Hash))
			return php.Lib.associativeArrayOfHash(value);
		else
		*/
			return value;
	}

	public override function assign(name : String, value : Dynamic) : Void
	{
		this.smartyEngine.assign(name, this.toPhpValue(value));
	}
	
	public override function clearAssign(name : String) : Bool
	{
		var exists = this.smartyEngine.get_template_vars(name) != null;
		this.smartyEngine.clear_assign(name);
		
		return exists;
	}

	public override function render(fileName : String) : String
	{
		this.smartyEngine.template_dir = this.templatePath;
		this.smartyEngine.compile_dir = this.compiledPath;

		return this.smartyEngine.fetch(fileName, this.cacheId);
	}
}
#end
