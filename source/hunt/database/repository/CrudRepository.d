/*
 * Entity - Entity is an object-relational mapping tool for the D programming language. Referring to the design idea of JPA.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs.cn
 *
 * Licensed under the Apache-2.0 License.
 *
 */
 
module hunt.database.repository.CrudRepository;

import entity;
import entity.EntityManagerFactory;
public import entity.repository.Repository;

abstract class CrudRepository(T, ID) : Repository!(T, ID)
{
    EntityManagerFactory createEntityManager()
    {
        return Application.getInstance().getEntityManagerFactory().createEntityManager();
    }

    public long count()
    {
        return 0;
    }

    public void remove()
    {
        auto em = this.createEntityManager();
        em.remove!T(id);
        em.close();
    }

    public void removeAll()
    {
    }
    
    public void removeAll(T[] entities)
    {
    }

    public void removeById(ID id)
    {
    }
    
    public bool existsById(ID id)
    {
    }

    public T[] findAll()
    {
        return [];
    }

    public T[] findAllById(ID[] ids)
    {
        return [];
    }

    public T findById(ID id)
    {
        auto em = this.createEntityManager();
        T result = em.find!T(id);
        em.close();

        return result;
    }

    public T save(T entity)
    {
        return null;
    }

    public T[] saveAll(T[] entities)
    {
        return [];
    }
}
