package haxigniter.tests.unit;

import Type;
import haxigniter.types.TypeFactory;
import haxigniter.tests.TestCase;

import haxigniter.controllers.Controller;

import haxigniter.libraries.Request;

class Testrest extends haxigniter.controllers.RestController
{
	public function new() {}
	
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

class Teststandard extends Controller
{
	public function new() {}
	
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

class Custom extends Controller
{
	public function new() {}
	
	public override function handleRequest(uriSegments : Array<String>, method : String, params : Hash<String>, rawQuery : String) : Dynamic
	{
		return 'I am custom: ' + method + ' ' + params.get('one') + params.get('two') + params.get('three');
	}
}

class When_using_Controllers extends haxigniter.tests.TestCase
{
	private var oldNs : String;
	private var rest : Testrest;
	
	public override function setup()
	{
		this.rest = new Testrest();
		
		this.oldNs = Request.defaultPackage;
		Request.defaultPackage = 'haxigniter.tests.unit';
	}
	
	public override function tearDown()
	{
		Request.defaultPackage = this.oldNs;
	}
	
	public function test_Then_Rest_actions_should_work_according_to_reference()
	{
		var output : String;
		var data = new Hash<String>();

		// index()
		output = Request.fromString('testrest', 'GET');
		this.assertEqual('index', output);

		// make()
		// Include in this test a prepending slash to test if it will be stripped.
		// Also test optional argument
		output = Request.fromString('/testrest/new/123', 'GET');
		this.assertEqual('make 123', output);

		output = Request.fromString('testrest/new/123/12.45', 'GET');
		this.assertEqual('make 123 - 12.45', output);
		
		// show()
		output = Request.fromString('testrest/123/useful/1-2-3', 'GET');
		this.assertEqual('show 123 (useful) 1=2=3', output);

		// edit()
		output = Request.fromString('testrest/456/edit/true', 'GET');
		this.assertPattern(~/^edit 456 (1|true)$/, output);

		// create()
		data.set('id', '123');
		data.set('name', 'Test');
		
		output = Request.fromString('testrest', 'POST', data);
		this.assertEqual('create 123 Test', output);

		// update()
		data.set('id', 'N/A');
		data.set('name', 'Test 2');

		output = Request.fromString('testrest/456', 'POST', data);
		this.assertEqual('update 456 N/A Test 2', output);

		// destroy()
		output = Request.fromString('testrest/789/delete', 'POST', data);
		this.assertEqual('destroy 789', output);
	}

	public function test_Then_standard_actions_should_work_according_to_reference()
	{
		var output : String;
		var data = new Hash<String>();

		// index()
		output = Request.fromString('teststandard', 'GET');
		this.assertEqual('index', output);

		output = Request.fromString('teststandard/index/true', 'POST');
		this.assertPattern(~/^index (1|true)$/, output);

		output = Request.fromString('teststandard/first/true/123.987', 'GET');
		this.assertEqual('first true - 123.987', output);

		output = Request.fromString('teststandard/second/what-a-nice-format', 'GET');
		this.assertEqual('second what/a/nice/format', output);
	}

	public function test_Then_custom_controller_will_handle_the_request_itself()
	{
		var output : String;
		var data = new Hash<String>();
		
		data.set('one', '1');
		data.set('two', '2');
		data.set('three', '3');
		
		// index()
		output = Request.fromString('custom', 'PUT', data);
		this.assertEqual('I am custom: PUT 123', output);
	}
}