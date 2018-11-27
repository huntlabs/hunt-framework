module hunt.framework.security.acl.Permission;

class Permission
{
    int    id;
    string key;
    string name;
    
    this()
    {

    }

    this(int id , string key , string name)
    {
        this.id = id;
        this.key = key;
        this.name = name;
    }
}
