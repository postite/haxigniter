package tests;

class TestRunner extends haxigniter.common.unit.TestRunner
{
	/**
	 * Add test classes here. Then you can execute them with
	 * new tests.TestRunner().runAndDisplay() or runAndDisplayOnError()
	 */
	private override function addTestClasses()
	{
		this.add(new tests.unit.When_doing_math());
	}
	
	public function new() { super(); }
}
