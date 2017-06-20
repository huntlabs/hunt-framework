module app.config;

import db;

__gshared Database ddo;
__gshared DatabaseConfig config;

static this()
{
	config = (new DatabaseConfig())
		.addDatabaseSource("mysql://dev:111111@10.1.11.31:3306/blog?charset=utf-8")
		.setMaxConnection(20)
		.setConnectionTimeout(5000);
	ddo = new Database(config);
}
