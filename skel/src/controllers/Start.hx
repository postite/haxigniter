package controllers;

/**
 * The Start controller
 * Start is the default controller name, so if your application is in the root folder of the
 * web server, http://yourhostname/ will go here.
 * 
 * This controller is a RestController, which follows the RESTful approach used in Ruby on Rails.
 * A GET request like http://yourhostname/start/123 will map to the show() method.
 * 
 * Please look at haxigniter.server.request.RestHandler.hx for a full reference of the mappings.
 * 
 * Important: When creating your own controllers, they must be referenced in the 
 * file haxigniter/application/config/Controllers.hx, so the compiler is aware of them.
 * See that file for more information.
 * 
 */
class Start extends MyController, implements haxe.rtti.Infos
{
	public function new()
	{
		super();

		var url = new haxigniter.server.libraries.Url(this.config);
		
		// Some default view assignments for every page
		this.view.assign('application', 'haXigniter');
		this.view.assign('link', url.siteUrl());		
	}
	
	public function index()
	{
		// Displays 'start/index.mtt' (className/method, extension is from the ViewEngine.)
		this.view.displayDefault();
	}

	public function show(id : Int)
	{
		this.view.assign('id', id);
		this.view.display('start/index.mtt');
	}
	
	public function create(posted : Hash<String>)
	{
		// this.trace() gives a nicer trace output.
		this.trace(posted);
		this.view.display('start/index.mtt');
	}
}
