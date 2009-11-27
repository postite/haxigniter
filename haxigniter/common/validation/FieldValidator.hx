package haxigniter.common.validation;
import haxigniter.common.libraries.IterableTools;

enum ValidationResult
{
	success;
	tooMany(extraFields : List<String>);
	tooFew(missingFields : List<String>);
	failure(fields : List<String>);
}

enum ValidationType
{
	exactMatch;
	allowTooFew;
}

class FieldValidator 
{
	private var fields : Hash<EReg>;
	private var callbacks : Hash<String -> Bool>;
	private var validationType : ValidationType;
	
	private var allFields : Hash<Bool>;
	
	/**
	 * Creates a new instance of the FieldValidator.
	 * @param	fields An anonymous object of EReg objects.
	 * @param	callbacks For more advanced behaviour, a Hash of callbacks that takes a string and returns whether the validation succeeded or not.
	 */
	public function new(fields : Dynamic, ?callbacks : Dynamic<String -> Bool>, ?validationType : ValidationType)
	{
		this.allFields = new Hash<Bool>();
		
		this.fields = objectToHash(fields);
		this.callbacks = objectToHash(callbacks);
		this.validationType = validationType == null ? ValidationType.exactMatch : validationType;
	}
	
	public function validateField(field : String, value : Dynamic) : Bool
	{
		var test : EReg = null;
		var method : String -> Bool = null;
		
		if(fields.exists(field))
			test = fields.get(field);
		
		if(callbacks.exists(field))
			method = callbacks.get(field);
		
		if(test == null && method == null)
			throw 'Field "' + field + '" not found in FieldValidator.';

		if(!Std.is(value, String))
		{
			if(Reflect.isObject(value) || Reflect.isFunction(value))
				throw 'Field "' + field + '" is not a scalar value.';
			else
				value = Std.string(value);
		}

		if(test != null && !test.match(cast value))
			return false;
			
		if(method != null && !method(cast value))
			return false;
			
		return true;
	}
	
	public function validate(input : Dynamic, ?failOnFirst = false) : ValidationResult
	{
		var inputFields = Reflect.fields(input);
		var validFields = { iterator: allFields.keys };

		var extraFields = IterableTools.difference(inputFields, validFields);
		if(extraFields.length > 0)
			return ValidationResult.tooMany(extraFields);

		if(validationType != ValidationType.allowTooFew)
		{
			var fewFields = IterableTools.difference(validFields, inputFields);
			if(fewFields.length > 0)
				return ValidationResult.tooFew(fewFields);
		}
		
		var failures = new List<String>();
			
		for(field in inputFields)
		{
			var value = Reflect.field(input, field);
			
			if(!validateField(field, value))
				failures.push(field);
		}
		
		return failures.length == 0 ? ValidationResult.success : ValidationResult.failure(failures);
	}

	private function objectToHash<T>(object : Dynamic) : Hash<T>
	{
		var output = new Hash<T>();
		
		for(field in Reflect.fields(object))
		{
			if(!allFields.exists(field))
				allFields.set(field, true);
			
			output.set(field, Reflect.field(object, field));
		}
		
		return output;
	}
	
	/*
	private function hashToObject(hash : Hash<Dynamic>) : Dynamic
	{
		var output = {};
		for(field in hash.keys())
			Reflect.setField(output, field, hash.get(field));
		
		return output;
	}
	*/
}