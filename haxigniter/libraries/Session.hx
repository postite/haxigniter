package haxigniter.libraries; 

#if php
typedef InternalSession = php.Session;
#elseif neko
typedef InternalSession = haxigniter.neko.Session;
#end

// TODO: Test flash vars in neko.
class Session implements Dynamic 
{
	// Internal flag for when flash is retrieved
	// It must be static because static vars aren't serialized.
	private static var gotCurrentFlash : Bool = false;
	private static var currentFlash : Dynamic = null;

	private static var namespace = '_haxigniter_';
	private static var flashNamespace = '_flash_';

	public var flashVar(getFlash, setFlash) : Dynamic;
	private function getFlash()
	{
		// If no flash request is done, get the current flash var and remove it.
		if(!gotCurrentFlash && this.exists(flashNamespace))
		{
			gotCurrentFlash = true;
			
			Session.currentFlash = this.get(flashNamespace);
			this.remove(flashNamespace);
		}
		
		return Session.currentFlash;
	}
	private function setFlash(value : Dynamic)
	{
		// Need to set gotCurrentFlash here so it's not removed by getFlash() in the same request.
		gotCurrentFlash = true;

		this.set(flashNamespace, value);

		Session.currentFlash = value;
		return Session.currentFlash;
	}
	
	/**
	* This class is abstract, so constructor is private.
	*/
	private function new() { }

	public function get(name : String) : Dynamic
	{
		return InternalSession.get(namespace + name);
	}

	public function set(name : String, value : Dynamic) : Void
	{
		InternalSession.set(namespace + name, value);
	}

	public function exists(name : String) : Bool
	{
		return InternalSession.exists(namespace + name);
	}

	public function remove(name : String) : Bool
	{
		var output = this.exists(name);
		InternalSession.remove(namespace + name);
		
		return output;
	}
}
