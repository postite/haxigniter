class RunUnitTests
{
    static function main()
    {
		neko.Lib.println('Running haXigniter tests...');
		neko.Lib.println(new haxigniter.tests.HaxigniterTests().runTests());

		//neko.Lib.println('Running application tests...');
		//neko.Lib.print(new haxigniter.application.tests.TestRunner().runTests());
    }
}