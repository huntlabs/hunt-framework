module app.model.user;

import hunt;

@Table("user")
class User
{
	@AutoIncrement @PrimaryKey
    long id;
	
    string name;
}

@Table("blog")
class Blog
{
	@AutoIncrement @PrimaryKey
    long id;
	
    string name;
}
