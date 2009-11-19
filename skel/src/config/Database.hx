package config; 
import haxigniter.libraries.Database;

/* =============================================================== */
/* ===== Database configuration file ============================= */
/* =============================================================== */

/*
|--------------------------------------------------------------------------
| Development (local) connection
|--------------------------------------------------------------------------
|
| These database settings will be used when Config.development is true.
| Set them as appropriate.
|
*/
class DevelopmentConnection extends DatabaseConnection
{
	public function new()
	{
		this.host = 'localhost';
		this.user = 'root';
		this.pass = '';
		this.database = '';
		this.driver = DatabaseDriver.mysql; // Can also be sqlite, then Database will be used as filename.
		this.debug = null; // Displays debug information on database/query errors if set.
		this.port = 3306;
		this.socket = null;
	}
}

/*
|--------------------------------------------------------------------------
| Online (live) connection
|--------------------------------------------------------------------------
|
| These database settings will be used when Config.development is false.
|
*/
class OnlineConnection extends DatabaseConnection
{
	public function new()
	{
		this.host = '';
		this.user = '';
		this.pass = '';
		this.database = '';
		this.driver = DatabaseDriver.mysql; // Can also be sqlite, then Database will be used as filename.
		this.debug = null; // Displays debug information on database/query errors if set.
		this.port = 3306;
		this.socket = null;
	}
}
