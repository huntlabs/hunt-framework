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
 
module hunt.data.repository.EntityRepository;

import hunt.data.repository.CrudRepository;
public import hunt.data.domain;
import entity;


class EntityRepository (T, ID) : CrudRepository!(T, ID)
{

	static string tableName()
	{
		return getUDAs!(getSymbolsByUDA!(T, Table)[0], Table)[0].name;
	}


	static string init_code()
	{
		return `		auto em = this.createEntityManager();
		CriteriaBuilder builder = em.getCriteriaBuilder();	
		auto criteriaQuery = builder.createQuery!T;
		Root!T root = criteriaQuery.from();`;
	}


	long count(Specification!T specification)
	{
		mixin(init_code);

		criteriaQuery.select(builder.count(root)).where(specification.toPredicate(
				root , criteriaQuery , builder));
		
		Long result = cast(Long)(em.createQuery(criteriaQuery).getSingleResult());
		em.close();
		return result.longValue();
	}

	T[] findAll(Sort sort)
	{
		mixin(init_code);

		//sort
		foreach(o ; sort.list)
			criteriaQuery.getSqlBuilder().orderBy(tableName ~ "." ~ o.getColumn() , o.getOrderType());

		//all
		criteriaQuery.select(root);

		TypedQuery!T typedQuery = em.createQuery(criteriaQuery);
		auto res = typedQuery.getResultList();
		em.close();
		return res;
	}


	T[] findAll(Specification!T specification)
	{
		mixin(init_code);

		//specification
		criteriaQuery.select(root).where(specification.toPredicate(
				root , criteriaQuery , builder));

		TypedQuery!T typedQuery = em.createQuery(criteriaQuery);
		auto res = typedQuery.getResultList();
		em.close();
		return res;
	}

	T[] findAll(Specification!T specification , Sort sort)
	{
		mixin(init_code);

		//sort
		foreach(o ; sort.list)
			criteriaQuery.getSqlBuilder().orderBy(tableName ~ "." ~ o.getColumn() , o.getOrderType());

		//specification
		criteriaQuery.select(root).where(specification.toPredicate(
				root , criteriaQuery , builder));

		TypedQuery!T typedQuery = em.createQuery(criteriaQuery);
		auto res = typedQuery.getResultList();
		em.close();
		return res;
	}


	Page!T findAll(Pageable pageable)
	{
		mixin(init_code);

		//sort
		foreach(o ; pageable.getSort.list)
			criteriaQuery.getSqlBuilder().orderBy(tableName ~ "." ~ o.getColumn() , o.getOrderType());

		//all
		criteriaQuery.select(root);

		//page
		TypedQuery!T typedQuery = em.createQuery(criteriaQuery).setFirstResult(pageable.getOffset())
				.setMaxResults(pageable.getPageSize());
		auto res = typedQuery.getResultList();
		auto page = new Page!T(res , pageable , super.count());
		em.close();
		return page;
	}

	Page!T findAll(Specification!T specification, Pageable pageable)
	{
		mixin(init_code);

		//sort
		foreach(o ; pageable.getSort.list)
			criteriaQuery.getSqlBuilder().orderBy(tableName ~"." ~ o.getColumn() , o.getOrderType());

		//specification
		criteriaQuery.select(root).where(specification.toPredicate(
				root , criteriaQuery , builder));
				
		//page
		TypedQuery!T typedQuery = em.createQuery(criteriaQuery).setFirstResult(pageable.getOffset())
			.setMaxResults(pageable.getPageSize());
		auto res = typedQuery.getResultList();
		auto page = new Page!T(res , pageable , count(specification));
		em.close();
		return page;
	}

}

/*
string orderByIDDesc(T)()
{
	string code = "criteriaQuery.orderBy(builder.desc(root."~ T.stringof ~"."~ getSymbolsByUDA!(T, PrimaryKey)[0].stringof ~"));";
	return code;
}*/


version(unittest)
{
	@Table("p_menu")
	class Menu : Entity
	{
		@PrimaryKey
		@AutoIncrement
		int 		ID;
		
		string 		name;
		int 		up_menu_id;
		string 		perident;
		int			index;
		string		icon;
		bool		status;
	}
}


unittest{

	void test_entity_repository()
	{
		import kiss.log;
		//data
		/*
	(1, 'User', 0, 'user.edit', 0, 'fe-box', 0),
	(2, 'Role', 0, 'role.edit', 0, 'fe-box', 0),
	(3, 'Module', 0, 'module.edit', 0, 'fe-box', 0),
	(4, 'Permission', 0, 'permission.edit', 0, 'fe-box', 0),
	(5, 'Menu', 0, 'menu.edit', 0, 'fe-box', 0),
	(6, 'Manage User', 1, 'user.edit', 0, '0', 0),
	(7, 'Add User', 1, 'user.add', 0, '0', 0),
	(8, 'Manage Role', 2, 'role.edit', 0, '0', 0),
	(9, 'Add Role', 2, 'role.add', 0, '0', 0),
	(10, 'Manage Module', 3, 'module.edit', 0, '0', 0),
	(11, 'Add Module', 3, 'module.add', 0, '0', 0),
	(12, 'Manage Permission', 4, 'permission.edit', 0, '0', 0),
	(13, 'Add Permission', 4, 'permission.add', 0, '0', 0),
	(14, 'Manage Menu', 5, 'menu.edit', 0, '0', 0),
	(15, 'Add Menu', 5, 'menu.add', 0, '0', 0);
		 */
		auto rep = new EntityRepository!(Menu , int)();
		
		//sort
		auto menus1 = rep.findAll(new Sort("ID" , OrderBy.DESC));
		assert(menus1.length == 15);
		assert(menus1[0].ID == 15 && menus1[$ - 1].ID == 1);
		
		//specification
		class MySpecification: Specification!Menu
		{
			Predicate toPredicate(Root!Menu root, CriteriaQuery!Menu criteriaQuery ,
				CriteriaBuilder criteriaBuilder)
			{
				Predicate _name = criteriaBuilder.gt(root.Menu.ID, 5);
				return criteriaBuilder.and(_name);
			}
		}
		auto menus2 = rep.findAll(new MySpecification());
		assert(menus2.length == 10);
		assert(menus2[0].ID == 6);
		
		//sort specification
		auto menus3 = rep.findAll(new MySpecification , new Sort("ID" ,OrderBy.DESC));
		assert(menus3[0].ID == 15 && menus3[$ - 1].ID == 6);

		//page
		auto pages1 = rep.findAll(new Pageable(0 , 10 , "ID" , OrderBy.DESC));
		assert(pages1.getTotalPages() == 2);
		assert(pages1.getContent.length == 10);
		assert(pages1.getContent[0].ID == 15 && pages1.getContent[$-1].ID == 6);
		assert(pages1.getTotalElements() == 15);

		//page specification
		auto pages2 = rep.findAll(new MySpecification , new Pageable(1 , 5 , "ID" , OrderBy.DESC));
		assert(pages2.getTotalPages() == 2);
		assert(pages2.getContent.length == 5);
		assert(pages2.getContent[0].ID == 10 && pages1.getContent[$-1].ID == 6);
		assert(pages2.getTotalElements() == 10);
	

	}


	// test_entity_repository();
}



