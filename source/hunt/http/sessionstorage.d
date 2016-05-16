module hunt.http.sessionstorage;

/**
* StorageInterface.
* donglei xiaosan@outlook.com
*
* @api
*/
interface SessionStorageInterface
{
    public string getId();
    public void setId(string id);

    public void init();

    /**
	* Returns the session name.
	*
	* @return mixed The session name.
	*
	* @api
	*/
    public string getName();

    /**
	* Sets the session name.
	*
	* @param string $name
	*
	* @api
	*/
    public void setName(string name);
    ///Sets a typed field to the session.
    void set(string key, string value);
    string get(string key);

    ///session 是否过期
    bool isExpired();
    public bool del();
    ///生成sessionid
    string generateSessionId();

    @property string seesionPath();
}

import std.file;
import std.path;
import std.json;

///session 有效期
enum int SESSION_MAX_VAILD = 3600 * 12;

///文件存储
class FileSessionStorage : SessionStorageInterface
{

    private
    {
        string _session_Id;
        string _name;
        string _session_path;
    }

    public string getId()
    {
        if (_session_Id is null)
        {
            _session_Id = generateSessionId();
        }
        return this._session_Id;
    }

    public void init()
    {
        this.getId();
        this.set("__Init", "1");
    }

    public void setId(string id)
    {
        if (id !is null)
            _session_Id = id;
        this.set("__Init", "1");
    }

    public bool del()
    {
        try
        {
            import std.file;

            remove(seesionPath());
            _session_Id = null;
            return true;
        }
        catch (Exception ex)
        {
            import std.experimental.logger;

            log("remove session file error:", ex.msg);
        }
        return false;
    }

    /**
	* Returns the session name.
	*
	* @return mixed The session name.
	*
	* @api
	*/
    public string getName()
    {
        if (_name is null)
        {
            _name = "hunt_session";
        }
        return _name;
    }

    /**
	* Sets the session name.
	*
	* @param string $name
	*
	* @api
	*/
    public void setName(string name)
    {
        assert(name !is null);
        _name = name;
    }
    //生成sessionid
    public string generateSessionId()
    {
        import std.digest.sha;
        import std.format;
        import std.datetime;
        import std.random;
        import core.cpuid;
        import std.string;

        return toHexString(sha1Of(format("%s--%s--%s",
            Clock.currTime().toISOExtString, uniform(long.min, long.max), processor()))).toLower;
    }

    ///Sets a typed field to the session.
    void set(string key, string value)
    {
        //assert(_session_Id !is null);
        if (_session_Id is null)
        {
            _session_Id = generateSessionId();
        }
        if (!exists(seesionPath))
        {
            mkdirRecurse(dirName(seesionPath));
            import core.stdc.time;

            JSONValue json = [key : value];
            json["__time"] = time(null);
            write(seesionPath, json.toString());
        }
        else
        {
            string tmp = readText(seesionPath);
            JSONValue j = parseJSON(tmp);
            import core.stdc.time;

            j[key] = value;
            j["__time"] = time(null);
            write(seesionPath, j.toString());
        }
    }

    string get(string key)
    {
        //assert(_session_Id !is null);
        if (!exists(seesionPath))
        {
            return string.init;
        }
        else
        {
            string tmp = readText(seesionPath);
            JSONValue j = parseJSON(tmp);

            if ("__time" in j)
            {
                import core.stdc.time;

                time_t now = time(null);
                import std.conv : parse;

                if ((now - j["__time"].integer) > SESSION_MAX_VAILD)
                {
                    try
                    {
                        remove(seesionPath);
                        return string.init;
                    }
                    catch (Exception ex)
                    {

                    }
                }
            }
            else
            {
                return string.init;
            }

            if (key in j)
            {
                if (j[key].type() == JSON_TYPE.INTEGER)
                {
                    import std.conv;

                    return to!(string)(j[key].integer);
                }
                return j[key].str;
            }
            else
                return string.init;
        }
    }

    ///session 是否过期
    bool isExpired()
    {
        return string.init == get("__time");
    }

    @property string seesionPath()
    {
        if (_session_Id is null)
        {
            return string.init;
        }
        version (linux)
            return buildPath("/tmp/session/", _session_Id[0 .. 2], _session_Id[2 .. 4],
                _session_Id);
        else
            return buildPath("./storage/session/", _session_Id[0 .. 2],
                _session_Id[2 .. 4], _session_Id);
    }
}
