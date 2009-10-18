class UnitTest
{
    static function main()
    {
        var args = neko.Sys.args();
        
        if(args[0] == '-help' || args[0] == '--help')
        {
            neko.Lib.println('haXigniter unit tester');
            neko.Lib.println(' Usage : unittest [-all]');
            neko.Lib.println(' -all : Run the whole haXigniter test suite, not just application tests.');
        }
        else
        {
            if(args[0] == '-all')
            {
                neko.Lib.println('Running haXigniter tests...');
                neko.Lib.println(new haxigniter.tests.HaxigniterTests().runTests());
            }
            
            neko.Lib.println('Running application tests...');
            neko.Lib.print(new haxigniter.application.tests.TestRunner().runTests());
        }
    }
}