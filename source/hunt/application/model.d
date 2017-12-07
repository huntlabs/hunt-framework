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
public import hunt.application.config;

import std.string;

__gshared DatabaseConfig _dbconfig;
__gshared EntityManagerFactory _entityManagerFactory;
__gshared EntityManager _entityManager;

@property static  EntityManager entityManager()
{
    return _entityManager;
}

void registerEntity(T...)()
{
    assert(Config.app.database.url,"Please add database url first");
    _dbconfig = new DatabaseConfig(Config.app.database.url);
    _dbconfig.setMaximumConnection(Config.app.database.pool.maxConnection);
    _dbconfig.setMinimumConnection(Config.app.database.pool.minConnection);
    _dbconfig.setConnectionTimeout(Config.app.database.pool.timeout);
	assert(_dbconfig,"Please init db config first");
    _entityManagerFactory = Persistence.createEntityManagerFactory("hunt",_dbconfig);
	assert(_entityManagerFactory,"Please init entity manager factory first");
	_entityManager = _entityManagerFactory.createEntityManager!(T);
}
