module app.model.user;

import hunt.data.entity;

@Table("user")
class User
{
    @AutoIncrement
    @PrimaryKey 
    int id;

    @NotNull
    string name;
    float money;
    string email;
    bool status;
}
