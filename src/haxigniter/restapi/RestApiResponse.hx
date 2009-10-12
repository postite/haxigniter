package haxigniter.restapi;

enum RestErrorType 
{
	invalidRequestType;
    invalidResource;
    invalidQuery;
	invalidApiVersion;
	invalidOutputFormat;
	invalidData;

	unknownError;
}

typedef RestResponseOutput = {
	var contentType : String;
	var charSet : String;
	var output : String;
}

typedef RestDataCollection = {
	var startIndex : Int;
	var endIndex : Int;
	var totalCount : Int;
	var data : List<Dynamic>;
}

/////////////////////////////////////////////////////////////////////

enum RestApiResponse 
{
    one(type : String, data : Dynamic);
    many(type : String, data : RestDataCollection);
    error(message : String, type : RestErrorType);
}
