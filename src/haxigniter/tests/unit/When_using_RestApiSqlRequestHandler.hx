package haxigniter.tests.unit;

import haxe.Serializer;
import haxe.Unserializer;
import haxigniter.restapi.RestApiSqlRequestHandler;
import haxigniter.controllers.RestApiController;

import haxigniter.restapi.RestApiResponse;

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

	///// Read /////
	
	public function test_Then_read_requests_should_create_proper_sql_for_single_resources()
	{
		this.request('/bazaars');
		this.assertQueries(['SELECT bazaars.* FROM bazaars']);

		this.request('/bazaars/3');
		this.assertQueries(['SELECT bazaars.* FROM bazaars WHERE bazaars.id = Q*3*Q']); // The funny Q* syntax is the mock database quoting.

		this.request('/bazaars/[name^=test][email$=google.com]:range(1,10)');
		this.assertQueries([
			'SELECT bazaars.* FROM bazaars WHERE bazaars.name LIKE Q*test%*Q AND bazaars.email LIKE Q*%google.com*Q LIMIT 1,9',
			'SELECT COUNT(*) FROM bazaars WHERE bazaars.name LIKE Q*test%*Q AND bazaars.email LIKE Q*%google.com*Q'
			]);

		this.request('/bazaars/:order(name)');
		this.assertQueries(['SELECT bazaars.* FROM bazaars ORDER BY name']);

		this.request('/bazaars/:order(name,desc,id,asc,email)');
		this.assertQueries(['SELECT bazaars.* FROM bazaars ORDER BY name DESC, id ASC, email']);

		this.request('/bazaars/:random');
		this.assertQueries(['SELECT bazaars.* FROM bazaars ORDER BY RAND()']);
	}

	public function test_Then_read_requests_should_create_proper_sql_for_multiple_resources()
	{
		this.request('/bazaars/4/libraries');
		this.assertQueries(['SELECT libraries.* FROM libraries INNER JOIN bazaars ON (bazaars.id = libraries.bazaarId AND bazaars.id = Q*4*Q)']);

		this.request('/bazaars/4/libraries/:range(20,50)');
		this.assertQueries([
			'SELECT libraries.* FROM libraries INNER JOIN bazaars ON (bazaars.id = libraries.bazaarId AND bazaars.id = Q*4*Q) LIMIT 20,30',
			'SELECT COUNT(*) FROM libraries INNER JOIN bazaars ON (bazaars.id = libraries.bazaarId AND bazaars.id = Q*4*Q)'
			]);

		this.request('/bazaars/[name=BigOne]/libraries/55');
		this.assertQueries(['SELECT libraries.* FROM libraries INNER JOIN bazaars ON (bazaars.id = libraries.bazaarId AND bazaars.name = Q*BigOne*Q) WHERE libraries.id = Q*55*Q']);

		this.request('/bazaars/[name=BigOne]/libraries/[id=1]:order(firstname,asc,lastname,desc)');
		this.assertQueries(['SELECT libraries.* FROM libraries INNER JOIN bazaars ON (bazaars.id = libraries.bazaarId AND bazaars.name = Q*BigOne*Q) WHERE libraries.id = Q*1*Q ORDER BY firstname ASC, lastname DESC']);

		this.request('/bazaars/1/libraries/3/news/5');
		this.assertQueries(['SELECT news.* FROM news INNER JOIN libraries ON (libraries.id = news.libraryId AND libraries.id = Q*3*Q) INNER JOIN bazaars ON (bazaars.id = libraries.bazaarId AND bazaars.id = Q*1*Q) WHERE news.id = Q*5*Q']);
	}
	
	///// Create, update, delete /////

	public function test_Then_create_requests_should_create_proper_sql()
	{
		// Very hard to unit test this without mock objects. It has to stay like this until further.
		this.request('/bazaars/4/libraries', 'POST', 'firstname=Boris&lastname=Doris');		
		this.assertQueries([
			'SELECT bazaars.id FROM bazaars WHERE bazaars.id = Q*4*Q'
			//, 'INSERT...'
			]);
	}

	public function test_Then_update_requests_should_create_proper_sql()
	{
		// Very hard to unit test this without mock objects. It has to stay like this until further.
		this.request('/bazaars/10/libraries', 'PUT', 'firstname=Boris&lastname=Doris');		
		this.assertQueries([
			'SELECT libraries.id FROM libraries INNER JOIN bazaars ON (bazaars.id = libraries.bazaarId AND bazaars.id = Q*10*Q)'
			//, 'UPDATE libraries SET lastname=Q*Doris*Q, firstname=Q*Boris*Q WHERE libraries.id IN()'
			]);
	}

	public function test_Then_delete_requests_should_create_proper_sql()
	{
		// Very hard to unit test this without mock objects. It has to stay like this until further.
		this.request('/bazaars/15/libraries/20', 'DELETE');
		this.assertQueries([
			'SELECT libraries.id FROM libraries INNER JOIN bazaars ON (bazaars.id = libraries.bazaarId AND bazaars.id = Q*15*Q) WHERE libraries.id = Q*20*Q'
			//, 'DELETE FROM libraries WHERE libraries.id IN()'
			]);
	}

	
	private function assertQueries(queries : Array<String>)
	{
		//trace(this.db.queries);
		
		this.assertEqual(queries.length, this.db.queries.length);
		
		for(i in 0 ... queries.length)
		{
			this.assertEqual(StringTools.trim(StringTools.replace(queries[i], '  ', ' ')), StringTools.trim(StringTools.replace(this.db.queries[i], '  ', ' ')));
		}
	}
	
	private function request(query : String, ?type = 'GET', ?rawRequestData : String) : Void
	{
		this.db.queries.splice(0, this.db.queries.length);		
		this.controller.handleRequest(['api', 'v1'], type, new Hash<String>(), query, rawRequestData);
	}
}