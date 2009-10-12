package haxigniter.exceptions;

import haxigniter.restapi.RestApiResponse;

class RestApiException extends haxigniter.exceptions.Exception
{
	public var error(default, null) : RestErrorType;
	
	public function new(message : String, ?error : RestErrorType, ?code : Int = 0, ?stack : haxe.PosInfos)
	{
		this.error = error;		
		super(message, code, stack);
	}
}
