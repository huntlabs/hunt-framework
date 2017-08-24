module app.model.user;

import hunt;

@Table("user")
class User
{
    @AutoIncrement @PrimaryKey 
    int id;

    @NotNull
    string name;
    float money;
    string email;
    bool status;
}
