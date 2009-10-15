package haxigniter.restapi;

import haxigniter.exceptions.RestApiException;
import haxigniter.restapi.RestApiResponse;

enum RestApiSelectorOperator
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

enum RestApiSelector
{
    func (name : String, args : Array<String>);
    attribute (name : String, operator : RestApiSelectorOperator, value : String);
}
	
enum RestApiResource
{
	one(resourceName : String, id : Int);
    all(resourceName : String);
    some(resourceName : String, selectors : Array<RestApiSelector>);
    view(resourceName : String, viewName : String);
}

typedef RestApiFormat = String;

enum RestApiRequestType
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
	var supportedOutputFormats(default, null) : Array<RestApiFormat>;
	
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
	function outputApiResponse(response : RestApiResponse, outputFormat : RestApiFormat) : RestResponseOutput;
}

/////////////////////////////////////////////////////////////////////

class RestApiRequest
{
	public var type(default, null) : RestApiRequestType;
    public var resources(default, null) : Array<RestApiResource>;
    public var format(default, null) : RestApiFormat;
    public var apiVersion(default, null) : Int;
	public var queryParameters(default, null) : Hash<String>;
    public var data(default, null) : String; // Any extra data for create/update

	public function new(type : RestApiRequestType, resources : Array<RestApiResource>, format : RestApiFormat, apiVersion : Int, queryParameters : Hash<String>, data : String)
	{
		if(type == null)
			throw new RestApiException('No request type specified.', RestErrorType.invalidRequestType);
		if(resources == null)
			throw new RestApiException('No selectors in request.', RestErrorType.invalidQuery);
		if(apiVersion == null)
			throw new RestApiException('No api version specified.', RestErrorType.invalidApiVersion);
		
		this.type = type;
		this.resources = resources;
		this.format = format;
		this.apiVersion = apiVersion;
		
		this.queryParameters = queryParameters;
		this.data = data;
	}
	
	public function toString() : String
	{
		var output = 'RestApiRequest(' + type + ': ';
		var resourceOutput = [];
		
		for(resource in resources)
		{
			switch(resource)
			{
				case one(name, id):
					resourceOutput.push('one("' + name + '": ' + id + ')');
				case all(name):
					resourceOutput.push('all("' + name + '")');
				case view(name, viewName):
					resourceOutput.push('view("' + name + '": "' + viewName + '")');
				case some(resourceName, query):
					var selectors = [];
					for(selector in query)
					{
						selectors.push(Std.string(selector));
					}
					resourceOutput.push('some("' + resourceName + '": ' + selectors.join(', ') + ')');
			}
		}
		
		output += resourceOutput.join(', ');
		output += ' ' + queryParameters + ' [' + data + '] => ' + format + ')';
		
		return output;
	}
}