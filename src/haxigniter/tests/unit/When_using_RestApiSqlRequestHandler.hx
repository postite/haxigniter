package haxigniter.tests.unit;

import haxigniter.restapi.RestApiSqlRequestHandler;
import haxigniter.controllers.RestApiController;

import haxigniter.tests.unit.MockDatabaseConnection;

class When_using_RestApiSqlRequestHandler extends haxigniter.tests.TestCase
{
	var controller : RestApiController;
	var handler : RestApiSqlRequestHandler;
	var db : MockDatabaseConnection;
	
	public override function setup()
	{
		this.db = new MockDatabaseConnection();
		this.handler = new RestApiSqlRequestHandler(this.db);
		
		this.controller = new RestApiController(this.handler);
		this.controller.noOutput = true;
	}
	
	public override function tearDown()
	{
	}
	
	public function test_Then_read_requests_should_create_proper_sql()
	{
		this.request('/bazaars');
		this.assertQueries(['SELECT bazaars.* FROM bazaars']);

		this.request('/bazaars/3');
		this.assertQueries(['SELECT bazaars.* FROM bazaars WHERE bazaars.id = Q*3*Q']); // The funny Q* syntax is the mock database quoting.

		//this.request('/bazaars/[name^=test][email$=google.com]');
		//this.assertQueries(['SELECT bazaars.* FROM bazaars WHERE bazaars.name LIKE Q*test%*Q AND email LIKE Q*%google.com*Q']);
	}
	
	private function assertQueries(queries : Array<String>)
	{
		this.assertEqual(queries.length, this.db.queries.length);
		
		for(i in 0 ... queries.length)
		{
			this.assertEqual(StringTools.trim(StringTools.replace(queries[i], '  ', ' ')), StringTools.trim(StringTools.replace(this.db.queries[i], '  ', ' ')));
		}
	}
	
	private function request(query : String, type = 'GET')
	{
		this.db.queries.splice(0, this.db.queries.length);
		this.controller.handleRequest(['api', 'v1'], type, new Hash<String>(), query);
	}
}