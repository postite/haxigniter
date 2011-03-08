package haxigniter.server.views;
import haxigniter.server.Config;

class TemploVars
{
	public function new() {}
}

class Templo extends ViewEngine
{
	private var templateVars : TemploVars;
	private var macros : String;
	private var optimized : Bool;
	
	public function new(config : Config, ?macros : String = null, ?optimized : Bool = false)
	{
		super(config);
		this.templateExtension = 'mtt';
				
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
		mtwin.templo.Loader.BASE_DIR = this.templatePath;
		mtwin.templo.Loader.TMP_DIR = this.compiledPath;
		mtwin.templo.Loader.MACROS = this.macros;
		mtwin.templo.Loader.OPTIMIZED = this.optimized;

		var t = new mtwin.templo.Loader(fileName);
		return t.execute(this.templateVars);
	}
}
