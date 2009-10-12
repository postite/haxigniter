package haxigniter.restapi;

enum RestErrorType 
{
	invalidRequestType;
    invalidResource;
    invalidQuery;
	invalidApiVersion;
	invalidOutputFormat;
	invalidData;

	internal;
}

typedef RestResponseOutput = {
	var contentType : String;
	var charSet : String;
	var output : String;
}

class RestDataCollection
{
	public var startIndex(default, null) : Int;
	public var endIndex(default, null) : Int;
	public var totalCount(default, null) : Int;
	public var data : Array<Dynamic>;
	
	public function new(startIndex : Int, endIndex : Int, totalCount : Int, data : Array<Dynamic>)
	{
		if(startIndex == null || startIndex < 0)
			throw '[RestDataCollection] Invalid startIndex: ' + startIndex;

		if(endIndex == null || endIndex < 0)
			throw '[RestDataCollection] Invalid endIndex: ' + endIndex;

		if(totalCount == null || totalCount < 0)
			throw '[RestDataCollection] Invalid totalCount: ' + totalCount;

		if(data == null)
			throw '[RestDataCollection] Data is null.';

		this.startIndex = startIndex;
		this.endIndex = endIndex;
		this.totalCount = totalCount;
		this.data = data;
	}
}

/////////////////////////////////////////////////////////////////////

enum RestApiResponse 
{
	success(ids : Array<Int>);
	successData(collection : RestDataCollection);
	failure(message : String, errorType : RestErrorType);
}
