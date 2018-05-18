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
 
module hunt.data.repository.CrudRepository;

import entity;
import entity.EntityManagerFactory;
import hunt;
public import entity.repository.Repository;

version(unittest)
{
	// __gshared  EntityManagerFactory g_entityManagerFactory = null;
	// static this()
	// {
	// 	if(g_entityManagerFactory is null)
	// 	{
	// 		DatabaseOption options = new DatabaseOption("mysql://root:@localhost:3306/hunt_test?charset=utf-8");
	// 		g_entityManagerFactory = Persistence.createEntityManagerFactory("default", options);
	// 	}
	// }

}


class CrudRepository(T, ID) : Repository!(T, ID)
{
    EntityManager createEntityManager()
    {
		// version(unittest)
		// {
		// 	return g_entityManagerFactory.createEntityManager();
		// }
		// else{
      	  return Application.getInstance().getEntityManagerFactory().createEntityManager();
		// }
	}

    public long count()
    {
        auto em = this.createEntityManager();
        CriteriaBuilder builder = em.getCriteriaBuilder();
        
        auto criteriaQuery = builder.createQuery!T;
        Root!T root = criteriaQuery.from();
        criteriaQuery.select(builder.count(root));
        
        Long result = cast(Long)(em.createQuery(criteriaQuery).getSingleResult());
		em.close();
        return result.longValue();
    }

    public void remove(T entity)
    {
        auto em = this.createEntityManager();
        em.remove!T(entity);
        em.close();
    }

    public void removeAll()
    {
        auto em = this.createEntityManager();

        foreach (entity; findAll())
        {
            em.remove!T(entity);
        }

        em.close();
    }
    
    public void removeAll(T[] entities)
    {
        auto em = this.createEntityManager();

        foreach (entity; entities)
        {
            em.remove!T(entity);
        }
        
        em.close();
    }

    public void removeById(ID id)
    {
        auto em = this.createEntityManager();
        em.remove!T(id);
        em.close();
    }
    
    public bool existsById(ID id)
    {
        T entity = this.findById(id);
        
        return (entity !is null);
    }



    public T[] findAll()
    {
        auto em = this.createEntityManager();
        CriteriaBuilder builder = em.getCriteriaBuilder();

        auto criteriaQuery = builder.createQuery!(T);

        Root!T root = criteriaQuery.from();
        TypedQuery!T typedQuery = em.createQuery(criteriaQuery.select(root));

        return typedQuery.getResultList();
    }

    public T[] findAllById(ID[] ids)
    {
        T[] entities;

        foreach (id; ids)
        {
            T entity = this.findById(id);
            if (entity !is null)
                entities ~= entity;
        }

        return entities;
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
        auto em = this.createEntityManager();
        
        if (em.find!T(entity) is null)
        {
            em.persist(entity);
        }
        else
        {
            em.merge!T(entity);
        }

        em.close();

        return entity;
    }

    public T[] saveAll(T[] entities)
    {
        T[] resultList;

        foreach (entity; entities)
        {
            resultList ~= this.save(entity);
        }

        return resultList;
    }
}




