package haxigniter.restapi;

import haxigniter.libraries.Inflection;
import haxigniter.libraries.Database;

#if php
import php.Lib;
import php.Web;
import php.db.ResultSet;
#elseif neko
import neko.Lib;
import neko.Web;
import neko.db.ResultSet;
#end

import haxigniter.libraries.Database;

import haxigniter.controllers.RestApiController;
import haxigniter.restapi.RestApiRequest;
import haxigniter.restapi.RestApiResponse;

import haxigniter.exceptions.RestApiException;

typedef SqlQueryPart = {
	var name : String;
	var sql: String;
	var values: Array<String>;
}

typedef SqlQueryBase = {
	var joins : SqlQueryPart;
	var where : SqlQueryPart;
	var order : String;
	var limit : Int;
	var offset : Int;
}

class RestApiSqlRequestHandler implements RestApiRequestHandler
{
	public var supportedContentTypes(default, null) : Hash<String>;
	
	private var db : DatabaseConnection;
	
	public function new(db : DatabaseConnection)
	{
		this.db = db;
		
		supportedContentTypes = new Hash<String>();
		supportedContentTypes.set('haxigniter', RestApiController.commonMimeTypes.haxigniter);
		
		supportedOutputFormats = ['haxigniter'];
	}

	///// RestApiRequestHandler implementation //////////////////////

	public var supportedOutputFormats(default, null) : Array<RestApiFormat>;

	public function handleApiRequest(request : RestApiRequest) : RestApiResponse
	{
		switch(request.type)
		{
			case read:
				return handleReadRequest(request);
			case create:
				return handleCreateRequest(request);
			case delete:
				return handleDeleteRequest(request);
			case update:
				return handleUpdateRequest(request);
		}
	}

	private inline function requestData(request : RestApiRequest) : Hash<String>
	{
		var data = haxigniter.libraries.Input.parseQuery(request.data);
		var empty = true;
		
		for(key in data.keys())
		{
			// Test for malicious keys.
			this.db.testAlphaNumeric(key);
			empty = false;
		}
		
		if(empty)
			throw new RestApiException('No data specified in request.', RestErrorType.invalidData);

		return data;
	}
	
	public function handleCreateRequest(request : RestApiRequest) : RestApiResponse
	{
		var createResource = request.resources[request.resources.length - 1];
		
		if(createResource.selectors.length > 0)
			throw new RestApiException('Ending resource cannot have any selectors in create requests.', RestErrorType.invalidQuery);

		var data = requestData(request);
		
		var output = new Array<Int>();
		
		if(request.resources.length > 1)
		{
			// Create a select query based on everything up to (but not including) the last resource, to get the ids for the foreign key.
			var query = buildBaseSql(request.resources.slice(0, -1));
			var foreignKey = Inflection.singularize(query.where.name) + 'Id';
			
			for(id in selectSqlId(query))
			{
				data.set(foreignKey, Std.string(id));
				
				db.insert(createResource.name, data);
				output.push(db.lastInsertId());
			}
		}
		else
		{
			db.insert(createResource.name, data);
			output.push(db.lastInsertId());			
		}
		
		return RestApiResponse.success(output);
	}

	public function handleUpdateRequest(request : RestApiRequest) : RestApiResponse
	{
		var data = requestData(request);
		var output = new Array<Int>();

		var base = buildBaseSql(request.resources);
		var ids = selectSqlId(base);

		var updateAll : Bool = request.resources.length == 1 && request.resources[0].selectors.length == 0;
		var tableName = request.resources[request.resources.length - 1].name;
		
		if(ids.length > 0 || updateAll)
		{
			var query = 'UPDATE ' + tableName + ' SET ';
			
			var updateData = new Array<String>();
			var values = [];
			for(key in data.keys())
			{
				updateData.push(key + '=?');			
				values.push(data.get(key));
			}
			
			// Add the data keys to the query.
			query += updateData.join(', ');
			
			// Test affected rows or just return ids?
			if(!updateAll)
				query += ' WHERE ' + tableName + '.id IN(' + ids.join(',') + ')';

			db.query(query, values);
		}
			
		return RestApiResponse.success(ids);
	}

	public function handleDeleteRequest(request : RestApiRequest) : RestApiResponse
	{
		var output = new Array<Int>();

		var base = buildBaseSql(request.resources);
		var ids = selectSqlId(base);

		var deleteAll : Bool = request.resources.length == 1 && request.resources[0].selectors.length == 0;
		var tableName = request.resources[request.resources.length - 1].name;

		if(ids.length > 0 || deleteAll)
		{
			var query = 'DELETE FROM ' + tableName;
			
			// Test affected rows or just return ids?
			if(!deleteAll)
				query += ' WHERE ' + tableName + '.id IN(' + ids.join(',') + ')';
			
			db.query(query);
		}
		
		return RestApiResponse.success(ids);
	}

	public function handleReadRequest(request : RestApiRequest) : RestApiResponse
	{
		var query = buildBaseSql(request.resources);
		var select = selectSql(query);
		
		// TODO: Enforce upper limit
		// TODO: Use SQL_CALC_FOUND_ROWS for the Mysql driver.

		var results = db.query('SELECT ' + query.where.name + '.*' + select.sql, select.values);
		var response : RestDataCollection;
		
		if(query.limit == 0 && query.offset == 0)
		{
			response = new RestDataCollection(0, cast(Math.max(0, results.length-1), Int), results.length, Lambda.array(results.results()));
		}
		else
		{
			var limitPos : Int;
			
			// Cut the query after the ORDER BY or LIMIT, it's not needed when counting.
			if(query.order != '')
				limitPos = select.sql.lastIndexOf('ORDER BY');
			else if(query.limit > 0 || query.offset > 0)
				limitPos = select.sql.lastIndexOf('LIMIT');
			else
				limitPos = select.sql.length;
			
			var count = db.queryInt('SELECT COUNT(*) ' + select.sql.substr(0, limitPos), select.values);
			response = new RestDataCollection(query.offset, query.offset + results.length - 1, count, Lambda.array(results.results()));
		}
		
		return haxigniter.restapi.RestApiResponse.successData(response);
	}
	
	public function attributeToSql(name : String, operator : RestApiSelectorOperator, value : String, newValue : {val : String}) : String
	{
		newValue.val = value;
		
		switch(operator)
		{
			case contains:
				newValue.val = '%' + value + '%';
				return name + ' LIKE ?';
			
			case endsWith:
				newValue.val = '%' + value;
				return name + ' LIKE ?';

			case equals:
				return name + ' = ?';

			case lessThan:
				return name + ' < ?';

			case lessThanOrEqual:
				return name + ' <= ?';

			case moreThan:
				return name + ' > ?';

			case moreThanOrEqual:
				return name + ' >= ?';

			case notEqual:
				return name + ' != ?';

			case startsWith:
				newValue.val = value + '%';
				return name + ' LIKE ?';
		}
	}
	
	public function outputApiResponse(response : RestApiResponse, outputFormat : RestApiFormat) : RestResponseOutput
	{
		return {
			contentType: supportedContentTypes.get(supportedOutputFormats[0]),
			charSet: null,
			output: haxe.Serializer.run(response)
		};
	}

	/////////////////////////////////////////////////////////////////

	public function selectSqlId(query : SqlQueryBase) : Array<Int>
	{
		var output = new Array<Int>();
		
		var select = selectSql(query);
		var foreignKey = Inflection.singularize(query.where.name) + 'Id';
		
		for(row in db.query('SELECT ' + query.where.name + '.id' + select.sql, select.values))
		{
			output.push(row.id);
		}
		
		return output;
	}
	
	public function selectSql(query : SqlQueryBase) : SqlQueryPart
	{
		// Query the database
		var sql = ' FROM ' + query.where.name + ' ' + query.joins.sql + ' ';
		
		if(query.where.sql != '')
			sql += 'WHERE ' + query.where.sql + ' ';
		
		if(query.order != '')
			sql += 'ORDER BY ' + query.order + ' ';
		
		if(query.limit > 0 || query.offset > 0)
			sql += 'LIMIT ' + (query.offset > 0 ? query.offset + ',' : '') + query.limit;

		var values = query.joins.values.concat(query.where.values);
		
		return { name: '', sql: sql, values: values };
	}
	
	public function buildBaseSql(resources : Array<RestApiResource>) : SqlQueryBase
	{
		var tables = [];
		
		var order = null;
		var limit = null;
		var offset = null;
		
		for(resource in resources)
		{
			var attributes = [];
			var values = [];
			
			for(selector in resource.selectors)
			{
				switch(selector)
				{
					case func(name, args):
						switch(name.toLowerCase())
						{
							case 'range':
								if(limit != null)
									throw new RestApiException('range() can only be called once in a selector.', RestErrorType.invalidQuery);

								if(args.length != 2)
									throw new RestApiException('range() takes exactly two arguments.', RestErrorType.invalidQuery);
								
								var start = Std.parseInt(args[0]);
								var end = Std.parseInt(args[1]);
								
								if(start == null)
									throw new RestApiException('Error in range() when parsing "' + args[0] + '" to integer.', RestErrorType.invalidQuery);

								if(end == null)
									throw new RestApiException('Error in range() when parsing "' + args[1] + '" to integer.', RestErrorType.invalidQuery);
								
								if(end < start)
									throw new RestApiException('Start of range() cannot be higher than the end.', RestErrorType.invalidQuery);

								limit = end - start;
								offset = start;
						
							case 'order':
								if(order != null)
									throw new RestApiException('Order can only be set once in a selector.', RestErrorType.invalidQuery);

								var orders = new Array<String>();
								for(i in 0 ... args.length)
								{
									if(i%2 == 1) continue;
									
									this.db.testAlphaNumeric(args[i]);
									
									if(args[i+1] == null)
										orders.push(args[i]);
									else
									{
										var orderBy = args[i+1].toUpperCase();
										
										if(orderBy == 'ASC' || orderBy == 'DESC')
											orders.push(args[i] + ' ' + orderBy);
										else
											throw new RestApiException('order() keyword can only be ASC or DESC, was "' + orderBy + '".', RestErrorType.invalidQuery);
									}										
								}								
								order = orders.join(', ');
						
							case 'random':
								if(order != null)
									throw new RestApiException('Order can only be set once in a selector.', RestErrorType.invalidQuery);

								switch(this.db.driver)
								{
									case DatabaseDriver.mysql:
										order = 'RAND()';
									case DatabaseDriver.sqlite:
										order = 'RANDOM()';
								}
								
							default:
								throw new RestApiException('pseudo-function "'+name+'" is not supported by the sql request handler.', RestErrorType.invalidQuery);
						}
					
					case attribute(name, operator, value):
						var newValue = { val: '' };
						attributes.push(attributeToSql(resource.name + '.' + name, operator, value, newValue));
						values.push(newValue.val);
				}
			}
			
			tables.push({name: resource.name, attributes: attributes, values: values});
		}
		
		return { 
			joins: createSqlJoin(tables),
			where: createSqlWhere(tables[tables.length-1]),
			order: (order == null ? '' : order), 
			limit: (limit == null ? 0 : limit), 
			offset: (offset == null ? 0 : offset) 
			};
	}

	private function createSqlWhere(table : {name: String, attributes: Array<String>, values: Array<String>}) : SqlQueryPart
	{
		return { name: table.name, sql: table.attributes.join(' AND '), values: table.values };
	}
	
	private function createSqlJoin(tables : Array<{name: String, attributes: Array<String>, values: Array<String>}>) : SqlQueryPart
	{
		var values = new Array<String>();
		var joins = new Array<String>();
		
		for(i in 0 ... tables.length-1)
		{
			var sql = '';
			var table = tables[i];
			var joinTable = tables[i+1];
			
			// Create the join statement, with singularized foreign key.
			sql += 'INNER JOIN ' + table.name + ' ON (' + table.name + '.id = ' + joinTable.name + '.' + Inflection.singularize(table.name) + 'Id';
			
			if(table.attributes.length > 0)
			{
				sql += ' AND ' + table.attributes.join(' AND ');
				
				// Need to concatenate in reverse order here so they come in correct order in the sql query.
				values = table.values.concat(values);
			}
			
			sql += ")";
			
			// Need to shift them so they come in the correct order in the sql query.
			joins.unshift(sql);
		}
		
		return { name: '', sql: joins.join(' '), values: values };
	}
	
	private function contentType(outputFormat : RestApiFormat)
	{
		return supportedContentTypes.exists(outputFormat) ? supportedContentTypes.get(outputFormat) : supportedContentTypes.get(supportedOutputFormats[0]);
	}

}
