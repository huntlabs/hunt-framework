module hunt.framework.application.ConfigManager;

import hunt.framework.application.ApplicationConfig;
import hunt.framework.Init;

import std.exception;
import std.format;
import std.file;
import std.parallelism : totalCPUs;
import std.path;
import std.process;
import std.socket : Address, parseAddress;
import std.string;

// import hunt.cache.CacheOption;
// import hunt.http.MultipartOptions;
import hunt.logging.ConsoleLogger;
// import hunt.redis.RedisPoolConfig;
import hunt.util.Configuration;

/** 
 * 
 */
class ConfigManager {

    protected ConfigBuilder _defaultBuilder;
    // protected ConfigBuilder[string] _conf;

    protected string _basePath = DEFAULT_CONFIG_LACATION;
    protected string _fileName = DEFAULT_CONFIG_FILE;
    protected string _section = "";

    // private ApplicationConfig _appConfig;

    string configPath() {
        return this._basePath;
    }

    ConfigManager configPath(string path) {
        if (path.empty)
            return this;

        if (path[$ - 1] == '/')
            this._basePath = path;
        else
            this._basePath = path ~ "/";

        return this;
    }

    string configFile() {
        return _fileName;
    }

    ConfigManager configFile(string name) {
        _fileName = name;
        return this;
    }

    string configSection() {
        return _section;
    }

    void configSection(string name) {
        _section = name;
    }

    // ApplicationConfig config() {
    //     if (!_appConfig) {

    //         string huntEnv = environment.get("HUNT_ENV", "");
    //         if (huntEnv.empty) {
    //             huntEnv = environment.get(ENV_APP_ENV, "");
    //         }
            
    //         version(HUNT_DEBUG) tracef("%s=%s", ENV_APP_ENV, huntEnv);

    //         if(!huntEnv.empty) {
    //             _fileName = "application." ~ huntEnv ~ ".conf";
    //         }

    //         string configBase = environment.get(ENV_CONFIG_BASE_PATH, "");
    //         if(!configBase.empty) {
    //             _basePath = configBase;
    //         }

    //         load();
    //     }

    //     return _appConfig;
    // }

    // void httpBind(string host, ushort port) {
    //     _appConfig.http.address = host;
    //     _appConfig.http.port = port;
    // }

    T load(T)() if(is(T : ApplicationConfig)) {

        string huntEnv = environment.get("HUNT_ENV", "");
        if (huntEnv.empty) {
            huntEnv = environment.get(ENV_APP_ENV, "");
        }
        
        version(HUNT_DEBUG) tracef("%s=%s", ENV_APP_ENV, huntEnv);

        if(!huntEnv.empty) {
            _fileName = "application." ~ huntEnv ~ ".conf";
        }

        string configBase = environment.get(ENV_CONFIG_BASE_PATH, "");
        if(!configBase.empty) {
            _basePath = configBase;
        }  

        T _appConfig;
        string fullName = buildPath(APP_PATH, _basePath, _fileName);
        if (exists(fullName)) {
            infof("using the config file: %s", fullName);
            _defaultBuilder = new ConfigBuilder(fullName, _section);
            _appConfig = _defaultBuilder.build!(T)();
            // addConfig("hunt", _defaultBuilder);
        } else {
            warningf("The configure file does not exist: %s", fullName);
            _defaultBuilder = new ConfigBuilder();
            _appConfig = new T();
        }

        // update the config item with the environment variable if it exists
        string value = environment.get(ENV_APP_NAME, "");
        if(!value.empty) {
            _appConfig.application.name = value;
        }

        // value = environment.get(ENV_APP_VERSION, "");
        // if(!value.empty) {
        //     _appConfig.application.version = value;
        // }

        value = environment.get(ENV_APP_LANG, "");
        if(!value.empty) {
            _appConfig.application.defaultLanguage = value;
        }

        value = environment.get(ENV_APP_KEY, "");
        if(!value.empty) {
            _appConfig.application.secret = value;
        }

        return _appConfig;
    }

    // ConfigBuilder defaultBuilder() {
    //     return _defaultBuilder;
    // }

    // ConfigBuilder config(string key) {
    //     import std.format;

    //     ConfigBuilder v = null;
    //     v = _conf.get(key, null);

    //     enforce!ConfigNotFoundException(v, format(" %s is not created! ", key));

    //     return v;
    // }

    // void addConfig(string key, ConfigBuilder conf) {
    //     _conf[key] = conf;
    // }

    // auto opDispatch(string s)() {
    //     return config(s);
    // }

    this() {
        _basePath = DEFAULT_CONFIG_PATH;
        _fileName = DEFAULT_CONFIG_FILE;
    }

}
