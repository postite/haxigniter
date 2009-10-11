package haxigniter.restapi;

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

enum RestApiFormat 
{
    haXigniter;
    json;
    xml;
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
    public var format(default, null) : RestApiFormat;
    public var apiVersion(default, null) : Int;
    public var data(default, null) : Dynamic; // Any PUT or POST data for create/update

	public function new() 
	{
		
	}	
}