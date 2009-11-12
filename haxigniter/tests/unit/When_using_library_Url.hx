package haxigniter.tests.unit;

import haxigniter.libraries.Url;

class When_using_library_Url extends haxigniter.tests.TestCase
{
	public function test_Then_linkUrl_should_strip_last_slash()
	{
		var config = haxigniter.application.config.Config.instance();
		var old = config.indexPath;
		
		config.indexPath = '/';
		this.assertEqual('', Url.linkUrl());
		
		config.indexPath = '/test/';
		this.assertEqual('/test', Url.linkUrl());

		config.indexPath = '/test/test2/';
		this.assertEqual('/test/test2', Url.linkUrl());

		config.indexPath = old;
	}
}
