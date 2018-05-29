module hunt.security.acl.User;

import hunt.security.acl.Role;
import hunt.security.acl.permission.Permission;

class User
{
   
    
        int 		_id;
		string 		_name;
        Permission 	_permission;
        Role[] 		roles;
		__gshared User _default;

	this()
	{

	}

    public this(int id , string name)
    {
        this._id = id;
        this._permission = new Permission;
		this._name = name;	
	}

	static public User defaultUser(){
		if(_default is null)
			_default = new User(0 , "default");
		return _default;
	}


    public int id()
    {
        return this._id;
    }

	public string name()
	{
		return this._name;
	}

    public bool isGuest()
    {
        return this._id == 0;
    }

    public bool hasRole(int roleId)
    {
		foreach(r ; roles)
			if(r.id == roleId)
				return true;

        return false;
    }

    public bool can(string key)
    {
        return this._permission.hasPermission(key);
    }

    public User assignRole(Role role)
    {
        this.roles ~= role;

        this._permission.addPermissions(role.permission.permissions);
        
        return this;
    }
}
