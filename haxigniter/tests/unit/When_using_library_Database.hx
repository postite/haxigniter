package haxigniter.tests.unit;

import haxigniter.tests.unit.MockDatabaseConnection;

class When_using_library_Database extends haxigniter.tests.TestCase
{
	private var db : MockDatabaseConnection;
	
	public override function setup()
	{
		db = new MockDatabaseConnection();
	}
	
	public function test_Then_dynamic_objects_should_be_iterated()
	{
		var data1 = { me: 'who', data: 'you' };
		
		var data2 = new Hash<Dynamic>();
		data2.set('who', 'me');
		data2.set('you', 1337);
		
		// Simple test of the mock object
		this.assertEqual(0, db.queries.length);

		db.insert('test', data1);
		this.assertEqual('INSERT INTO test (me, data) VALUES (Q*who*Q, Q*you*Q)', db.lastQuery);
		
		db.insert('test', data2);
		this.assertEqual('INSERT INTO test (who, you) VALUES (Q*me*Q, Q*1337*Q)', db.lastQuery);
		
		db.update('test', data1, data2, 5);
		this.assertEqual('UPDATE test SET me=Q*who*Q, data=Q*you*Q WHERE who=Q*me*Q AND you=Q*1337*Q LIMIT 5', db.lastQuery);

		db.delete('test', data1, 1);
		this.assertEqual('DELETE FROM test WHERE me=Q*who*Q AND data=Q*you*Q LIMIT 1', db.lastQuery);	
		
		// Simple test of the mock object
		this.assertEqual(4, db.queries.length);
		this.assertEqual('INSERT INTO test (me, data) VALUES (Q*who*Q, Q*you*Q)', db.queries[0]);
		this.assertEqual('DELETE FROM test WHERE me=Q*who*Q AND data=Q*you*Q LIMIT 1', db.queries[3]);
	}
}
