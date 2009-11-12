package haxigniter.tests.unit;

import haxigniter.libraries.Server;

class When_using_library_Server extends haxigniter.tests.TestCase
{
	public function test_Then_basename_should_work_as_in_php()
	{
		var filename : String;
		
		filename = '/test/file.txt';
		this.assertEqual('file.txt', Server.basename(filename));

		filename = '/file2.txt';
		this.assertEqual('file2.txt', Server.basename(filename));

		filename = 'file2.txt';
		this.assertEqual('file2.txt', Server.basename(filename));

		filename = '/test/file.txt';
		this.assertEqual('file', Server.basename(filename, '.txt'));
		
		filename = 'file2.txt';
		this.assertEqual('file2', Server.basename(filename, '.txt'));
	}
}
