package haxigniter.tests.unit;

import haxigniter.libraries.Url;

/**
* This is fun, unit testing a unit test class.
*/
class When_using_library_Url extends haxigniter.tests.TestCase
{
	public function test_Then_linkUrl_should_consider_script_file()
	{
		var config = haxigniter.application.config.Config.instance();
		var old = config.indexPath;
		
		config.indexPath = '/';
		this.assertEqual('', Url.linkUrl());
		
		config.indexPath = '/index.php';
		this.assertEqual('', Url.linkUrl());

		config.indexPath = '/test/index.php';
		this.assertEqual('/test', Url.linkUrl());

		config.indexPath = '/test';
		this.assertEqual('/test', Url.linkUrl());

		config.indexPath = '/test/test2/index.php';
		this.assertEqual('/test/test2', Url.linkUrl());

		config.indexPath = '/test/test2/index.n';
		this.assertEqual('/test/test2', Url.linkUrl());

		config.indexPath = '/test/test2';
		this.assertEqual('/test/test2', Url.linkUrl());

		config.indexPath = old;
	}
}
