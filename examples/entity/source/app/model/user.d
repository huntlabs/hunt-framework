module app.model.user;

import hunt;

class User
{
	@AutoIncrement @PrimaryKey
    long id;
	
    string name;
}
