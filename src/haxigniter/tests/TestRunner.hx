package haxigniter.tests;

import haxigniter.libraries.Debug;
import haxigniter.tests.unit.When_UnitTesting_With_TestCase;
import haxigniter.tests.unit.When_using_a_TypeFactory;
import haxigniter.tests.unit.When_using_Controllers;

import haxigniter.tests.unit.When_using_library_Url;
import haxigniter.tests.unit.When_using_library_Database;
import haxigniter.tests.unit.When_using_library_Input;
import haxigniter.tests.unit.When_using_library_Inflection;

import haxigniter.tests.unit.When_using_RestApiParser;

#if php
import php.Lib;
#elseif neko
import neko.Lib;
#end

class TestRunner extends haxe.unit.TestRunner
{
	/**
	 * Override this class and add your own test classes.
	 */
	private function addTestClasses() {}
	
	private var output : String;

	public function new(runHaxigniterTests = true)
	{
		// Rebind the print method to capture output.
		var self = this;
		haxe.unit.TestRunner.print = function(v : Dynamic)
		{
			self.output += v;
		}

		super();

		if(runHaxigniterTests)
		{
			// haXigniter framework tests
			this.add(new When_UnitTesting_With_TestCase());
			this.add(new When_using_a_TypeFactory());
			this.add(new When_using_Controllers());
			
			this.add(new When_using_library_Database());
			this.add(new When_using_library_Url());
			this.add(new When_using_library_Input());
			this.add(new When_using_RestApiParser());

			this.add(new When_using_library_Inflection());			
		}
		
		this.addTestClasses();		
	}
	
	public function runTests() : String
	{
		this.output = '';
		this.run();

		return this.output;
	}

	public function runAndDisplay() : Void
	{
		var output : String = this.runTests();
		Lib.print('<pre style="border:1px dashed blue; padding:5px; background-color:#F2F0EE;">' + output + '</pre>');
	}
	
	public function runAndDisplayOnError() : Void
	{
		var output : String = this.runTests();
		var errorTest : EReg = ~/\b[1-9]\d* failed\b/;
		
		if(errorTest.match(output))
			Lib.print('<pre style="border:1px dashed red; padding:5px; background-color:#F2F0EE;">' + output + '</pre>');
	}
}
