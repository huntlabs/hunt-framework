module hunt.orm.entity;
import entity;
import std.string;
import ddbc.all;

private __gshared static EntityMetaData _schema;

final class ORMEntity{
	__gshared static ORMEntity _orm;

	private EntityManagerFactory _entityManagerFactory;
	private Dialect _dialect;
	private DataSource _ds;
	private Driver _driver;

	static @property getInstance()
	{
		if(_orm is null)
			_orm = new ORMEntity();
		import std.stdio, core.thread;
		writeln("----", Thread.getThis.id, " orm " , _orm.toHash, " shame ", _schema.toHash);
		return _orm;
	}

	void initDB(string driver,string url, string[string]params = null, int maxPoolSize = 2, int timeToLive = 600, int waitTimeOut = 30){
		import std.experimental.logger;
		driver = toLower(driver);
		if(driver == "mysql")
		{
			_dialect = new MySQLDialect();
			_driver = new MySQLDriver();
		}
		else if(driver == "postgresql")
		{
			_dialect = new PGSQLDialect();
			_driver = new PGSQLDriver();
		}
		else if(driver == "")
		{
			_dialect = new SQLiteDialect();
			_driver = new SQLITEDriver();
		}
		else
		{
			assert(false, "not support dialect "~driver);
		}
		_ds = new ConnectionPoolDataSourceImpl(_driver, url, params, maxPoolSize, timeToLive, waitTimeOut);
		trace(_driver, url, params, maxPoolSize, timeToLive, waitTimeOut);
		_entityManagerFactory = new EntityManagerFactory(_schema, _dialect, _ds);
	}

	@property EntityManagerFactory entityManagerFactory(){
		assert(_entityManagerFactory !is null, " init db first");
		return _entityManagerFactory;
	}
}



@property __gshared static  EntityManagerFactory entityManagerFactory(){
	return ORMEntity.getInstance.entityManagerFactory;
}

void registerEntity(T...)()
{
	_schema = new SchemaInfoImpl!(T);
}