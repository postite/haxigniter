package haxigniter.tests.unit;

import Type;
import haxigniter.common.types.TypeFactory;
import haxigniter.tests.TestCase;

import haxigniter.server.request.RestApiHandler;
import haxigniter.server.request.RequestHandler;
import haxigniter.server.Controller;

import haxigniter.common.restapi.RestApiInterface;
import haxigniter.common.restapi.RestApiResponse;
import haxigniter.server.restapi.RestApiSecurityHandler;
import haxigniter.server.restapi.RestApiFormatHandler;
import haxigniter.server.restapi.RestApiRequest;
import haxigniter.server.restapi.RestApiRequestHandler;

import haxigniter.libraries.Request;

class SecurityMock implements RestApiSecurityHandler
{
	public function new() {}
	
	public function install(api : RestApiInterface) : Void
	{
	}
	
	public function create(resourceName : String, data : Dynamic, ?parentResource : String, ?parentId : Int, ?parameters : Hash<String>) : Void
	{
	}
	
	public function read(resourceName : String, data : RestDataCollection, ?parameters : Hash<String>) : Void
	{
	}
	
	public function update(resourceName : String, ids : List<Int>, data : Dynamic, ?parameters : Hash<String>) : Void
	{
	}
	
	public function delete(resourceName : String, ids : List<Int>, ?parameters : Hash<String>) : Void
	{
	}
}

class TestRestApi implements Controller, implements RestApiRequestHandler
{
	public var lastRequest : RestApiRequest;
	public var requestHandler : RequestHandler;
	
	public function new()
	{
		
	}
	
	///// Interface implementation //////////////////////////////////
	
	public function handleApiRequest(request : RestApiRequest, security : RestApiSecurityHandler) : RestApiResponse
	{
		this.lastRequest = request;
		return RestApiResponse.success([]);
	}

	public function restApiOutput(response : RestApiResponse, outputFormat : RestApiFormat) : RestResponseOutput
	{
		switch(response)
		{
			case success(rows):
				if(rows.length != 0) throw response;
			default:
				throw response;
		}
		
		return {
			contentType: 'mock1',
			charSet: 'mock2',
			output: 'mock3'
		}
	}
}

class When_using_RestApiController extends haxigniter.tests.TestCase
{
	private var api : TestRestApi;
	private var requestHandler : RestApiHandler;
	
	private var request : Request;

	private var r : Array<RestApiResource>;
	
	public override function setup()
	{
		var config = new MockConfig();
		config.controllerPackage = 'haxigniter.tests.unit';

		this.api = new TestRestApi();
		this.request = new Request(config);		

		this.requestHandler = new RestApiHandler(new SecurityMock(), this.api);
		this.requestHandler.noOutput = true;
	}
	
	public override function tearDown()
	{
	}
	
	public function test_Then_a_request_should_handle_the_basic_data()
	{
		this.requestHandler.handleRequest(this.api, '/api/v1', 'GET', new Hash<String>(), '/bazaars', null);
		
		this.assertEqual(1, api.lastRequest.apiVersion);
		
		this.assertEqual('{}', Std.string(api.lastRequest.queryParameters));
		this.assertEqual(1, api.lastRequest.resources.length);
		this.assertEqual(RestApiRequestType.read, api.lastRequest.type);
	}

	public function test_Then_a_request_should_handle_not_so_basic_data()
	{
		this.requestHandler.handleRequest(this.api, '/couldBeAnything/v23', 'DELETE', new Hash<String>(), '/what/3/is/[this^=stuff]/', null);
		
		this.assertEqual(23, api.lastRequest.apiVersion);
		
		this.assertEqual('{}', Std.string(api.lastRequest.queryParameters));
		this.assertEqual(2, api.lastRequest.resources.length);
		this.assertEqual(RestApiRequestType.delete, api.lastRequest.type);		
	}

	public function test_Then_a_request_should_generate_valid_resources()
	{
		r = requestResource('/bazaars');
		this.assertEqual(1, r.length);
		this.assertResource('bazaars', '', r[0]);

		r = requestResource('/bazaars//');
		this.assertEqual(1, r.length);
		this.assertResource('bazaars', '', r[0]);

		r = requestResource('/bazaar2/12');		
		this.assertEqual(1, r.length);
		this.assertResource('bazaar2', 'attribute(id,equals,12)', r[0]);
		
		r = requestResource('/bazaars/3/libraries/');
		this.assertEqual(2, r.length);
		this.assertResource('bazaars', 'attribute(id,equals,3)', r[0]);
		this.assertResource('libraries', '', r[1]);

		r = requestResource('/bazaars/[field^=123][field2*="test"]/');
		this.assertEqual(1, r.length);
		this.assertResource('bazaars', 'attribute(field,startsWith,123),attribute(field2,contains,test)', r[0]);
		
		r = requestResource('/bazaars/[id<20]:range(0,10)/');
		this.assertEqual(1, r.length);
		this.assertResource('bazaars', 'attribute(id,lessThan,20),func(range[0,10])', r[0]);

		r = requestResource('/bazaars/:range(10,20)/');
		this.assertEqual(1, r.length);
		this.assertResource('bazaars', 'func(range[10,20])', r[0]);
	}
	
	private function assertResource(name : String, selectorDump : String, resource : RestApiResource)
	{
		this.assertEqual(name, resource.name);
		this.assertEqual(selectorDump, selectorsToString(resource.selectors));
	}
	
	// PHP cannot dump data like Neko, so this is needed.
	private function selectorsToString(selectors : Array<RestApiSelector>) : String
	{
		var output = [];
		for(s in selectors)
		{
			switch(s)
			{
				case func(name, args):
					output.push('func(' + name + '[' + args.join(',') + '])');
				
				case attribute(name, operator, value):
					output.push('attribute(' + name + ',' + operator + ',' + value + ')');
			}
		}
		
		return output.join(',');
	}
	
	private function requestResource(query : String, method = 'GET') : Array<RestApiResource>
	{
		this.api.lastRequest = null;
		var response = this.requestHandler.handleRequest(this.api, '/api/v1', method, new Hash<String>(), query, null);
		
		if(this.api.lastRequest == null)
			trace(response);
		
		return this.api.lastRequest.resources;
	}
}