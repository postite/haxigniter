package haxigniter.restapi;

import haxigniter.exceptions.RestApiException;
import haxigniter.restapi.RestApiResponse;

enum RestResourceOperator
{
    contains;        // *=
    endsWith;        // $=
    equals;          // =
    lessThan;        // <
    lessThanOrEqual; // <=
    moreThan;        // >
    moreThanOrEqual; // >=
    notEqual;        // !=
    startsWith;      // ^=
}

enum RestResourceSelector
{
    func (name:String, args:Array<String>);
    attribute (name:String, operator:RestResourceOperator, value:String);
}
	
enum RestApiSelector
{
    one(resourceName : String, id : Int);
    all(resourceName : String);
    some(resourceName : String, query : Array<RestResourceSelector>);
    view(resourceName : String, viewName : String);
}

enum RestRequestType
{
	create;
	delete;
	get;
	update;
}

/////////////////////////////////////////////////////////////////////

class RestApiRequest 
{
	public var type(default, null) : RestRequestType;
    public var selectors(default, null) : Array<RestApiSelector>;
    public var format(default, null) : String;
    public var apiVersion(default, null) : Int;
    public var data(default, null) : Hash<String>; // Any PUT or POST data for create/update

	public function new(type : RestRequestType, selectors : Array<RestApiSelector>, format : String, apiVersion : Int, data : Hash<String>) 
	{
		if(type == null)
			throw new RestApiException('No request type specified.', RestErrorType.invalidRequestType);
		if(selectors == null)
			throw new RestApiException('No selectors in request.', RestErrorType.invalidQuery);
		if(format == null)
			throw new RestApiException('No output format specified.', RestErrorType.invalidOutputFormat);
		if(apiVersion == null)
			throw new RestApiException('No api version specified.', RestErrorType.invalidApiVersion);
		if(data == null)
			throw new RestApiException('No extra data specified.', RestErrorType.invalidData);
		
		this.type = type;
		this.selectors = selectors;
		this.format = format;
		this.apiVersion = apiVersion;
		this.data = data;
	}
	
	public function toString() : String
	{
		return 'RestApiRequest(' + type + selectors + ' ' + data + ' => ' + format + ')';
	}
}