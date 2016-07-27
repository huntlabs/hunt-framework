/*
 * Hunt - a framework for web and console application based on Collie using Dlang development
 *
 * Copyright (C) 2015-2016  Shanghai Putao Technology Co., Ltd 
 *
 * Developer: putao's Dlang team
 *
 * Licensed under the BSD License.
 *
 */
module hunt.http.session;

import hunt.http.sessionstorage;



/**
* Interface for the session.
*
* @author donglei xiaosan@outlook.com
*/
interface SessionInterface
{
    /**
	* Returns the session ID.
	*
	* @return string The session ID.
	*
	* @api
	*/
    public string getId();
    /**
	* Sets the session ID.
	*
	* @param string $id
	*
	* @api
	*/
    public void setId(string id);

    public void init();

    /// Gets a typed field from the session.
	string get(string key, lazy string def_value = string.init);
    ///Sets a typed field to the session.
    void set(string key, string value);
    ///Queries the session for the existence of a particular key.
    bool has(string key);

    bool del();

}

/**
* Represents a session.
*
* @author donglei xiaosan@outlook.com
*
*/
class Session : SessionInterface
{

    protected
    {
        SessionStorageInterface storge;
    }

    this(string sessionId,SessionStorageInterface storg = newStorage())
    {
        this(storg);
        setId(sessionId);
    }

    this(SessionStorageInterface storg = newStorage())
    {
		storge = storg;
    }

    /**
	* Returns the session ID.
	*
	* @return string The session ID.
	*
	* @api
	*/
    public string getId()
    {
        return this.storge.getId();
    }

    public void init()
    {
        this.storge.init();
    }

    public bool del()
    {
        return this.storge.del();
    }
    /**
	* Sets the session ID.
	*
	* @param string $id
	*
	* @api
	*/
    public void setId(string id)
    {
        this.storge.setId(id);
        version (USE_MemcacheSessionStorage)
        {
        }

		version(USE_FileSessionStorage)
        {
            if (this.storge.isExpired())
            {
                this.storge.setId(this.storge.generateSessionId());
            }
        }
    }

    /// Gets a typed field from the session.
    string get(string key, lazy string def_value = string.init)
    {
        string tmp = this.storge.get(key);
        if (tmp is string.init)
        {
            return def_value;
        }
		return tmp;
    }
    ///Sets a typed field to the session.
    void set(string key, string value)
    {
		import std.conv:to;
        this.storge.set(key, value);
    }
    ///Queries the session for the existence of a particular key.
    bool has(string key)
    {
        string value = this.storge.get(key);
        if (value == string.init)
            return false;
        return true;
    }

    @property SessionStorageInterface SessionStorage()
    {
        return storge;
    }
}

unittest
{
	//test no session id
	Session session = new Session();
	session.set("test", "testvalue");
	assert(session.get("test") == "testvalue");
	session.set("uid", 123455);
	assert(session.get!int("uid") == 123455);
	import std.experimental.logger;
	log("test no session id:", session.getId);
	
}


unittest
{
	Session session = new Session("123456");
	session.set("test", "testvalue");
	assert(session.get("test") == "testvalue");
	assert(session.getId() == "123456");
	import std.experimental.logger;
	log("test session with id:", session.getId());
}
