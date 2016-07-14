module hunt.application.model;

import entity;

DataBase getDB()
{
	if(_db is null)
	{
		import std.exception;
		_db = DataBase.create(_conStr);
		//enforce(_db, "the db  is Not support "~_conStr);
		_db.connect();
	}
	return _db;
}

auto getQuery(T)()
{
	return new Query!T(getDB());
}

void initDb(string str)
{
	_conStr = str;
	getDB();
}

private:
__gshared string _conStr;
DataBase _db;
