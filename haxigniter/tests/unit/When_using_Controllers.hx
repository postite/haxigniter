package haxigniter.tests.unit;

import haxe.rtti.Infos;
import haxigniter.common.exceptions.Exception;
import haxigniter.server.content.ContentHandler;
import Type;
import haxigniter.common.types.TypeFactory;
import haxigniter.common.unit.TestCase;

import haxigniter.server.content.ContentHandler;
import haxigniter.server.request.RequestHandler;

import haxigniter.server.Controller;
import haxigniter.server.request.RestHandler;
import haxigniter.server.request.BasicHandler;

import haxigniter.server.libraries.Request;

class TestContentHandler implements ContentHandler
{
	public function new() {}
	
	public function input(content : ContentData) : Dynamic
	{
		return StringTools.replace(content.data, 'a', '#');
	}
	
	public function output(content : Dynamic) : ContentData
	{
		var s = cast(content, String);
		
		return {
			mimeType: null,
			charSet: null,
			encoding : null,
			data : StringTools.replace(s, '1', '@####')
		}
	}
}


class Testrest implements Controller, implements Infos
{
	public function new()
	{
		requestHandler = new RestHandler(new MockConfig());
	}
	
	public var requestHandler(default, null) : RequestHandler;
	public var contentHandler(default, null) : ContentHandler;
	
	public function index() : String
	{
		return 'index';
	}
	
	public function make(arg1 : String, ?arg2 : Float) : String
	{
		return 'make ' + arg1 + (arg2 != null ? ' - ' + arg2 : '');
	}
	
	public function show(id : String, ?arg1 : String, ?arg2 : List<Int>) : String
	{
		return 'show ' + id + ' (' + arg1 + ') ' + arg2.join('=');
	}
	
	public function edit(id : Int, ?arg1 : Bool) : String
	{
		return 'edit ' + id + ' ' + arg1;
	}
	
	public function create(formData : Hash<String>) : String
	{
		return 'create ' + formData.get('id') + ' ' + formData.get('name');
	}
	
	public function update(id : Int, formData : Hash<String>) : String
	{
		return 'update ' + id + ' ' + formData.get('id') + ' ' + formData.get('name');
	}
	
	public function destroy(id : Int) : String
	{
		return 'destroy ' + id;
	}
}

class Teststandard implements Controller, implements Infos
{
	public function new()
	{
		requestHandler = new BasicHandler(new MockConfig());
	}
	
	public var requestHandler(default, null) : RequestHandler;
	public var contentHandler(default, null) : ContentHandler;
	
	public function index(?arg1 : Bool) : String
	{
		return 'index' + (arg1 ? ' ' + arg1 : '');
	}
	
	public function first(arg1 : String, ?arg2 : Float) : String
	{
		return 'first ' + arg1 + (arg2 != null ? ' - ' + arg2 : '');
	}
	
	public function second(arg2 : List<String>) : String
	{
		return 'second ' + arg2.join('/');
	}
}

///// Testing ///////////////////////////////////////////////////////

class When_using_Controllers extends haxigniter.common.unit.TestCase
{
	private var rest : Testrest;
	private var request : Request;
	
	public override function setup()
	{
		this.rest = new Testrest();
		this.request = new Request(new MockConfig());
	}
	
	public override function tearDown()
	{
	}
	
	public function test_Then_Rest_actions_should_work_according_to_reference()
	{
		var output : String;
		var data = new Hash<String>();

		// index()
		output = request.execute('testrest');
		this.assertEqual('index', output);

		// make()
		// Include in this test a prepending slash, which will be stripped.
		output = request.execute('/testrest/new/123');
		this.assertEqual('make 123', output);

		// Also test optional argument
		output = request.execute('testrest/new/123/12.45');
		this.assertEqual('make 123 - 12.45', output);
		
		// show()
		output = request.execute('testrest/123/useful/1-2-3');
		this.assertEqual('show 123 (useful) 1=2=3', output);

		// edit()
		output = request.execute('testrest/456/edit/true');
		this.assertPattern(~/^edit 456 (1|true)$/, output);

		// create()
		data.set('id', '123');
		data.set('name', 'Test');
		
		output = request.execute('testrest', 'POST', data);
		this.assertEqual('create 123 Test', output);

		// update()
		data.set('id', 'N/A');
		data.set('name', 'Test 2');

		output = request.execute('testrest/456', 'POST', data);
		this.assertEqual('update 456 N/A Test 2', output);

		// destroy()
		output = request.execute('testrest/789/delete', 'POST', data);
		this.assertEqual('destroy 789', output);
	}

	public function test_Then_standard_actions_should_work_according_to_reference()
	{
		var output : String;
		var data = new Hash<String>();

		// index()
		output = request.execute('teststandard', 'GET');
		this.assertEqual('index', output);

		output = request.execute('teststandard/index/true', 'POST');
		this.assertPattern(~/^index (1|true)$/, output);

		output = request.execute('teststandard/first/true/123.987', 'GET');
		this.assertEqual('first true - 123.987', output);

		output = request.execute('teststandard/second/what-a-nice-format', 'GET');
		this.assertEqual('second what/a/nice/format', output);
	}
}