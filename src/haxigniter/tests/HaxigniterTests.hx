package haxigniter.tests;

import haxigniter.tests.unit.When_UnitTesting_With_TestCase;
import haxigniter.tests.unit.When_using_a_TypeFactory;
import haxigniter.tests.unit.When_using_Controllers;

import haxigniter.tests.unit.When_using_library_Url;
import haxigniter.tests.unit.When_using_library_Database;
import haxigniter.tests.unit.When_using_library_Input;
import haxigniter.tests.unit.When_using_library_Inflection;
import haxigniter.tests.unit.When_using_library_Server;

#if php
import php.Lib;
#elseif neko
import neko.Lib;
#end

/**
 * haXigniter framework tests.
 * Run by executing "tools/unittest.bat -all"
 */
class HaxigniterTests extends haxigniter.tests.TestRunner
{
	//new haxigniter.tests.HaxigniterTests().runAndDisplay();
	
	public function new()
	{
		super();

		this.add(new When_UnitTesting_With_TestCase());
		this.add(new When_using_a_TypeFactory());
		this.add(new When_using_Controllers());
		
		this.add(new When_using_library_Database());
		this.add(new When_using_library_Url());
		this.add(new When_using_library_Input());
		this.add(new When_using_library_Inflection());
		this.add(new When_using_library_Server());
	}
}
