package haxigniter.session; 

class SessionObject
{
	///// Static stuff for the wrapper //////////////////////////////

	private static var session : Session;	
	private static var sessionName : String = '_haxigniter_session_';

	private static var flashName = '_flash';
	
	public static function restore<T>(session : Session, classType : Class<T>, ?classArgs : Array<Dynamic>) : T
	{
		if(SessionObject.session != null && SessionObject.session != session)
			throw 'Cannot change session handler for SessionObject.';
		else
			SessionObject.session = session;
		
		var object = objectName(classType);
		
		if(!session.exists(object))
		{
			session.set(object, Type.createInstance(classType, classArgs == null ? [] : classArgs));
		}
		
		return cast session.get(sessionName);
	}
	
	private static function objectName(classType : Class<Dynamic>) : String
	{
		return sessionName + Type.getClassName(classType);
	}

	/////////////////////////////////////////////////////////////////
	
	public var flashVar(getFlash, setFlash) : Dynamic;
	private function getFlash()
	{
		var object = objectName(Type.getClass(this));
		return session.exists(object + flashName) ? session.get(object + flashName) : null;
	}
	private function setFlash(value : Dynamic)
	{
		var object = objectName(Type.getClass(this));		
		return session.set(object + flashName, value);
	}
	
	/**
	* This class should only be created with the restore() factory method, so constructor is private.
	*/
	private function new() { }
}
