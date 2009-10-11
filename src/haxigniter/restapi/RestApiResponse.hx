package haxigniter.restapi;

enum RestErrorType 
{
    invalidResource;
    invalidId;
    invalidQuery;
    // etc...
}

/////////////////////////////////////////////////////////////////////

enum RestApiResponse 
{
    one(type : String, data : Dynamic);
    many(type : String, data : List<Dynamic>);
    error(type : RestErrorType, message : String);
}
