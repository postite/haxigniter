package haxigniter.libraries;

class IterableTools
{
	public static function isSubsetOf<T>(subSet : Iterable<T>, bigSet : Iterable<T>) : Bool
	{
		for(v in subSet)
		{
			if(!Lambda.has(bigSet, v))
				return false;
		}
		
		return true;
	}

	public static function arraySearch<T>(array : Array<T>, searchFor : T) : Null<Int>
	{
		for(i in 0 ... array.length)
		{
			if(array[i] == searchFor)
				return i;
		}
		
		return null;
	}	
}
