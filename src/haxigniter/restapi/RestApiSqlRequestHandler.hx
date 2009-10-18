package haxigniter.restapi;

import haxigniter.libraries.Inflection;

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

typedef BaseSqlComponents = {
	var tables: Array<{name: String, attribs: Array<String>}>;
	var values: Array<String>;
	var joins: Array<String>;
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
		if(request.resources.length > 1)
			throw new RestApiException('Only one resource can be specified for create requests.', RestErrorType.invalidQuery);
		
		switch(request.resources[0])
		{
			case all(name):
				var data = requestData(request); 
				
				if(this.db.insert(name, data) == 0)
					throw new RestApiException('Create request failed - no insert was made.', RestErrorType.unknown);
			
			default:
				throw new RestApiException('Only "ALL" resources allowed for create requests.', RestErrorType.invalidQuery);
		}
		
		return RestApiResponse.success(this.db.lastInsertId());
	}

	public function handleUpdateRequest(request : RestApiRequest) : RestApiResponse
	{
		var sql = buildBaseSql(request);

		if(request.resources.length > 1)
			throw new RestApiException('Only one resource can be specified for update requests.', RestErrorType.invalidQuery);
		
		var data = requestData(request);
		
		var sql = buildBaseSql(request);
		var table : { name: String, attribs: Array<String>} = sql.tables[0];
		
		var query = 'UPDATE ' + table.name + ' SET ';
		var updateData = new Array<String>();
		
		for(key in data.keys())
		{
			updateData.push(key + '=?');			
			sql.values.push(data.get(key));
		}
		
		// Add the data keys to the query.
		query += updateData.join(', ');
		
		if(table.attribs.length > 0)
		{
			// Move the values for the WHERE to the end of the values array, because they are specified last.
			var temp = sql.values.splice(0, table.attribs.length);
			sql.values = sql.values.concat(temp);

			query += ' WHERE (' + table.attribs.join(') AND (') + ')';
		}
		
		var result = this.db.query(query, sql.values);
		
		return RestApiResponse.success(result.length);
	}

	public function handleDeleteRequest(request : RestApiRequest) : RestApiResponse
	{
		// TODO: Make mysql driver support multiple delete table requests.
		if(request.resources.length > 1)
			throw new RestApiException('Only one resource can be specified for delete requests.', RestErrorType.invalidQuery);

		var sql = buildBaseSql(request);
		var table : { name: String, attribs: Array<String>} = sql.tables[0];
		
		var query = 'DELETE FROM ' + table.name;
		
		if(table.attribs.length > 0)
			query += ' WHERE (' + table.attribs.join(') AND (') + ')';
		else if(sql.values.length > 0)
			throw new RestApiException('Unmatched sql attributes and values.', RestErrorType.unknown);

		var result = this.db.query(query, sql.values);
		
		return RestApiResponse.success(result.length);
	}

	public function handleReadRequest(request : RestApiRequest) : RestApiResponse
	{
		var sql = buildBaseSql(request);

		var from = '';
		var where = '';
		var limit = '';
		
		var table : { name: String, attribs: Array<String>} = sql.tables[0];
		from = 'FROM ' + table.name + ' ';
		
		if(table.attribs.length > 0)
		{
			where += ' WHERE (' + table.attribs.join(') AND (') + ')';
			
			// Move the values for the attributes to the end of the values array,
			// because they are specified last, in the FROM part.
			var temp = sql.values.splice(0, table.attribs.length);
			sql.values = sql.values.concat(temp);
		}

		// TODO: Enforce upper limit based on range pseudo-function.
		
		// TODO: Use SQL_CALC_FOUND_ROWS for the Mysql driver.
		var output = from + sql.joins.join(' ') + where;

		// Make the full query
		var results = db.query('SELECT ' + sql.tables[sql.tables.length-1].name + '.* ' + output + limit, sql.values);
		var response : RestDataCollection;
		
		// If no LIMIT or empty response, collection is easily created.
		if(results.length == 0)
			response = new RestDataCollection(0, 0, 0, Lambda.array(results.results()));
		else if(limit == '')
			response = new RestDataCollection(0, results.length - 1, results.length, Lambda.array(results.results()));
		else
		{
			var count = db.queryInt('SELECT COUNT(*) ' + output, sql.values);
			response = new RestDataCollection(0, results.length - 1, count, Lambda.array(results.results()));
		}
		
		/*
		haxigniter.Application.trace(tables);
		haxigniter.Application.trace(values);
		haxigniter.Application.trace(output);
		*/
		
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

	public function buildBaseSql(request : RestApiRequest) : BaseSqlComponents
	{
		// The query being built is a join of all resources.
		var tables = [];
		var values = [];
		var joins = [];
		
		for(resource in request.resources)
		{
			switch(resource)
			{
				case one(name, id):
					var newValue = { val: '' };
					tables.push({name: name, attribs: [attributeToSql(name + '.id', RestApiSelectorOperator.equals, Std.string(id), newValue)]});
					values.push(newValue.val);
				
				case all(name):
					tables.push({name: name, attribs: []});
				
				case view(name, viewName):
					throw new RestApiException('Views are not implemented.', RestErrorType.invalidQuery);
				
				case some(resourceName, query):
					var attributes = [];
					for(selector in query)
					{
						switch(selector)
						{
							case func(name, args):
								throw new RestApiException('Pseudo-functions are not implemented.', RestErrorType.invalidQuery);
							
							case attribute(name, operator, value):
								var newValue = { val: '' };
								attributes.push(attributeToSql(resourceName + '.' + name, operator, value, newValue));
								values.push(newValue.val);
						}
					}
					tables.push({name: resourceName, attribs: attributes});
			}
		}

		for(i in 1...tables.length)
		{
			var table = tables[i];
			var prevTable : { name: String, attribs: Array<String>} = tables[i-1];
			
			// Create the join statement, with singularized foreign key.
			var join = 'INNER JOIN ' + table.name + ' ON (' + table.name + '.' + Inflection.singularize(prevTable.name) + 'Id = ' + prevTable.name + '.id';
			
			if(table.attribs.length > 0)
				join += ' AND ' + table.attribs.join(' AND ');
			
			join += ')';
			
			joins.push(join);
		}

		return { tables: tables, values: values, joins: joins };
	}
	
	private function contentType(outputFormat : RestApiFormat)
	{
		return supportedContentTypes.exists(outputFormat) ? supportedContentTypes.get(outputFormat) : supportedContentTypes.get(supportedOutputFormats[0]);
	}

}
