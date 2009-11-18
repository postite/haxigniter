package haxigniter.tests.unit;

import haxigniter.libraries.Url;

class When_using_library_Url extends haxigniter.tests.TestCase
{
	private var config : MockConfig;
	private var url : Url;
	
	public override function setup()
	{
		this.config = new MockConfig();
		this.url = new Url(this.config);
	}
	
	public override function tearDown()
	{
	}

	public function test_Then_linkUrl_should_strip_last_slash()
	{
		config.indexPath = '/';
		this.assertEqual('', url.linkUrl());
		
		config.indexPath = '/test/';
		this.assertEqual('/test', url.linkUrl());

		config.indexPath = '/test/test2/';
		this.assertEqual('/test/test2', url.linkUrl());
	}
}
