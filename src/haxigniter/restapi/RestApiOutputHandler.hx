package haxigniter.restapi;

import haxigniter.restapi.RestApiResponse;

typedef RestApiFormat = String;

typedef RestResponseOutput = {
	var contentType : String;
	var charSet : String;
	var output : String;
}

interface RestApiOutputHandler
{
	/**
	 * Array of supported formats. If none is specified in the request, first one on this list is used.
	 */ 
	var outputFormats(default, null) : Array<RestApiFormat>;
	
	/**
	 * Format a response according to an output format.
	 * @param	request
	 * @param	outputFormat must be in the supportedOutputFormat array.
	 * @return
	 */
	function outputApiResponse(response : RestApiResponse, outputFormat : RestApiFormat) : RestResponseOutput;
}
