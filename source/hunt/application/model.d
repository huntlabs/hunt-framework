module hunt.application.model;

import entity;

abstract class Model(T) if(is(T == class) || is(T == struct))
{
	alias MQuery = Query!T;
	alias Iterator = MQuery.Iterator;

	this()
	{}

	this (DataBase db)
	{
		_dbc = db;
	}

	final @property MQuery query()
	{
		if(_queryc is null)
			_queryc = new MQuery(database);
		return _queryc;
	}

	final @property DataBase database()
	{
		if(_dbc is null)
			_dbc = DB;
		return _dbc;
	}

	final Iterator Select(string table = "")()
	{
		return query.Select!(table)();
	}
	
	final Iterator Select(string sql)
	{
		return query.Select(sql);
	}
	
	final void Insert(string table = "")(ref T v)
	{
		query.Insert!(table)(v);
	}
	
	final void Update(string table = "")(ref T v)
	{
		query.Update!(table)(v);
	}
	
	final void Update(string table = "")(ref T v, string where)
	{
		query.Update!(table)(v,where);
	}
	
	final void Update(string table = "")(ref T v, WhereBuilder where)
	{
		query.Update!(table)(v,where);
	}
	
	final void Delete(string table = "")(ref T v)
	{
		query.Delete!(table)(v,where);
	}
	
	final void Delete(string table = "")(ref T v, string where)
	{
		query.Delete!(table)(v,where);
	}
	
	final void Delete(string table = "")(ref T v, WhereBuilder where)
	{
		query.Delete!(table)(v,where);
	}

private:
	DataBase _dbc;
	MQuery _queryc;
}

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
