package haxigniter.tests.unit;

import haxigniter.exceptions.RestApiException;
import haxigniter.restapi.RestApiConfigSecurityHandler;

import haxigniter.restapi.RestApiInterface;
import haxigniter.restapi.RestApiResponse;

class MockApiInterface implements RestApiInterface
{
	public var requests : Array<String -> RestApiResponse>;
	private var count : Int;

	public function new()
	{
		requests = new Array<String -> RestApiResponse>();
		count = 0;
	}
	
	public function create(url : String, data : Dynamic, callBack : RestApiResponse -> Void) : Void
	{
		throw 'Not needed.';
	}
	
	public function read(url : String, callBack : RestApiResponse -> Void) : Void
	{
		if(count > requests.length)
			throw 'Expected only ' + count + ' requests for MockApiInterface.';
		
		callBack(this.requests[count++](url));		
	}
	
	public function update(url : String, data : Dynamic, callBack : RestApiResponse -> Void) : Void
	{
		throw 'Not needed.';
	}
	
	public function delete(url : String, callBack : RestApiResponse -> Void) : Void
	{
		throw 'Not needed.';
	}
}

/**
* This is fun, unit testing a unit test class.
*/
class When_using_RestApiConfigSecurityHandler extends haxigniter.tests.TestCase
{
	private var api : MockApiInterface;
	private var parameters : Hash<String>;
	private var security : RestApiConfigSecurityHandler;
	private var rights : SecurityRights;
	private var ownerships : Ownerships;
	
	public override function setup()
	{
		var self = this;

		this.rights = new SecurityRights();
		this.ownerships = new Ownerships();

		this.api = new MockApiInterface();
		this.api.requests[0] = function(url : String) : RestApiResponse
		{
			self.assertEqual('/?/USERS/[USER="User"][PASS="Pass\\"word"]', url);
			return RestApiResponse.successData(new RestDataCollection(0, 0, 1, [{id: 123, isAdmin: 0}]));
		}

		parameters = new Hash<String>();
		parameters.set('username', 'User');
		parameters.set('password', 'Pass"word');

		security = new RestApiConfigSecurityHandler(rights, ownerships);
		
		security.userNameField = 'USER';
		security.userPasswordField = 'PASS';
		security.userResource = 'USERS';
		
		security.userIsAdminField = 'isAdmin';
		security.userIsAdminValue = 1;
		
		security.install(this.api);
	}
	
	public override function tearDown()
	{
		
	}
	
	private function setRights(rights : SecurityRights)
	{
		Reflect.setField(security, 'rights', rights);
	}

	private function setOwnerships(ownerships : Ownerships)
	{
		Reflect.setField(security, 'ownerships', ownerships);
	}

	public function test_Then_callbacks_must_have_valid_names()
	{
		try
		{
			new RestApiConfigSecurityHandler(null, null, { totalBogusName: null } );
		}
		catch(e : RestApiException)
		{
			this.assertPattern(~/Invalid callback name: totalBogusName$/, e.message);
		}
		
		new RestApiConfigSecurityHandler(null, null, { adminCreateTablename: null } );
	}
	
	public function test_Then_resource_must_exist_in_access_object()
	{
		try
		{
			security.create('testResource', null);
		}
		catch(e : RestApiException)
		{
			this.assertPattern(~/No rights found for resource: testResource$/, e.message);
		}

		try
		{
			security.read('testResource', null);
		}
		catch(e : RestApiException)
		{
			this.assertPattern(~/No rights found for resource: testResource$/, e.message);
		}

		try
		{
			security.update('testResource', null, null);
		}
		catch(e : RestApiException)
		{
			this.assertPattern(~/No rights found for resource: testResource$/, e.message);
		}

		try
		{
			security.delete('testResource', null);
		}
		catch(e : RestApiException)
		{
			this.assertPattern(~/No rights found for resource: testResource$/, e.message);
		}

		// Set one right and test if it passes through now.
		rights.set('testAgain', null);
		
		try
		{
			security.create('testAgain', null);
		}
		catch(e : String)
		{
			// The access fields for the
			this.assertPattern(~/^Invalid field access : guest$/, e);
		}
	}

	public function test_Then_write_requests_fails_if_no_data()
	{
		rights.set('testResource', {guest: {create: 'ALL', read: 'ALL', update: 'ALL', delete: 'ALL'}, owner: null, admin: null});
		
		try
		{
			security.create('testResource', null);
		}
		catch(e : RestApiException)
		{
			this.assertPattern(~/No request data found!$/, e.message);
		}
	}

	public function test_Then_write_requests_fails_if_id_exists_for_ALL_rights()
	{
		rights.set('testResource', {guest: {create: 'ALL', read: 'ALL', update: 'ALL', delete: 'ALL'}, owner: null, admin: null});
		
		try
		{
			security.create('testResource', {id: 123, name: 'Boris'});
		}
		catch(e : RestApiException)
		{
			this.assertPattern(~/Field "id" cannot be modified.$/, e.message);
		}
	}

	public function test_Then_no_access_if_login_fails()
	{
		rights.set('testResource', { guest: null, owner: null, admin: null } );
		
		// Failed to find a valid user.
		this.api.requests[0] = function(url : String) : RestApiResponse
		{
			return RestApiResponse.successData(new RestDataCollection(0, 0, 0, []));
		}
		
		try
		{
			security.create('testResource', null, parameters);
		}
		catch(e : RestApiException)
		{
			this.assertPattern(~/^Invalid username or password.$/, e.message);
		}		
	}
	
	public function test_Then_guest_has_access_if_specified()
	{
		rights.set('testResource', {guest: {create: 'ALL', read: 'ALL', update: 'ALL', delete: 'ALL'}, owner: null, admin: null});
		
		security.create('testResource', {});
		//security.read('testResource', null);
		//security.update('testResource', null, null);
		//security.delete('testResource', null);
		
		this.assertTrue(true); // Just passin' through...
	}

	///// Create access /////////////////////////////////////////////

	public function test_Then_admin_has_access_if_null()
	{
		var self = this;
		
		rights.set('testResource', { guest: null, owner: null, admin: null } );

		// User is admin in this case, so request is good.
		this.api.requests[0] = function(url : String) : RestApiResponse
		{
			self.assertEqual('/?/USERS/[USER="User"][PASS="Pass\\"word"]', url);
			return RestApiResponse.successData(new RestDataCollection(0, 0, 1, [{id: 1, isAdmin: 1}]));
		}
		
		// Input data is not needed since admin has full access by default.
		security.create('testResource', null, parameters);
		
		this.assertTrue(true); // Just passin' through...
	}
	
	public function test_Then_owner_has_write_access_if_specified_for_foreign_keys()
	{
		var self = this;
		var data : Dynamic = { name: 'ABC' };
		
		rights.set('libraries', { guest: null, owner: {create: 'ALL'}, admin: null } );		
		ownerships[0] = ['users', 'libraries'];

		this.api.requests[1] = function(url : String) : RestApiResponse
		{
			self.assertEqual('/?/users/123/', url);
			return RestApiResponse.successData(new RestDataCollection(0, 0, 1, [{id: 1, name: 'Boris'}]));
		}
		
		security.create('libraries', data, parameters);		
		this.assertEqual(1, data.userId);
	}

	public function test_Then_owner_has_access_if_specified_for_foreign_keys_and_multiple_resources()
	{
		var self = this;
		var data : Dynamic = { name: 'ABC' };
		
		rights.set('news', { guest: null, owner: {create: 'ALL'}, admin: null } );		
		ownerships[0] = ['users', 'libraries', 'news'];

		this.api.requests[1] = function(url : String) : RestApiResponse
		{
			self.assertEqual('/?/users/123/libraries', url);
			return RestApiResponse.successData(new RestDataCollection(0, 0, 1, [{id: 2, name: 'Boris'}]));
		}
		
		security.create('news', data, parameters);		
		this.assertEqual(2, data.libraryId);
	}

	public function test_Then_owner_has_access_if_specified_for_primary_keys()
	{
		var self = this;
		
		rights.set('users', { guest: null, owner: {create: 'ALL'}, admin: null } );		
		ownerships[0] = ['users'];

		this.api.requests[1] = function(url : String) : RestApiResponse
		{
			self.assertEqual('/?/users/123/', url);
			return RestApiResponse.successData(new RestDataCollection(0, 0, 1, [{id: 123, name: 'Doris'}]));
		}
		
		// Do the test.
		var data : Hash<String> = new Hash<String>();
		data.set('name', 'ABC');
		
		security.create('users', data, parameters);
		
		this.assertEqual(data.get('name'), 'ABC');
		this.assertFalse(data.exists('id'));
	}
	
	public function test_Then_owner_has_access_if_specified_for_subset_of_ownerships()
	{
		var self = this;
		
		rights.set('users', { guest: null, owner: {create: 'ALL'}, admin: null } );		
		ownerships[0] = ['users', 'libraries', 'news'];

		this.api.requests[1] = function(url : String) : RestApiResponse
		{
			self.assertEqual('/?/users/123/', url);
			return RestApiResponse.successData(new RestDataCollection(0, 0, 1, [{id: 123, name: 'Doris'}]));
		}
		
		security.create('users', {}, parameters);
	}

	public function test_Then_guest_has_write_access_to_specific_fields_when_specified()
	{
		var self = this;
		var data : Dynamic = { name: 'ABC', count: 123 };
		
		rights.set('news', { guest: {create: ['name', 'count']}, owner: null, admin: null } );		

		security.create('news', data, null);
		this.assertEqual(1,1);
	}

	public function test_Then_guest_has_write_access_to_field_subset_when_specified()
	{
		var self = this;
		var data : Dynamic = { name: 'ABC' };
		
		rights.set('news', { guest: {create: ['name', 'count']}, owner: null, admin: null } );		

		security.create('news', data, null);
		this.assertEqual(1,1);
	}

	public function test_Then_guest_cannot_write_to_unspecified_fields()
	{
		var self = this;
		var data : Dynamic = { name: 'ABC', hack: 1337 };
		
		rights.set('news', { guest: {create: ['name', 'count']}, owner: null, admin: null } );		

		try
		{
			security.create('news', data, null);
		}
		catch(e : RestApiException)
		{
			this.assertPattern(~/Unauthorized access to fields "hack".$/, e.message);
		}
	}

	///// Read access ///////////////////////////////////////////////
}
