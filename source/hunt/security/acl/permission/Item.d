module hunt.security.acl.permission.Item;

struct PermissionItem
{
    private
    {
        string group;
        string key;
        string routes;
        string name;
        string discription;
    }

    public this(string name, string key, string discription)
    {
        this.name = name;
        this.key = key;
        this.discription = discription;
    }
}
