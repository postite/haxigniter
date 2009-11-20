package haxigniter.server.libraries;

import Type;
import haxe.PosInfos;
import haxigniter.server.libraries.Debug;

#if php
import php.db.Connection;
import php.db.ResultSet;
import php.db.Mysql;
import haxigniter.server.db.Sqlite;
#elseif neko
import neko.db.Connection;
import neko.db.ResultSet;
import neko.db.Mysql;
import neko.db.Sqlite;
#end

enum DatabaseDriver
{
	mysql;
	sqlite;
}

class DatabaseException extends haxigniter.common.exceptions.Exception
{
	public var connection : DatabaseConnection;
	
	public function new(message : String, connection : DatabaseConnection, ?stack : haxe.PosInfos)
	{
		this.connection = connection;
		super(message, 0, stack);
	}
}

// TODO: Operators in where queries
// TODO: Unquoted fields in where/data queries
class DatabaseConnection
{	
	public var host : String;
	public var port : Int;
	public var user : String;
	public var pass : String;
	public var database : String;
	public var socket : String;
	public var driver : DatabaseDriver;
	
	public var debug : Debug;
	
	public var connection(getConnection, null) : Connection;
	private var myConnection : Connection;
	private function getConnection() : Connection
	{
		if(this.myConnection == null)
		{
			switch(this.driver)
			{
				case mysql:
					this.myConnection = Mysql.connect(this);
				case sqlite:
					this.myConnection = Sqlite.open(this.database);
			}
		}
		
		return this.myConnection;
	}
	
	public var traceQueries : DebugLevel;
	
	/**
	 * Set this value to change the string which is replaced by a parameter when executing a query.
	 * Default is '?'
	 */
	public var parameterString : String;
	
	/**
	 * Last executed query, useful when debugging.
	 */
	public var lastQuery(default, null) : String;

	private static var alphaRegexp : EReg = ~/^\w+$/;

	public function open() : Void
	{
		if(this.myConnection != null)
			throw new DatabaseException('Connection is already open.', this);
		
		getConnection();
	}
	
	public function close() : Void
	{
		if(this.myConnection != null)
		{
			this.myConnection.close();
			this.myConnection = null;
		}
	}
	
	///// Query methods /////////////////////////////////////////////
	
	public function query(query : String, ?params : Iterable<Dynamic>, ?pos : PosInfos) : ResultSet
	{
		if(params != null)
			query = this.queryParams(query, params);
		
		this.lastQuery = query;
		
		return this.request(query, pos);
	}

	public function queryRow(query : String, ?params : Iterable<Dynamic>, ?pos : PosInfos) : Dynamic
	{
		var result = this.query(query, params, pos);
		return result.hasNext() ? result.next() : null;
	}

	public function queryInt(query : String, ?params : Iterable<Dynamic>, ?pos : PosInfos) : Int
	{
		var result = this.query(query, params, pos);
		return result.hasNext() ? result.getIntResult(0) : null;
	}

	public function queryFloat(query : String, ?params : Iterable<Dynamic>, ?pos : PosInfos) : Float
	{
		var result = this.query(query, params, pos);
		return result.hasNext() ? result.getFloatResult(0) : null;
	}

	public function queryString(query : String, ?params : Iterable<Dynamic>, ?pos : PosInfos) : String
	{
		var result = this.query(query, params, pos);
		return result.hasNext() ? result.getResult(0) : null;
	}

	///// C(R)UD methods ////////////////////////////////////////////
	
	private function makeHash(data : Dynamic, ?pos : PosInfos) : Hash<Dynamic>
	{
		if(Std.is(data, Hash)) 
			return data;
		
		var output = new Hash<Dynamic>();
		for(field in Reflect.fields(data))
		{
			output.set(field, Reflect.field(data, field));
		}
		
		return output;
	}
	
	public function insert(table : String, data : Dynamic, ?replace = false, ?pos : PosInfos) : Int
	{
		this.testAlphaNumeric(table);

		var hash = makeHash(data);
		var keys = '';
		var values = '';
		
		for(key in hash.keys())
		{
			this.testAlphaNumeric(key);
			keys += ', ' + key;
			values += ', ' + this.connection.quote(Std.string(hash.get(key)));
		}
		
		var query = (replace ? 'REPLACE' : 'INSERT') + ' INTO ' + table + ' (' + keys.substr(2) + ') VALUES (' + values.substr(2) + ')';
		var result : ResultSet = this.request(query, pos);
		
		this.lastQuery = query;		
		return result.length;
	}

	public function replace(table : String, data : Dynamic) : Int
	{
		return this.insert(table, data, true);
	}
	
	public function update(table : String, data : Dynamic, ?where : Dynamic, ?limit : Int, ?pos : PosInfos) : Int
	{
		this.testAlphaNumeric(table);
		
		var hash = makeHash(data);
		var set = '';
		var whereStr = '';
		
		for(key in hash.keys())
		{
			this.testAlphaNumeric(key);
			set += ', ' + key + '=' + this.connection.quote(Std.string(hash.get(key)));
		}

		if(where != null)
		{
			var whereHash = makeHash(where);
			
			for(key in whereHash.keys())
			{
				this.testAlphaNumeric(key);
				whereStr += ' AND ' + key + '=' + this.connection.quote(Std.string(whereHash.get(key)));
			}
		}

		var query = 'UPDATE ' + table + ' SET ' + set.substr(2);
		
		if(where != null)
			query += ' WHERE ' + whereStr.substr(5);
		
		if(limit != null)
			query += ' LIMIT ' + limit;

		var result : ResultSet = this.request(query, pos);
		
		this.lastQuery = query;
		return result.length;
	}
	
	public function delete(table : String, ?where : Dynamic, ?limit : Int, ?pos : PosInfos) : Int
	{
		this.testAlphaNumeric(table);
		
		var whereStr = '';
		
		if(where != null)
		{
			var whereHash = makeHash(where);
			
			for(key in whereHash.keys())
			{
				this.testAlphaNumeric(key);
				whereStr += ' AND ' + key + '=' + this.connection.quote(Std.string(whereHash.get(key)));
			}
		}

		var query = 'DELETE FROM ' + table;
		
		if(where != null)
			query += ' WHERE ' + whereStr.substr(5);
		
		if(limit != null)
			query += ' LIMIT ' + limit;

		var result : ResultSet = this.request(query, pos);
		
		this.lastQuery = query;
		return result.length;
	}	

	///// Other /////////////////////////////////////////////////////
	
	public function lastInsertId() : Int
	{
		return this.connection.lastInsertId();
	}
	
	public inline function testAlphaNumeric(value : String) : Void
	{	
		if(value == null || !DatabaseConnection.alphaRegexp.match(value))
			throw new DatabaseException('Invalid parameter: ' + value, this);
	}

	/////////////////////////////////////////////////////////////////
	
	private function queryParams(query : String, params : Iterable<Dynamic>)
	{
		var parameter = this.parameterString == null ? '?' : this.parameterString;
		
		for(param in params)
		{
			var pos = query.indexOf(parameter);
			if(pos == -1)
				throw new DatabaseException('Not enough parameters in query.', this);
			
			if(param != null)
			{
				param = this.connection.quote(Std.string(param));
				
				/*
				// Slightly faster, but neko/php conflicts:
				param = switch(Type.typeof(param))
				{
					case ValueType.TInt: param;
					case ValueType.TFloat: param;
					case ValueType.TBool: Std.string(param);
					default: this.connection.quote(Std.string(param));
				}
				*/
			}
			else
				param = 'NULL';
			
			query = query.substr(0, pos) + param + query.substr(pos+1);
		}
		
		return query;
	}

	private function request(query : String, ?pos : PosInfos) : ResultSet
	{
		if(traceQueries != null && this.debug != null)
			debug.trace('[Executing SQL] ' + query, traceQueries, pos);

		try
		{
			return this.connection.request(query);
		}
		catch(e : Dynamic)
		{
			if(this.debug != null)
				debug.trace('[SQL Error]\n' + query, DebugLevel.error, pos);
			
			throw e;
		}
	}
}

/*
$db['local']['dbprefix'] = "";
$db['local']['pconnect'] = FALSE;
$db['local']['cache_on'] = FALSE;
$db['local']['cachedir'] = "";
$db['local']['char_set'] = "latin1";
$db['local']['dbcollat'] = "latin1_swedish_ci";	
*/
