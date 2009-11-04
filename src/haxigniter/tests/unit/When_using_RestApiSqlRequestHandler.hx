﻿package haxigniter.tests.unit;

import haxe.Serializer;
import haxe.Unserializer;
import haxigniter.controllers.RestApiController;

import haxigniter.restapi.RestApiSqlRequestHandler;
import haxigniter.restapi.RestApiFormatHandler;
import haxigniter.restapi.RestApiRequest;
import haxigniter.restapi.RestApiResponse;

import haxigniter.tests.unit.MockDatabaseConnection;

class TestRestCreate
{
	var firstname : String;
	var lastname : String;
	
	public function new(firstname : String, lastname : String)
	{
		this.firstname = firstname;
		this.lastname = lastname;
	}
}

class TestController extends RestApiController
{
	public var acceptFailure : String;
	
	public override function restApiOutput(response : RestApiResponse, outputFormat : RestApiFormat) : RestResponseOutput
	{
		switch(response)
		{
			case failure(message, errorType):
				if(message != acceptFailure)
					throw response;
			
			default:
		}
		
		return super.restApiOutput(response, outputFormat);
	}
}

class When_using_RestApiSqlRequestHandler extends haxigniter.tests.TestCase
{
	var controller : TestController;
	var handler : RestApiSqlRequestHandler;
	var db : MockDatabaseConnection;
	
	public override function setup()
	{
		this.db = new MockDatabaseConnection();
		this.handler = new RestApiSqlRequestHandler(this.db);
		
		this.controller = new TestController(this.handler);
		this.controller.noOutput = true;
	}
	
	public override function tearDown()
	{
	}

	///// Read /////
	public function test_Then_read_requests_should_create_proper_sql_for_single_resources()
	{
		// Set mock result to avoid request failures
		// Needs to be an int for COUNT(*)
		this.db.setMockResults([1]);
		
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

		this.request('/bazaars/:eq(5)');
		this.assertQueries([
			'SELECT bazaars.* FROM bazaars LIMIT 5,1', 
			'SELECT COUNT(*) FROM bazaars'
			]);

		this.request('/bazaars/:lt(4)');
		this.assertQueries([
			'SELECT bazaars.* FROM bazaars LIMIT 4',
			'SELECT COUNT(*) FROM bazaars'
			]);

		this.request('/bazaars/:gt(10)');
		this.assertQueries([
			'SELECT bazaars.* FROM bazaars LIMIT 10,999999999',
			'SELECT COUNT(*) FROM bazaars'
			]);
	}

	public function test_Then_read_requests_should_create_proper_sql_for_multiple_resources()
	{
		// Set mock result to avoid request failures
		// Needs to be an int for COUNT(*)
		this.db.setMockResults([1]);

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

	public function test_Then_requests_should_detect_joins_automatically()
	{
		// Set mock result to avoid request failures
		// Needs to be an int for COUNT(*)
		this.db.setMockResults([1]);
		this.controller.acceptFailure = 'No valid relations found for query.';
		
		this.db.simulateError('No join found.');

		this.request('/bazaars/4/libraries/8/news');
		
		// When a join fails, the request handler will juggle the joins around, hoping to find a valid one.
		var expected = [
			'SELECT news.* FROM news INNER JOIN libraries ON (libraries.id = news.libraryId AND libraries.id = Q*8*Q) INNER JOIN bazaars ON (bazaars.id = libraries.bazaarId AND bazaars.id = Q*4*Q)',
			'SELECT news.* FROM news INNER JOIN libraries ON (libraries.newsId = news.id AND libraries.id = Q*8*Q) INNER JOIN bazaars ON (bazaars.id = libraries.bazaarId AND bazaars.id = Q*4*Q)',
			'SELECT news.* FROM news INNER JOIN libraries ON (libraries.id = news.libraryId AND libraries.id = Q*8*Q) INNER JOIN bazaars ON (bazaars.libraryId = libraries.id AND bazaars.id = Q*4*Q)',
			'SELECT news.* FROM news INNER JOIN libraries ON (libraries.newsId = news.id AND libraries.id = Q*8*Q) INNER JOIN bazaars ON (bazaars.libraryId = libraries.id AND bazaars.id = Q*4*Q)',
			'SELECT news.* FROM news INNER JOIN libraries ON (libraries.id = news.libraryId AND libraries.id = Q*8*Q) INNER JOIN bazaars ON (bazaars.id = libraries.bazaarId AND bazaars.id = Q*4*Q)'
			];
		// (The last one will not be executed)
			
		this.assertEqual(expected.length, this.db.queries.length);

		for(i in 0 ... this.db.queries.length)
			this.assertEqual(expected[i], StringTools.trim(this.db.queries[i]));
	}

	
	///// Create, update, delete /////
	public function test_Then_create_requests_should_create_proper_sql_for_anonymous_objects()
	{
		// Also testing serialized objects and anonymous object here.
		var anon = { firstname: 'Boris', lastname: 'Doris' };		
		
		// Database should return the id of the bazaar.
		this.db.setMockResults([4]);
		
		this.request('/bazaars/4/libraries', 'POST', haxe.Serializer.run(anon));
		this.assertQueries([
			'SELECT bazaars.id FROM bazaars WHERE bazaars.id = Q*4*Q',
			#if neko
			'INSERT INTO libraries (lastname, firstname, bazaarId) VALUES (Q*Doris*Q, Q*Boris*Q, Q*4*Q)'
			#elseif php
			'INSERT INTO libraries (firstname, lastname, bazaarId) VALUES (Q*Boris*Q, Q*Doris*Q, Q*4*Q)'
			#end
			]);
	}

	public function test_Then_create_requests_should_create_proper_sql_for_objects()
	{
		var object = new TestRestCreate('Boris', 'Doris');
		
		this.db.setMockResults([1,2,3]);
		
		this.request('/bazaars/4/libraries/[id<4]/news', 'POST', haxe.Serializer.run(object));
		this.assertQueries([
			'SELECT libraries.id FROM libraries INNER JOIN bazaars ON (bazaars.id = libraries.bazaarId AND bazaars.id = Q*4*Q) WHERE libraries.id < Q*4*Q',
			#if neko
			'INSERT INTO news (lastname, libraryId, firstname) VALUES (Q*Doris*Q, Q*1*Q, Q*Boris*Q)',
			'INSERT INTO news (lastname, libraryId, firstname) VALUES (Q*Doris*Q, Q*2*Q, Q*Boris*Q)',
			'INSERT INTO news (lastname, libraryId, firstname) VALUES (Q*Doris*Q, Q*3*Q, Q*Boris*Q)'
			#elseif php
			'INSERT INTO news (firstname, lastname, libraryId) VALUES (Q*Boris*Q, Q*Doris*Q, Q*1*Q)',
			'INSERT INTO news (firstname, lastname, libraryId) VALUES (Q*Boris*Q, Q*Doris*Q, Q*2*Q)',
			'INSERT INTO news (firstname, lastname, libraryId) VALUES (Q*Boris*Q, Q*Doris*Q, Q*3*Q)'
			#end
			]);
	}

	public function test_Then_create_requests_with_single_resource_should_not_look_for_foreign_keys()
	{
		var object = new TestRestCreate('123', '456');
		
		this.request('/bazaars/', 'POST', haxe.Serializer.run(object));
		this.assertQueries([
			#if neko
			'INSERT INTO bazaars (lastname, firstname) VALUES (Q*456*Q, Q*123*Q)'
			#elseif php
			'INSERT INTO bazaars (firstname, lastname) VALUES (Q*123*Q, Q*456*Q)'
			#end
			]);
	}
	
	public function test_Then_update_requests_should_create_proper_sql()
	{
		// Also testing serialized Hash here.
		var hash = haxigniter.libraries.Input.parseQuery('firstname=Boris&lastname=Doris');
		
		this.db.setMockResults([9,8,7]);
		
		this.request('/bazaars/10/libraries', 'PUT', haxe.Serializer.run(hash));
		this.assertQueries([
			'SELECT libraries.id FROM libraries INNER JOIN bazaars ON (bazaars.id = libraries.bazaarId AND bazaars.id = Q*10*Q)',
			#if neko
			'UPDATE libraries SET lastname=Q*Doris*Q, firstname=Q*Boris*Q WHERE libraries.id IN(9,8,7)'
			#elseif php
			'UPDATE libraries SET firstname=Q*Boris*Q, lastname=Q*Doris*Q WHERE libraries.id IN(9,8,7)'
			#end
			]);
	}

	public function test_Then_delete_requests_should_create_proper_sql()
	{
		this.db.setMockResults([123,456]);
		
		this.request('/bazaars/15/libraries/[anything=goes]', 'DELETE');
		this.assertQueries([
			'SELECT libraries.id FROM libraries INNER JOIN bazaars ON (bazaars.id = libraries.bazaarId AND bazaars.id = Q*15*Q) WHERE libraries.anything = Q*goes*Q',
			'DELETE FROM libraries WHERE libraries.id IN(123,456)'
			]);
	}
	
	private function assertQueries(queries : Array<Dynamic>)
	{
		this.assertEqual(queries.length, this.db.queries.length);
		
		for(i in 0 ... queries.length)
		{
			var currentQuery = StringTools.trim(StringTools.replace(this.db.queries[i], '  ', ' '));
			
			if(Std.is(queries[i], String))
				this.assertEqual(StringTools.trim(StringTools.replace(queries[i], '  ', ' ')), currentQuery);
			else
				this.assertPattern(queries[i], currentQuery);
		}
	}
	
	private function request(query : String, ?type = 'GET', ?rawRequestData : String) : Void
	{
		this.db.queries.splice(0, this.db.queries.length);
		this.controller.handleRequest(['api', 'v1'], type, new Hash<String>(), query, rawRequestData);
	}
}