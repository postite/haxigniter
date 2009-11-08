package haxigniter.restapi;

import haxe.PosInfos;
import haxigniter.exceptions.RestApiException;

import haxigniter.restapi.RestApiSecurityHandler;
import haxigniter.restapi.RestApiInterface;
import haxigniter.restapi.RestApiRequest;
import haxigniter.restapi.RestApiResponse;
import haxigniter.restapi.RestApiFormatHandler;

/////////////////////////////////////////////////////////////////////

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
	
	/////////////////////////////////////////////////////////////////

	/**
	 * Returns true if the access is valid for the request input data.
	 * @param	accessObject
	 * @param	type
	 * @param	data
	 * @return
	 */
	private function validResourceAccess(accessObject : Dynamic, type : RestApiRequestType, data : PropertyObject) : Bool
	{
		if(data == null)
			throw new RestApiException('No request data found!', RestErrorType.invalidData);

		var typeName = Std.string(type);
		
		if(!Reflect.hasField(accessObject, typeName))
			throw new RestApiException('No access rights found for type: ' + typeName, RestErrorType.configurationError);
		
		var access = Reflect.field(accessObject, typeName);
		
		if(Std.is(access, String))
		{
			if(cast access == 'ALL')
			{
				if(this.hasProperty(data, 'id'))
					throw new RestApiException('Field "id" cannot be modified.', RestErrorType.invalidData);

				return true;
			}
		}
		else if(Std.is(access, Array))
		{
			var errorFields = new List<Dynamic>();
			
			// If access is specified as an array, only allow a subset of the specified rules.
			for(dataField in this.properties(data))
			{
				if(!Lambda.has(cast access, dataField))
					errorFields.push(dataField);
			}
			
			if(errorFields.length > 0)
				throw new RestApiException('Unauthorized access to fields "' + errorFields.join(',') + '".', RestErrorType.unauthorizedRequest);
			
			return true;
		}
		
		return false;
	}
	
	/////////////////////////////////////////////////////////////////

	/**
	 * Returns null or the foreign key and value to add to the request data if ownership was found, for create requests.
	 * For read/update/delete, testing for not null is enough for validating.
	 */
	private function ownerHasAccess(resourceName : String, type : RestApiRequestType, data : PropertyObject) : {key: String, value: Int}
	{
		var output : { key: String, value: Int } = null;
		
		if(this.ownerID == null || this.rights.get(resourceName).owner == null)
			return null;

		if(!validResourceAccess(this.rights.get(resourceName).owner, type, data))
			return null;

		// Ownership is handled by checking the ownerID with the ownership list.
		for(ownerTable in this.ownerships)
		{
			var request = buildOwnerRequest(resourceName, ownerTable, ownerID, type == RestApiRequestType.create);			
			if(request == null) continue;

			// Make the request and set key/value if it returns ok.
			this.restApi.read(request, function(response : RestApiResponse)
			{
				switch(response)
				{
					case successData(data):
						if(data.totalCount == 1)
						{
							if(ownerTable.length == 1)
							{
								// Output is found but no need to set key since it's a single resource.
								output = { key: null, value: null }
							}
							else
							{
								var keyField = haxigniter.libraries.Inflection.singularize(ownerTable[ownerTable.length - 2]) + 'Id';
								
								// Single resource request, set output to id field.
								if(!Reflect.hasField(data.data[0], 'id'))
									throw new RestApiException('Field "id" not found when determining user ownership for "'+resourceName+'".', RestErrorType.configurationError);

								// Output value is always the id field of the data row, since it was specified as the
								// last resource in the request string created by buildOwnerRequest().
								output = { key: keyField, value: data.data[0].id };
							}
						}
						
					default:
				}
			});
		}
		
		return output;
	}
	
	private function buildOwnerRequest(resourceName : String, table : Array<String>, ownerID : Int, createRequest : Bool) : String
	{
		var resourcePos = 0;
		
		for(i in 0 ... table.length)
		{
			if(table[i] == resourceName)
			{
				resourcePos = i;
				break;
			}
		}
		
		// If a create request is made, strip the last table since the request should get the foreign key.
		var requestTable = createRequest ? table.slice(1, resourcePos) : table.slice(1, resourcePos+1);
		
		// [users, libraries, news] becomes /?/users/ownerID/libraries//news
		return '/?/' + table[0] + '/' + ownerID + '/' + requestTable.join('//');
	}
	
	private function adminHasAccess(resourceName : String, type : RestApiRequestType, data : PropertyObject) : Bool
	{
		if(!this.isAdmin)
			return false;
		else if(this.rights.get(resourceName).admin == null)
			return true;
		
		return validResourceAccess(this.rights.get(resourceName).admin, type, data);
	}
	
	private function guestHasAccess(resourceName : String, type : RestApiRequestType, data : PropertyObject) : Bool
	{
		if(this.rights.get(resourceName).guest == null)
			return false;
		
		return validResourceAccess(this.rights.get(resourceName).guest, type, data);
	}
	
	private function testUserRights(resourceName : String, ?pos : PosInfos) : Void
	{
		if(!this.rights.exists(resourceName))
			throw new RestApiException('No rights found for resource: ' + resourceName, RestErrorType.configurationError, null, pos);
	}
	
	/**
	 * After this method is called, this.ownerID and this.isAdmin is set or exception is thrown.
	 * @param	parameters
	 */
	private function authorizeUser(parameters : Hash<String>) : Void
	{
		if(parameters == null)
			throw new RestApiException('Missing parameters "username" and "password" when authorizing user.', RestErrorType.unauthorizedRequest);
		
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

	private function properties(data : PropertyObject) : Array<String>
	{
		if(Reflect.isObject(data))
		{
			return Reflect.fields(data);
		}
		else if(Std.is(data, Hash))
		{
			var hash : Hash<Dynamic> = cast(data, Hash<Dynamic>);
			return Lambda.array({iterator: hash.iterator});
		}
		else
			throw new RestApiException('Unsupported request data type: ' + Type.typeof(data), RestErrorType.invalidData);
	}

	private function hasProperty(data : PropertyObject, property : String) : Bool
	{
		if(Reflect.isObject(data))
		{
			return Reflect.hasField(data, property);
		}
		else if(Std.is(data, Hash))
		{
			var hash : Hash<Dynamic> = cast(data, Hash<Dynamic>);
			return hash.exists(property);
		}
		else
			throw new RestApiException('Unsupported request data type: ' + Type.typeof(data), RestErrorType.invalidData);
	}
	
	private function setProperty(data : PropertyObject, keyValue : { key: String, value: Int }) : Void
	{
		if(Reflect.isObject(data))
		{
			Reflect.setField(data, keyValue.key, keyValue.value);
		}
		else if(Std.is(data, Hash))
		{
			var hash : Hash<Dynamic> = cast(data, Hash<Dynamic>);
			hash.set(keyValue.key, keyValue.value);
		}
		else
			throw new RestApiException('Unsupported request data type: ' + Type.typeof(data), RestErrorType.invalidData);
	}	
	
	///// RestApiSecurityHandler implementation /////////////////////
	
	public function create(resourceName : String, data : PropertyObject, ?parameters : Hash<String>) : Void
	{
		this.testUserRights(resourceName);
		
		// Test if guest can create the resource.
		if(!this.guestHasAccess(resourceName, RestApiRequestType.create, data))
		{
			this.authorizeUser(parameters);
			if(!this.adminHasAccess(resourceName, RestApiRequestType.create, data))
			{
				var ownerData = this.ownerHasAccess(resourceName, RestApiRequestType.create, data);
				
				if(ownerData == null)
				{
					throw new RestApiException('No authorization for create request.', RestErrorType.unauthorizedRequest);
				}
				else if(ownerData.key != null)
				{
					// Set foreign key if it exists.
					this.setProperty(data, ownerData);
				}
			}
		}
	}
	
	public function read(resourceName : String, data : RestDataCollection, ?parameters : Hash<String>) : Void
	{
		this.testUserRights(resourceName);
		throw new RestApiException('Not implemented.', RestErrorType.unauthorizedRequest);
	}
	
	public function update(resourceName : String, ids : List<Int>, data : PropertyObject, ?parameters : Hash<String>) : Void
	{
		this.testUserRights(resourceName);
		throw new RestApiException('Not implemented.', RestErrorType.unauthorizedRequest);
	}
	
	public function delete(resourceName : String, ids : List<Int>, ?parameters : Hash<String>) : Void
	{
		this.testUserRights(resourceName);
		throw new RestApiException('Not implemented.', RestErrorType.unauthorizedRequest);
	}
	
	public function install(api : RestApiInterface) { this.restApi = api; }
}
