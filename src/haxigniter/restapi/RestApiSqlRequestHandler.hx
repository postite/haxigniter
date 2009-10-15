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
		if(request.type != RestApiRequestType.get)
			throw new RestApiException('Request type ' + request.type + ' is not implemented.', RestErrorType.invalidRequestType);
		else
			return handleGetRequest(request);
	}
	
	public function handleGetRequest(request : RestApiRequest) : RestApiResponse
	{
		// The query being built is a join of all resources.
		var tables = [];
		var values = [];
		
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

		var from = '';
		var where = '';
		var limit = '';
		
		var joins = [];

		var table : { name: String, attribs: Array<String>} = tables[0];
		from = 'FROM ' + table.name + ' ';
		
		if(table.attribs.length > 0)
		{
			where += ' WHERE (' + table.attribs.join(') AND (') + ')';
			
			// Move the values for the attributes to the end of the values array,
			// because they are specified last, in the FROM part.
			var temp = values.splice(0, table.attribs.length);
			values = values.concat(temp);
		}

		for(i in 1...tables.length)
		{
			table = tables[i];
			var prevTable : { name: String, attribs: Array<String>} = tables[i-1];
			
			// Create the join statement, with singularized foreign key.
			var join = 'INNER JOIN ' + table.name + ' ON (' + table.name + '.' + Inflection.singularize(prevTable.name) + 'Id = ' + prevTable.name + '.id';
			
			if(table.attribs.length > 0)
				join += ' AND ' + table.attribs.join(' AND ');
			
			join += ')';
			
			joins.push(join);
		}
		
		// TODO: Enforce upper limit based on range pseudo-function.
		
		// TODO: Use SQL_CALC_FOUND_ROWS for the Mysql driver.
		var output = from + joins.join(' ') + where;

		// Make the full query
		var results = db.query('SELECT ' + tables[tables.length-1].name + '.* ' + output + limit, values);
		var response : RestDataCollection;
		
		// If no LIMIT or empty response, collection is easily created.
		if(results.length == 0)
			response = new RestDataCollection(0, 0, 0, Lambda.array(results.results()));
		else if(limit == '')
			response = new RestDataCollection(0, results.length - 1, results.length, Lambda.array(results.results()));
		else
		{
			var count = db.queryInt('SELECT COUNT(*) ' + output, values);
			response = new RestDataCollection(0, results.length - 1, count, Lambda.array(results.results()));
		}
		
		/*
		haxigniter.Application.trace(tables);
		haxigniter.Application.trace(values);
		haxigniter.Application.trace(output);
		*/
		
		return haxigniter.restapi.RestApiResponse.successData(response);
	}
	
	public function attributeToSql(name : String, operator : RestApiSelectorOperator, value : String, newValue : {val : String})
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
	
	private function contentType(outputFormat : RestApiFormat)
	{
		return supportedContentTypes.exists(outputFormat) ? supportedContentTypes.get(outputFormat) : supportedContentTypes.get(supportedOutputFormats[0]);
	}

}
