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

interface RestApiRequestHandler
{
	/**
	 * Array of supported formats. If none is specified in the request, first one on this list is used.
	 */ 
	var supportedOutputFormats(default, null) : Array<String>;
	
	/**
	 * Handle an incoming request.
	 * @param	request
	 * @return
	 */
	function handleApiRequest(request : RestApiRequest) : RestApiResponse;

	/**
	 * Format a response according to an output format.
	 * @param	request
	 * @param	outputFormat is guaranteed (from the RestApiController) to be in the supportedOutputFormat array.
	 * @return
	 */
	function outputApiResponse(request : RestApiResponse, outputFormat : String) : RestResponseOutput;
}

/////////////////////////////////////////////////////////////////////

class RestApiRequest
{
	public var type(default, null) : RestRequestType;
    public var selectors(default, null) : Array<RestApiSelector>;
    public var format(default, null) : String;
    public var apiVersion(default, null) : Int;
    public var data(default, null) : String; // Any extra data for create/update

	public function new(type : RestRequestType, selectors : Array<RestApiSelector>, format : String, apiVersion : Int, ?data : String)
	{
		if(type == null)
			throw new RestApiException('No request type specified.', RestErrorType.invalidRequestType);
		if(selectors == null)
			throw new RestApiException('No selectors in request.', RestErrorType.invalidQuery);
		if(apiVersion == null)
			throw new RestApiException('No api version specified.', RestErrorType.invalidApiVersion);
		
		this.type = type;
		this.selectors = selectors;
		this.format = format;
		this.apiVersion = apiVersion;
		this.data = data;
	}
	
	public function toString() : String
	{
		return 'RestApiRequest(' + type + selectors + ' [' + data + '] => ' + format + ')';
	}
}