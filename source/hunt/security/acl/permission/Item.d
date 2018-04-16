module hunt.security.acl.permission.Item;

struct PermissionItem
{
    string key;
    string name;

    public this(string name, string key)
    {
        this.name = name;
        this.key = key;
    }
}
