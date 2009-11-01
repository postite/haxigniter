package haxigniter.restapi;

import haxigniter.restapi.RestApiResponse;

typedef RestApiFormat = String;

typedef RestResponseOutput = {
	var contentType : String;
	var charSet : String;
	var output : String;
}

interface RestApiFormatHandler
{
	/**
	 * Array of supported formats. If none is specified in the request, first one on this list is used.
	 */ 
	var restApiFormats(default, null) : Array<RestApiFormat>;

	/**
	 * Format a response according to an output format.
	 * @param	request
	 * @param	outputFormat must be in the supportedOutputFormat array.
	 * @return
	 */
	function restApiInput(data : String, inputFormat : RestApiFormat) : Dynamic;

	/**
	 * Format a response according to an output format.
	 * @param	request
	 * @param	outputFormat must be in the supportedOutputFormat array.
	 * @return
	 */
	function restApiOutput(response : RestApiResponse, outputFormat : RestApiFormat) : RestResponseOutput;
}
