module app.dao.user;
import app.entity.user;

import hunt.orm.entity;
import entity;

class UserDao
{
	static void registerUser()
	{
		EntityManager manager = entityManagerFactory.createEntityManager();
		scope(exit){manager.close();}
		User user = new User();
		user.name = "donglei";
		manager.save(user);
	}
}

