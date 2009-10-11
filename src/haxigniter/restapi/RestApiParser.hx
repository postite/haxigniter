package haxigniter.restapi;

import haxigniter.restapi.RestApiRequest;
import haxigniter.exceptions.RestApiException;

/* 
   Css-selector parser written and kindly donated by John A. De Goes.
*/

enum Modifier {
    pseudo    (value:String);
    pseudoFunc(name:String, args:Array<String>);
    className (value:String);
    hash      (value:String);
    attribute (name:String, operator:String, value:String);
}

/**
 * A segment of a selector.
 */
class SelectorSegment {
    private static var NAME_P:EReg = ~/^(\*|[\-\w]+)/i;
    private static var HC_P  :EReg = ~/^(#|\.)([\-\w]+)/i;
    
    private static var PSEUDO_FUNC_P = ~/^:([\w\-]+)\(/i;
    private static var PSEUDO_P      = ~/^:([\w\-]+)/i;
    private static var ATTR_P        = ~/^\[([^\]]+)\]/;
    
    private static var ATTR_S_P      = ~/^([\w\-]+)(?:([=|!~*\^$]+)['"]?([\w\-]+)["']?)?$/i;
    
    public var name       (default, null):String;
    public var modifiers  (default, null):Array<Modifier>;
    
    public function new(name:String, modifiers:Array<Modifier>) {
        this.name       = name;
        this.modifiers  = modifiers;
    }
    
    public function stateless():SelectorSegment {
        return new SelectorSegment(name, new Array<Modifier>());
    }
    
    /**
     * Parses a single segment. Requires that any combinators (' ', '>', and 
     * '+') be grouped at the start of the string.
     */
    public static function parse(input:String):SelectorSegment {
        input = StringTools.trim(input);
        
        var name       = '*';
        var modifiers  = new Array<Modifier>();
        
        if (NAME_P.match(input)) {
            name = NAME_P.matched(1);
            
            input = input.substr(NAME_P.matched(0).length);
        }
        
        while (HC_P.match(input)) {
            var mod = HC_P.matched(1);
            var str = HC_P.matched(2);
            
            if (mod == '#') {
                modifiers.push(Modifier.hash(str));
            }
            else if (mod == '.') {
                modifiers.push(Modifier.className(str));
            }
            else {
                throw "Unknown modifier: " + input;
            }        
            
            input = input.substr(HC_P.matched(0).length);
        }
        
        var i = 0;
        
        while (i < input.length) {
            var remainder = input.substr(i);
			
			// PSEUDO_FUNC_P must be above PSEUDO_P since the latter is a subset of the first.
			if (PSEUDO_FUNC_P.match(remainder)) {
				var parsed = { length : null };
                var pseudoFunc = parsePseudoFunc(remainder.substr(1), // Sub one for the colon
				                                 PSEUDO_FUNC_P.matched(1).length, // Function name
												 parsed); // Parsed string length
												 
                modifiers.push(pseudoFunc);
                
                i += parsed.length + 1; // Add 1 for the colon
            }
            else if (PSEUDO_P.match(remainder)) {
                var pseudo = PSEUDO_P.matched(1);
                
                modifiers.push(Modifier.pseudo(pseudo));
                
                i += PSEUDO_P.matched(0).length;
            }
            else if (ATTR_P.match(remainder)) {
                var attr = ATTR_P.matched(1);
                
                if (ATTR_S_P.match(attr)) {
                    var name  = ATTR_S_P.matched(1);
                    var op    = ATTR_S_P.matched(2);
                    var value = ATTR_S_P.matched(3);
                    
                    modifiers.push(Modifier.attribute(name, op, value));
                }
                else {
                    throw "Unrecognized attribute selector format: " + attr;
                }
                
                i += ATTR_P.matched(0).length;
            }
            else {
                throw "Unrecognized selector segment: " + remainder;
            }
        }
        
        return new SelectorSegment(name, modifiers);
    }
    
    public function toString():String {
        return "SelectorSegment(" + name + ", modifiers=" + modifiers + ")";
    }
	
    /**
     * Parse the arguments in a function string.
     * @param    args Input string, starting with a function name and following parenthesis with arguments.
     * @param   str  Length of the parsed string is contained in str.length.
     * @return  A Modifier.pseudoFunc()
     */
    private static function parsePseudoFunc(func : String, funcNameLength : Int, parsed : { length: Int } ) : Modifier {
        var funcName = func.substr(0, funcNameLength);
        var funcParams = [];
        
        var insideSQuote = false;
        var insideDQuote = false;

        var i = funcNameLength; // +1 in the first loop for the initial parenthesis.
        var param = new StringBuf();
        
        while (++i < func.length) {
            var char = func.charAt(i);

			if (!insideDQuote && !insideSQuote)
            {
                if (char == '"')
                    insideDQuote = true;
                else if (char == "'")
                    insideSQuote = true;
                else if (char == "," || char == ")") {
                    funcParams.push(param.toString());
                    
                    if(char == ")")
                    {
                        // Add the last char to the index counter and exit.
                        ++i; 
                        break;
                    }
                    else
                        param = new StringBuf();
                }
                else
                    param.add(char);
            }
			else {
				if (char == '"' && insideDQuote)
					insideDQuote = false;
				else if (char == "'" && insideSQuote)
					insideSQuote = false;
				else if (char == '\\') {
					// Escaping char, add the next char instead.
					param.add(func.charAt(++i));
				}
				else
					param.add(char);
			}
		}

        // Set parsed length so it can be used in the main parser
        parsed.length = i;
        return Modifier.pseudoFunc(funcName, funcParams);
    }
}

/**
 * Represents a complete selector; e.g.: #foo >bar.first:hover
 */
class Selector {
    private static var COMBINATOR_SPACE_P:EReg = ~/\s+([>+~])\s+/g;
    
    public var segments (default, null):Array<SelectorSegment>;
    
    public function new(segments:Array<SelectorSegment>) {
        this.segments = segments;
    }
    
    public function slice(start:Int, end:Int = -1):Selector {
        if (end == -1) end = segments.length;
        
        return new Selector(segments.slice(start, end));
    }
    
    public function iterator():Iterator<Null<SelectorSegment>> {
        return segments.iterator();
    }
    
    public function stateless():Selector {
        return new Selector(
            Lambda.array(
                Lambda.map(
                    segments,
                    function (s) {
                        return s.stateless();
                    }
                )
            )
        );
    }
    
    public static function parse(input:String):Selector {
        input = StringTools.trim(input);
        
        var segments = new Array<SelectorSegment>();
        
        for (segment in splitSegs(input)) {
            if (segment != '') {
                segments.push(SelectorSegment.parse(segment));
            }
        }
        
        return new Selector(segments);
    }
    
    public function toString() {
        return "Selector(" + segments + ")";
    }
    
    private function getLength():Int {
        return segments.length;
    }
    
    public static function splitSegs(input:String):Array<String> {
        // Eliminate all spaces before/after sibling/child combinators:
        input = COMBINATOR_SPACE_P.replace(input, '$1');
        
        // Eliminate duplicate spaces:
        input = ~/\s+/g.replace(input, ' ');
        
        var segs = new Array<String>();
        
        var buf    = new StringBuf();
        var length = 0;
        
        for (i in 0...input.length) {
            var c = input.charAt(i);
            
            // Child, next sibling, descendant, following sibling:
            if (c == ' ' || c == '+' || c == '>' || c == '~') {
                if (length > 0) {
                    segs.push(buf.toString());
                    
                    length = 0;
                    buf    = new StringBuf();
                }
            }
            
            ++length;
            buf.add(c);
        }
        
        if (length > 0) {
            segs.push(buf.toString());
        }
        
        return segs;
    }
}

/////////////////////////////////////////////////////////////////////

class RestApiParser
{
	private static var validResourceName : EReg = ~/^\w+$/;
	private static var oneResource : EReg = ~/^[1-9]\d*$/;
	private static var viewResource : EReg = ~/^\w+$/;

	private static var my_stringToOperator : Hash<RestResourceOperator>;
	private static function stringToOperator() : Hash<RestResourceOperator>
	{
		if(my_stringToOperator == null)
		{
			my_stringToOperator = new Hash<RestResourceOperator>();

			my_stringToOperator.set('*=', RestResourceOperator.contains);
			my_stringToOperator.set('$=', RestResourceOperator.endsWith);
			my_stringToOperator.set('=', RestResourceOperator.equals);
			my_stringToOperator.set('<', RestResourceOperator.lessThan);
			my_stringToOperator.set('<=', RestResourceOperator.lessThanOrEqual);
			my_stringToOperator.set('>', RestResourceOperator.moreThan);
			my_stringToOperator.set('>=', RestResourceOperator.moreThanOrEqual);
			my_stringToOperator.set('!=', RestResourceOperator.notEqual);
			my_stringToOperator.set('^=', RestResourceOperator.startsWith);
		}
		
		return my_stringToOperator;
	}
	
	private static inline function validResourceTest(resource : String) : Void
	{
		if(!validResourceName.match(resource))
			throw new RestApiException('Invalid resource: ' + resource);
	}
	
	public static function parse(decodedUrl : String) : Array<RestApiSelector>
	{
		var output = new Array<RestApiSelector>();
		
		// Remove start and end slash
		if(StringTools.startsWith(decodedUrl, '/'))
			decodedUrl = decodedUrl.substr(1);

		if(StringTools.endsWith(decodedUrl, '/'))
			decodedUrl = decodedUrl.substr(0, decodedUrl.length - 1);

		// Split url and pair the resources with the types
		var urlSegments = decodedUrl.split('/');
		var i = 0;
		
		//trace(urlSegments);
		
		while(i < urlSegments.length)
		{
			output.push(parseSelector(urlSegments[i++], urlSegments[i++]));
		}
		
		return output;
	}
	
	public static function parseSelector(resource : String, data : String) : RestApiSelector
	{
		validResourceTest(resource);
		
		// Detect resource type.
		if(data == null)
			return RestApiSelector.all(resource);
		
		if(oneResource.match(data))
			return RestApiSelector.one(resource, Std.parseInt(data));
		
		if(viewResource.match(data))
			return RestApiSelector.view(resource, data);
		
		try
		{
			// Concatenate all Modifiers from selector.
			var output = new Array<Modifier>();
			for(selector in Selector.parse(data))
			{
				output = output.concat(selector.modifiers);
			}
			
			return RestApiSelector.some(resource, Lambda.array(Lambda.map(output, cssToRest)));
		}
		catch(e : String)
		{
			throw new RestApiException(e);
		}
	}
	
	private static function cssToRest(modifier : Modifier) : RestResourceSelector
	{
		var field : String;
		var operator : RestResourceOperator = null;
		var value : String = null;
		
		switch(modifier)
		{
			case pseudo(name):
				return RestResourceSelector.func(name, new Array<String>());
			case pseudoFunc(name, args):
				return RestResourceSelector.func(name, args);
			case className(value), hash(value):
				throw new RestApiException('Invalid modifier: ' + value);
			case attribute(name, operator, value):
				return RestResourceSelector.attribute(name, getOperator(operator), value);
		}
	}
	
	private static function getOperator(stringOperator : String) : RestResourceOperator
	{
		var output = stringToOperator().get(stringOperator);
		if(output == null)
			throw new RestApiException('Invalid operator: ' + stringOperator);
		
		return output;
	}
}











