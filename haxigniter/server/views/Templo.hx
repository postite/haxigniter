package haxigniter.server.views;

class TemploVars
{
	public function new() {}
}

class Templo extends ViewEngine
{
	private var templateVars : TemploVars;
	private var macros : String;
	private var optimized : Bool;
	
	public function new(?macros : String = null, ?optimized : Bool = false, templatePath : String = null, compiledPath : String = null)
	{
		this.templateExtension = 'mtt';
		
		// super() will set correct variables for TemplatePath and CompiledPath
		super(templatePath, compiledPath);
		
		this.macros = macros;
		this.optimized = optimized;

		this.templateVars = new TemploVars();
	}
	
	public override function assign(name : String, value : Dynamic) : Void
	{
		Reflect.setField(this.templateVars, name, value);
	}
	
	public override function clearAssign(name : String) : Bool
	{
		return Reflect.deleteField(this.templateVars, name);
	}

	public override function render(fileName : String) : String
	{
		templo.Loader.BASE_DIR = this.templatePath;
		templo.Loader.TMP_DIR = this.compiledPath;
		templo.Loader.MACROS = this.macros;
		templo.Loader.OPTIMIZED = this.optimized;

		var t = new templo.Loader(fileName);
		return t.execute(this.templateVars);
	}
}
