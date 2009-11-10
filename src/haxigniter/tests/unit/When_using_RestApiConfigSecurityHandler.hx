package haxigniter.tests.unit;

import haxigniter.exceptions.RestApiException;
import haxigniter.restapi.RestApiConfigSecurityHandler;

import haxigniter.restapi.RestApiInterface;
import haxigniter.restapi.RestApiResponse;

using haxigniter.libraries.IterableTools;

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
		if(count >= requests.length)
			throw 'Expected only ' + count + ' request(s) for MockApiInterface.';
		
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
			this.assertPattern(~/No request data found!$/, e.message);
		}

		try
		{
			security.read('testResource', null);
		}
		catch(e : RestApiException)
		{
			this.assertPattern(~/No rights found for resource: testResource$/, e.message);
		}

		/*
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
		*/
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
			security.create('testResource', {name: 'Doris'}, parameters);
		}
		catch(e : RestApiException)
		{
			this.assertPattern(~/^Invalid username or password.$/, e.message);
		}		
	}
	
	public function test_Then_guest_has_access_if_specified()
	{
		rights.set('testResource', {guest: {create: 'ALL', read: 'ALL', update: 'ALL', delete: 'ALL'}, owner: null, admin: null});
		
		security.create('testResource', {name: 'Boris'});
		security.read('testResource', new RestDataCollection(0, 0, 1, [{id: 456, name: 'Boris'}]));
		//security.update('testResource', null, null);
		//security.delete('testResource', null);
		
		this.assertTrue(true); // Just passin' through...
	}

	public function test_Then_no_access_if_not_specified()
	{
		rights.set('testResource', {guest: null, owner: null, admin: null});
		
		try
		{
			security.create('testResource', {name: 'Doris'});
		}
		catch(e : RestApiException)
		{
			this.assertPattern(~/^Unauthorized access.$/, e.message);
		}
	}

	///// Create access /////////////////////////////////////////////

	public function test_Then_admin_has_no_access_if_not_specified()
	{
		var self = this;
		
		rights.set('testResource', { guest: null, owner: null, admin: null } );

		// User is admin in this case, so request is good.
		this.api.requests[0] = function(url : String) : RestApiResponse
		{
			self.assertEqual('/?/USERS/[USER="User"][PASS="Pass\\"word"]', url);
			return RestApiResponse.successData(new RestDataCollection(0, 0, 1, [{id: 1, isAdmin: 1}]));
		}
		
		try
		{
			security.create('testResource', {name: 'Doris'});
		}
		catch(e : RestApiException)
		{
			this.assertPattern(~/^Unauthorized access.$/, e.message);
		}
	}

	public function test_Then_admin_has_access_if_specified()
	{
		var self = this;
		
		rights.set('testResource', { guest: null, owner: null, admin: 'ALL' } );

		// User is admin in this case, so request is good.
		this.api.requests[0] = function(url : String) : RestApiResponse
		{
			self.assertEqual('/?/USERS/[USER="User"][PASS="Pass\\"word"]', url);
			return RestApiResponse.successData(new RestDataCollection(0, 0, 1, [{id: 1, isAdmin: 1}]));
		}
		
		security.create('testResource', {name: 'Boris'}, parameters);
	}
	
	public function test_Then_owner_has_write_access_if_specified_for_foreign_keys()
	{
		var self = this;
		var data : Dynamic = { name: 'ABC' };
		
		rights.set('libraries', { guest: null, owner: {create: 'ALL'}, admin: null } );		
		ownerships[0] = ['users', 'libraries'];

		// Current ownerID is 123.
		// The security check returns a user with incorrect ID:
		this.api.requests[1] = function(url : String) : RestApiResponse
		{
			self.assertEqual('/?/users/123/', url);
			return RestApiResponse.successData(new RestDataCollection(0, 0, 1, [{id: 456, name: 'Boris'}]));
		}
		
		try
		{
			// Try to add something to users with incorrect id.
			security.create('libraries', data, 'users', 1, parameters);
		}
		catch(e : RestApiException)
		{
			this.assertPattern(~/^Unauthorized access.$/, e.message);
		}
		
		// Returns a user with correct ID this time. OwnerID is now 456.
		this.api.requests[2] = function(url : String) : RestApiResponse
		{
			self.assertEqual('/?/USERS/[USER="User"][PASS="Pass\\"word"]', url);
			return RestApiResponse.successData(new RestDataCollection(0, 0, 1, [{id: 456, isAdmin: 0}]));
		}
		
		// The return value from the security check now matches the ownerID:
		this.api.requests[3] = function(url : String) : RestApiResponse
		{
			self.assertEqual('/?/users/456/', url);
			return RestApiResponse.successData(new RestDataCollection(0, 0, 1, [{id: 456, name: 'Boris'}]));
		}
		
		// Creating a library with users as parent table.
		security.create('libraries', data, 'users', 456, parameters);
		
		this.assertEqual(456, data.userId);
		this.assertEqual('ABC', data.name);
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
			return RestApiResponse.successData(new RestDataCollection(0, 0, 1, [{id: 1, name: 'Boris'}, {id:2, name: 'Doris'}]));
		}

		// Now the ID must be included in the above resultset or access is denied.
		security.create('news', data, 'libraries', 2, parameters);
		this.assertEqual(2, data.libraryId);
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
		
		security.create('users', {name: 'Boris'}, 'libraries', 123, parameters);
	}

	public function test_Then_guest_rights_is_used_if_owner_access_fails()
	{
		var self = this;
		
		rights.set('users', { guest: {create: ['name']}, owner: null, admin: null } );		
		ownerships[0] = ['users', 'libraries', 'news'];

		this.api.requests[0] = function(url : String) : RestApiResponse
		{
			self.assertEqual('/?/USERS/[USER="User"][PASS="Pass\\"word"]', url);
			return RestApiResponse.successData(new RestDataCollection(0, 0, 1, [{id: 999, name: "Valid user but no access rights exists."}]));
		}

		try
		{
			security.create('users', { name: 'Boris', count: 123 }, parameters);
		}
		catch(e : RestApiException)
		{
			this.assertPattern(~/Unauthorized access to fields "count".$/, e.message);
		}
	}

	public function test_Then_guest_has_write_access_to_specific_fields_when_specified()
	{
		var self = this;
		var data : Dynamic = { name: 'ABC', count: 123 };
		
		rights.set('news', { guest: {create: ['name', 'count']}, owner: null, admin: null } );		

		security.create('news', data, null);
		this.assertTrue(true);
	}

	public function test_Then_guest_has_write_access_to_field_subset_when_specified()
	{
		var self = this;
		var data : Dynamic = { name: 'ABC' };
		
		rights.set('news', { guest: {create: ['name', 'count']}, owner: null, admin: null } );		

		security.create('news', data, null);
		this.assertTrue(true);
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
	
	public function test_Then_ALL_rights_gives_read_access_to_all_fields()
	{
		var self = this;
		var data = new RestDataCollection(0, 0, 1, [ { id: 1, firstname: 'Boris', lastname: 'Doris' } ]);
		
		rights.set('testResource', { guest: {read: 'ALL'}, owner: null, admin: null } );
		security.read('testResource', data, parameters);
		
		this.assertEqualObjects({ id: 1, firstname: 'Boris', lastname: 'Doris' }, data.data[0]);
	}

	public function test_Then_array_rights_gives_read_access_to_specified_fields()
	{
		var self = this;
		var data = new RestDataCollection(0, 0, 1, [ { id: 1, firstname: 'Boris', lastname: 'Doris' } ]);
		
		rights.set('testResource', { guest: {read: ['id', 'firstname']}, owner: null, admin: null } );
		security.read('testResource', data, parameters);
		
		this.assertEqualObjects({ id: 1, firstname: 'Boris' }, data.data[0]);
	}

	public function test_Then_owner_must_own_the_resources_for_read_access()
	{
		var self = this;
		
		var smalldata = new RestDataCollection(0, 0, 1, [ { id: 2, firstname: 'Justin', lastname: 'Case' } ]);
		var data = new RestDataCollection(0, 0, 1, [ { id: 1, firstname: 'Boris', lastname: 'Doris' }, { id: 2, firstname: 'Justin', lastname: 'Case' } ]);
		
		rights.set('news', { guest: null, owner: { read: ['id', 'firstname'] }, admin: null } );
		ownerships[0] = ['users', 'libraries', 'news'];

		this.api.requests[1] = function(url : String) : RestApiResponse
		{
			self.assertEqual('/?/users/123/libraries//news', url);
			return RestApiResponse.successData(data);
		}

		security.read('news', smalldata, parameters);
		
		this.assertEqual(smalldata.totalCount, 1);
		this.assertEqualObjects( { id: 2, firstname: 'Justin' }, smalldata.data[0]);
	}

	public function test_Then_if_owner_requests_more_than_he_owns_error_is_thrown()
	{
		var self = this;
		
		var smalldata = new RestDataCollection(0, 0, 1, [ { id: 2, firstname: 'Justin', lastname: 'Case' } ]);
		var data = new RestDataCollection(0, 0, 1, [ { id: 1, firstname: 'Boris', lastname: 'Doris' }, { id: 2, firstname: 'Justin', lastname: 'Case' } ]);
		
		rights.set('news', { guest: null, owner: { read: ['id', 'firstname'] }, admin: null } );
		ownerships[0] = ['users', 'libraries', 'news'];

		this.api.requests[1] = function(url : String) : RestApiResponse
		{
			self.assertEqual('/?/users/123/libraries//news', url);
			return RestApiResponse.successData(smalldata);
		}

		try
		{
			security.read('news', data, parameters);
		}
		catch(e : RestApiException)
		{
			this.assertPattern(~/Unauthorized access.$/, e.message);
		}
	}

	/////////////////////////////////////////////////////////////////
	
	private function assertEqualObjects(o1 : Dynamic, o2 : Dynamic)
	{
		var f1 = Reflect.fields(o1);
		var f2 = Reflect.fields(o2);
		
		this.assertEqual(f1.length, f2.length);
		this.assertTrue(f1.isSubsetOf(f2));
		
		for(field in f1)
		{
			this.assertEqual(Reflect.field(o1, field), Reflect.field(o2, field));
		}
	}
}
