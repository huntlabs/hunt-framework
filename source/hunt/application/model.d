module hunt.application.model;

import entity;

@property DataBase DB()
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

@property auto DBQuery(T)()
{
	return new Query!T(DB);
}

void initDb(string str)
{
	_conStr = str;
	DB();
}

private:
__gshared string _conStr;
DataBase _db;
