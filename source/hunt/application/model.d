/*
 * Hunt - a framework for web and console application based on Collie using Dlang development
 *
 * Copyright (C) 2015-2017  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.application.model;

version (WITH_ENTITY) :
public import entity;

import std.string;
import ddbc.all;

private __gshared static EntityMetaData _g_schema;
private __gshared string _g_driver;
private __gshared string _g_url;
private __gshared string[string] _g_params;
private __gshared int _g_maxPoolSize;
private __gshared int _g_timeToLive;
private __gshared int _g_waitTimeOut;
private __gshared string _g_tablePrefix;

void initDB(string driver,string url, string[string]params = null, int maxPoolSize = 2, int timeToLive = 600, int waitTimeOut = 30)
{
    _g_driver = driver;
    _g_url = url;
    _g_params = params;
    _g_maxPoolSize = maxPoolSize;
    _g_timeToLive = timeToLive;
    _g_waitTimeOut = waitTimeOut;
    if(params !is null && "prefix" in params)
    {
        _g_schema.tablePrefix = params["prefix"];
    }
}

final class HuntEntity
{
    static HuntEntity _entity;

    private EntityManagerFactory _entityManagerFactory;
    private Dialect _dialect;
    private DataSource _dataSource;
    private Driver _driver;

    static @property getInstance()
    {
        if(_entity is null)
        {
            _entity = new HuntEntity();
        }

        return _entity;
    }

    void initDB(string driver,string url, string[string]params = null, int maxPoolSize = 2, int timeToLive = 600, int waitTimeOut = 30)
    {
        import std.experimental.logger;
        driver = toLower(driver);

        if(driver == "mysql")
        {
            version(USE_MYSQL)
            {
                _dialect = new MySQLDialect();
                _driver = new MySQLDriver();
            }
        }
        else if(driver == "postgresql")
        {
            version(PGSQL)
            {
                _dialect = new PGSQLDialect();
                _driver = new PGSQLDriver();
            }
        }
        else if(driver == "")
        {
            version(USE_SQLITE)
            {
                _dialect = new SQLiteDialect();
                _driver = new SQLITEDriver();
            }
        }
        
	if(_dialect is null || _driver is null)
        {
            assert(false, "not support dialect " ~ driver);
        }

        _dataSource = new ConnectionPoolDataSourceImpl(_driver, url, params, maxPoolSize, timeToLive, waitTimeOut);
        _entityManagerFactory = new EntityManagerFactory(_g_schema, _dialect, _dataSource);
    }

    @property EntityManagerFactory entityManagerFactory()
    {
        if(_entityManagerFactory is null)
        {
            this.initDB(_g_driver,_g_url, _g_params, _g_maxPoolSize, _g_timeToLive, _g_waitTimeOut);
        }
        return _entityManagerFactory;
    }
}

@property static  EntityManagerFactory entityManagerFactory()
{
    return HuntEntity.getInstance.entityManagerFactory;
}

void registerEntity(T...)()
{
    _g_schema = new SchemaInfoImpl!(T);
}
