module hunt.security.acl.permission.Item;

struct PermissionItem
{
    string key;
    string name;

	public this( string key , string name)
    {
        this.name = name;
        this.key = key;
    }
}
