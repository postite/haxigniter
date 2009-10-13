package haxigniter.restapi;

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

class RestApiSqlFactory implements RestApiRequestHandler
{
	public var supportedContentTypes(default, null) : Hash<String>;
	public var supportedOutputFormats(default, null) : Array<String>;
	
	private var db : DatabaseConnection;
	
	public function new(db : DatabaseConnection)
	{
		this.db = db;
		
		supportedContentTypes = new Hash<String>();
		supportedContentTypes.set('haxigniter', RestApiController.commonMimeTypes.haxigniter);
		
		supportedOutputFormats = ['haxigniter'];
	}

	///// RestApiRequestHandler implementation //////////////////////
	
	public function handleApiRequest(request : RestApiRequest) : RestApiResponse
	{
		if(request.type != RestRequestType.get)
			throw new RestApiException('Request type ' + request.type + ' is not implemented.', RestErrorType.invalidRequestType);
		
		haxigniter.Application.trace(request);
		
		// The query being built is a join of all resources.
		var tables = [];
		var values = [];
		
		for(selector in request.selectors)
		{
			switch(selector)
			{
				case all(name):
					tables.push({name: name, attribs: []});
				
				case view(name, viewName):
					throw new RestApiException('Views are not implemented.', RestErrorType.invalidQuery);
				
				case some(name, query):
					var attributes = [];
					for(resource in query)
					{
						switch(resource)
						{
							case func(name, args):
								throw new RestApiException('Pseudo-functions are not implemented.', RestErrorType.invalidQuery);
							
							case attribute(name, operator, value):
								var newValue = { val: '' };
								attributes.push(attributeToSql(name, operator, value, newValue));
								values.push(newValue.val);
						}
					}
					tables.push({name: name, attribs: attributes});
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
			var join = 'INNER JOIN ' + table.name + ' ON (' + table.name + '.' + prevTable.name + 'Id = ' + prevTable.name + '.id';
			
			if(table.attribs.length > 0)
				join += ' AND ' + table.attribs.join(' AND ');
			
			join += ')';
			
			joins.push(join);
		}
		
		//db.traceQueries = true;
		
		// TODO: Enforce upper limit based on range pseudo-function.
		
		// TODO: Use SQL_CALC_FOUND_ROWS for the Mysql driver.
		var output = from + joins.join(' ') + where;

		// Make the full query
		var results = db.query('SELECT ' + tables[tables.length-1].name + '.* ' + output + limit, values);
		var response : RestDataCollection;
		
		// If no LIMIT, collection is easily created.
		if(limit == '')
			response = new RestDataCollection(0, results.length - 1, results.length, Lambda.array(results.results()));
		else
		{
			var count = db.query('SELECT COUNT(*) ' + output, values);
			response = new RestDataCollection(0, results.length - 1, count.length, Lambda.array(results.results()));
		}
		
		/*
		haxigniter.Application.trace(tables);
		haxigniter.Application.trace(values);
		haxigniter.Application.trace(output);
		*/
		
		return haxigniter.restapi.RestApiResponse.successData(response);
	}
	
	public function attributeToSql(name : String, operator : RestResourceOperator, value : String, newValue : {val : String})
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
	
	public function outputApiResponse(request : RestApiResponse, outputFormat : String) : RestResponseOutput
	{
		return {
			contentType: supportedContentTypes.get(supportedOutputFormats[0]),
			charSet: null,
			output: haxe.Serializer.run(request)
		};
	}

	/////////////////////////////////////////////////////////////////
	
	private function contentType(outputFormat : String)
	{
		return supportedContentTypes.exists(outputFormat) ? supportedContentTypes.get(outputFormat) : supportedContentTypes.get(supportedOutputFormats[0]);
	}

}
