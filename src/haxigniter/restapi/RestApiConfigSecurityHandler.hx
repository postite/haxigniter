package haxigniter.restapi;

import haxe.PosInfos;
import haxigniter.exceptions.RestApiException;

import haxigniter.restapi.RestApiSecurityHandler;
import haxigniter.restapi.RestApiInterface;
import haxigniter.restapi.RestApiRequest;
import haxigniter.restapi.RestApiResponse;
import haxigniter.restapi.RestApiFormatHandler;

/////////////////////////////////////////////////////////////////////

enum UserType {
	guest;
	owner;
	admin;
}

typedef UserRights = {
	var guest : Dynamic;
	var owner : Dynamic;
	var admin : Dynamic;
}

typedef Ownerships = Array<Array<String>>;
typedef SecurityRights = Hash<UserRights>;
typedef AnonymousObject = Dynamic;

typedef CreateCallback = RestApiInterface -> PropertyObject -> Hash<String> -> Void;
typedef ReadCallback = RestApiInterface -> RestDataCollection -> Hash<String> -> Void;
typedef UpdateCallback = RestApiInterface -> List<Int> -> PropertyObject -> Hash<String> -> Void;
typedef DeleteCallback = RestApiInterface -> List<Int> -> Hash<String> -> Void;

/////////////////////////////////////////////////////////////////////

class RestApiConfigSecurityHandler implements RestApiSecurityHandler
{
	public var userResource : String;
	public var userNameField : String;
	public var userPasswordField : String;

	public var userIsAdminField : String;
	public var userIsAdminValue : Dynamic;
	
	private static var validCallback = ~/^(admin|owner|guest)(Create|Read|Update|Delete)\w+$/;
	
	private var restApi : RestApiInterface;
	private var rights : SecurityRights;
	private var ownerships : Ownerships;
	private var callbacks : AnonymousObject;
	
	private var ownerID : Int;
	private var isAdmin : Bool;
	
	public function new(rights : SecurityRights, ?ownerships : Ownerships, ?callbacks: AnonymousObject)
	{
		this.isAdmin = false;
		
		if(ownerships == null)
			ownerships = [];
			
		if(callbacks != null)
		{
			// Test callbacks for valid names
			Lambda.iter(Reflect.fields(callbacks), function(funcName : String) {
				if(!validCallback.match(funcName))
					throw new RestApiException('Invalid callback name: ' + funcName, RestErrorType.configurationError);
			});
		}
		else
			callbacks = { };
		
		this.rights = rights;
		this.callbacks = callbacks;
		this.ownerships = ownerships;
	}
	
	///// Data access checks ////////////////////////////////////////

	private function dataResourceCheck(resourceName : String, ?pos : PosInfos) : UserRights
	{
		if(!this.rights.exists(resourceName))
			throw new RestApiException('No rights found for resource: ' + resourceName, RestErrorType.configurationError, null, pos);
		
		return this.rights.get(resourceName);
	}
	
	/**
	 * Returns true if the access is valid for the request input data.
	 * @param	accessObject
	 * @param	type
	 * @param	data
	 * @return
	 */
	private function dataAccessCheck(access : Dynamic, data : Array<PropertyObject>, writeAccess : Bool) : Void
	{
		// If accessArray is null, all fields are valid.
		var accessArray : Array<String>;
		
		if(Std.is(access, String) && cast access == 'ALL')
			accessArray = null;
		else if(Std.is(access, Array))
			accessArray = cast access;
		else
			throw new RestApiException('Invalid data access type: ' + Type.typeof(access), RestErrorType.configurationError);

		Lambda.iter(data, function(obj : PropertyObject)
		{
			if(accessArray == null)
			{
				// Access to all fields is allowed, but cannot write to the "id" field unless stated in the access array.
				if(writeAccess && Reflect.hasField(obj, 'id'))
					throw new RestApiException('Field "id" cannot be modified.', RestErrorType.invalidData);
			}
			else
			{
				var errorFields = new List<Dynamic>();
				
				// If access is specified as an array, only allow a subset of the specified rules.
				for(dataField in Reflect.fields(obj))
				{
					if(!Lambda.has(accessArray, dataField))
						errorFields.push(dataField);
				}
				
				if(errorFields.length > 0)
					throw new RestApiException('Unauthorized access to fields "' + errorFields.join(',') + '".', RestErrorType.unauthorizedRequest);
			}
		});
	}
	
	private function dataOwnerCheck(resourceName : String, ids : List<Int>) : Void
	{
		if(this.ownerID != null)
		{
			var self = this;
			
			// Ownership is handled by checking the ownerID with the ownership list.
			for(ownerTable in this.ownerships)
			{
				var resourcePos = 0;
				for(i in 0 ... ownerTable.length)
				{
					if(ownerTable[i] == resourceName)
					{
						resourcePos = i;
						break;
					}
				}
				
				// Make the request and set key/value if it returns ok.
				this.restApi.read(buildOwnerRequest(resourceName, ownerTable, resourcePos, false), function(response : RestApiResponse)
				{
					switch(response)
					{
						case successData(data):
							var bigSet = new List<Int>();
							Lambda.iter(data, function(row : Dynamic) {
								bigSet.push(row.id);
							});
							
							if(!self.isSubsetOf(ids, bigSet))
								throw new RestApiException('Unauthorized owner data access.', RestErrorType.unauthorizedRequest);
							
						default:
							throw new RestApiException('Unauthorized owner data access.', RestErrorType.unauthorizedRequest);
					}
				});
			}			
		}
		else
		{
			throw new RestApiException('Unauthorized owner data access.', RestErrorType.unauthorizedRequest);
		}
	}

	/////////////////////////////////////////////////////////////////
	
	private function isSubsetOf<T>(subSet : List<T>, bigSet : List<T>) : Bool
	{
		for(v in subSet)
		{
			if(!Lambda.has(bigSet, v))
				return false;
		}
		
		return true;
	}
	
	private function buildOwnerRequest(resourceName : String, table : Array<String>, resourcePos : Int, createRequest : Bool) : String
	{
		if(this.ownerID == null)
			throw new RestApiException('Unauthorized owner data access.', RestErrorType.unauthorizedRequest);
		
		// If a create request is made, strip the last table since the request should get the foreign key.
		var requestTable = createRequest ? table.slice(1, resourcePos) : table.slice(1, resourcePos+1);
		
		// [users, libraries, news] becomes /?/users/ownerID/libraries//news
		return '/?/' + table[0] + '/' + this.ownerID + '/' + requestTable.join('//');
	}

	private function setDataOwnership(resourceName : String, data : PropertyObject) : Void
	{
		if(this.ownerID == null)
			throw new RestApiException('Unauthorized owner data access.', RestErrorType.unauthorizedRequest);

		var done = false;
		
		for(ownerTable in this.ownerships)
		{
			var resourcePos = 0;
			for(i in 0 ... ownerTable.length)
			{
				if(ownerTable[i] == resourceName)
				{
					resourcePos = i;
					break;
				}
			}

			var request = buildOwnerRequest(resourceName, ownerTable, resourcePos, true);

			// Make the request and set key/value if it returns ok.
			this.restApi.read(request, function(response : RestApiResponse)
			{
				switch(response)
				{
					case successData(responseData):
						if(responseData.totalCount == 1)
						{
							if(resourcePos > 0)
							{
								var keyField = haxigniter.libraries.Inflection.singularize(ownerTable[resourcePos-1]) + 'Id';
								
								// Single resource request, set output to id field.
								if(!Reflect.hasField(responseData.data[0], 'id'))
									throw new RestApiException('Field "id" not found when determining user ownership for "'+resourceName+'".', RestErrorType.configurationError);

								// Output value is always the id field of the data row, since it was specified as the
								// last resource in the request string created by buildOwnerRequest().
								Reflect.setField(data, keyField, responseData.data[0].id);
								done = true;
							}
						}
						
					default:
						throw new RestApiException('Determining ownership for resource "'+resourceName+'" failed.', RestErrorType.configurationError);
				}
			});
			
			if(done) break;
		}
	}

	/////////////////////////////////////////////////////////////////

	/*
	private function isWriteRequest(type : RestApiRequestType) : Bool
	{
		return type != RestApiRequestType.read;
	}

	private function testAdminAccess(resourceName : String, writeRequest : Bool, ids : List<Int>, data : Array<Dynamic>) : Void
	{
		if(!this.isAdmin)
			return false;
		else if(this.rights.get(resourceName).admin == null)
			return true;
		
		var writeRequest = this.isWriteRequest(type);
			
	}
	
	private function guestHasAccess(resourceName : String, type : RestApiRequestType, data : PropertyObject) : Bool
	{
		if(this.rights.get(resourceName).guest == null)
			return false;
		
		return validResourceAccess(this.rights.get(resourceName).guest, type, data);
	}
	*/

	/**
	 * After this method is called, this.ownerID and this.isAdmin is set or exception is thrown.
	 * @param	parameters
	 */
	private function authorizeUser(parameters : Hash<String>) : Void
	{
		if(parameters == null || (!parameters.exists('username') && !parameters.exists('password')))
			return;
		
		if(!parameters.exists('username') || !parameters.exists('password'))
			throw new RestApiException('Missing parameters "username" or "password" when authorizing user.', RestErrorType.unauthorizedRequest);
		
		var self = this;
		var authorizeString = '/?/' + this.userResource + '/' +
			'[' + this.userNameField + '="' + StringTools.replace(parameters.get('username'), '"', '\\"') + '"]' +
			'[' + this.userPasswordField + '="' + StringTools.replace(parameters.get('password'), '"', '\\"') + '"]';
		
		this.restApi.read(authorizeString, function(response : RestApiResponse) {
			switch(response)
			{
				case successData(data):
					if(data.totalCount == 1)
					{
						var userRow = data.data[0];
						
						if(!Reflect.hasField(userRow, 'id'))
							throw new RestApiException('Field "id" not found when authorizing user.', RestErrorType.configurationError);
						
						self.ownerID = userRow.id;
						
						if(self.userIsAdminField != null && Reflect.hasField(userRow, self.userIsAdminField))
							self.isAdmin = Reflect.field(userRow, self.userIsAdminField) == self.userIsAdminValue;
						
						return;
					}
					
				default:
			}
			
			throw new RestApiException('Invalid username or password.', RestErrorType.unauthorizedRequest);
		});
	}

	private function authorizationFailed(message = 'Unauthorized access.', ?pos : PosInfos) : Void
	{
		throw new RestApiException(message, RestErrorType.unauthorizedRequest, null, pos);
	}
	
	///// RestApiSecurityHandler implementation /////////////////////
	
	public function create(resourceName : String, data : PropertyObject, ?parameters : Hash<String>) : Void
	{
		var rights : UserRights = this.dataResourceCheck(resourceName);
		var access : Dynamic;

		if(data == null || Reflect.fields(data).length == 0)
			throw new RestApiException('No request data found!', RestErrorType.invalidData);

		this.authorizeUser(parameters);
		
		if(this.isAdmin)
		{
			access = this.accessFor(RestApiRequestType.create, rights.admin);
			
			// Admin has full access so set it to ALL if no rights is set.
			this.dataAccessCheck(access == null ? 'ALL' : access, [data], true);
			return;
		}
		
		if(this.ownerID != null)
		{
			access = this.accessFor(RestApiRequestType.create, rights.owner);

			if(access != null)
			{
				this.dataAccessCheck(access, [data], true);
				// If data access was ok, add foreign key to data if needed.
				
				this.setDataOwnership(resourceName, data);
				return;
			}
		}
		
		// Finally, test guest access.
		access = this.accessFor(RestApiRequestType.create, rights.guest);
		
		if(access != null)
			this.dataAccessCheck(access, [data], true);
		else
			this.authorizationFailed();
	}
	
	private function accessFor(type : RestApiRequestType, access : Dynamic) : Dynamic
	{
		if(access == null) return null;
		
		var typeString = Std.string(type);
		return Reflect.hasField(access, typeString) ? Reflect.field(access, typeString) : null;
	}
	
	public function read(resourceName : String, data : RestDataCollection, ?parameters : Hash<String>) : Void
	{
		this.dataResourceCheck(resourceName);
		throw new RestApiException('Not implemented.', RestErrorType.unauthorizedRequest);
	}
	
	public function update(resourceName : String, ids : List<Int>, data : PropertyObject, ?parameters : Hash<String>) : Void
	{
		this.dataResourceCheck(resourceName);
		throw new RestApiException('Not implemented.', RestErrorType.unauthorizedRequest);
	}
	
	public function delete(resourceName : String, ids : List<Int>, ?parameters : Hash<String>) : Void
	{
		this.dataResourceCheck(resourceName);
		throw new RestApiException('Not implemented.', RestErrorType.unauthorizedRequest);
	}
	
	public function install(api : RestApiInterface) { this.restApi = api; }
}
