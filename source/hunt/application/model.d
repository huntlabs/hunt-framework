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
public import orm;

import std.string;

private __gshared static DatabaseConfig _dbconfig;
private __gshared static EntityManagerFactory _entityManagerFactory;
__gshared static EntityManager _entityManager;

void initDB(string url)
{
    _dbconfig = new DatabaseConfig(url);
    _entityManagerFactory = Persistence.createEntityManagerFactory("hunt",_dbconfig);
}

@property static  EntityManager entityManager()
{
    return _entityManager;
}

void registerEntity(T...)()
{
	_entityManager = _entityManagerFactory.createEntityManager!(T)();
}
